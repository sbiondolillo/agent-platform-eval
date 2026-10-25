# Capture: spend-attribution probe, platform arm

Probe [spend-attribution](../../docs/plan.md). Taken 2026-10-25 from 00:30 UTC. Five factory runs of issue #2 on throwaway branches, with the telemetry export pointed at the same Grafana Cloud stack as the Cloud arm.

## The factory change

DSF v1.2.1 passes the agent container only `HOME`, `ANTHROPIC_API_KEY` and `ANTHROPIC_BASE_URL` (`src/Core/Sandbox.cs`). The `--pass-env` names go to the integration tests only.

Throwaway branch `probe/spend-attribution` on sbiondolillo/dotnet-software-factory, from v1.2.1:

| Commit | Change |
|---|---|
| e222ee2 | Eight telemetry names as `--env NAME`, passed when the host sets a value |
| 9fe936f | The temporality name |
| 40daf71 | `NO_PROXY` and `no_proxy`. An explicit `--env` wins over the Docker client's proxies block |

The unit suite passed 1425 tests on each commit.

## The sample repo change

Throwaway branch `probe/spend-attribution` on sbiondolillo/platform-eval-sample:

| Commit | Change |
|---|---|
| 0d47127 | The seven variables in the "Run the factory" step env, plus `OTEL_EXPORTER_OTLP_HEADERS` from a repository secret. Service name `agent-platform-eval-platform`. Factory ref default `probe/spend-attribution` |
| 8a2524d | Temporality |
| bcbcff0 | Endpoint `http://172.17.0.1:4318` for the relay, and `NO_PROXY` with 172.17.0.1 |
| 375a1e2 | GitHub env keys are case-insensitive, so the script exports `no_proxy` |
| 5fbc6fa | Endpoint back to the gateway |

## The egress change

A Squid allowlist line for `otlp-gateway-prod-us-east-2.grafana.net` under sandbox01, homelab-ansible commit 1ea1431. Applied to egress-01 with `changed=2`. The container reaches the proxy through `HTTPS_PROXY`, which the runner user's Docker client config injects.

## The five runs

Every dispatch was `gh workflow run factory.yml --ref probe/spend-attribution -f issue=2 -f ref=probe/spend-attribution`. All five ended in success, and each opened a throwaway PR.

| Run | Start | Route | Phases (turns, cost, s) | PR | Grafana |
|---|---|---|---|---|---|
| 40146937983 | 00:30:11 | direct, delta | plan 7 $0.0772433 17 s; build 4 $0.0699441 58 s; review 4 $0.040588 21 s | 10 | no data |
| 40148180618 | 00:49:16 | direct, cumulative | plan 8 $0.0830591 20 s; build 5 $0.0752454 69 s; review 4 $0.0464666 22 s | 11 | no data |
| 40148902323 | 01:00:22 | relay adds the header | plan 7 $0.0856194 22 s; build 5 $0.073822 74 s; review 4 $0.0445089 24 s | 12 | 16 series, 3 sessions |
| 40149311145 | 01:06:20 | relay passes the container's header through | plan 6 $0.0414619 14 s; build 4 $0.0511095 55 s; review 4 $0.0422551 19 s; build 6 $0.0412766 17 s; review 4 $0.0425809 22 s | 13 | 401 at the relay |
| 40149458043 | 01:08:33, ran from 01:10:45 after the runner freed | direct, cumulative, secret re-set | plan 7 $0.0379027 20 s; build 11 $0.0799911 81 s; review 4 $0.0455749 25 s | 14 | 3 new sessions |

The Actions log prints the variable names and values, with the header masked as `***`. It shows no exporter line in any run. A refused export is invisible from the sending side.

## Squid log, run 1

On egress-01, during run 1: 17 CONNECT lines to `otlp-gateway-prod-us-east-2.grafana.net:443`, all `TCP_TUNNEL/200`, from 10.25.0.10. They run from 00:30:45 to 00:32:32, every 5 to 10 s. Other hosts in the window: api.anthropic.com, api.nuget.org and github.com. The tunnel log shows the connection, not the response inside it.

## Relay on sandbox-01

The relay [`otlp-relay.py`](otlp-relay.py) ran as `/home/sam/otlp-relay.py` in the operator's SSH shell. It bound 0.0.0.0:4318, with `https_proxy=http://10.26.0.10:3128`.

### Run 3, the relay adds the header from the shell

```
172.17.0.2 01:00:52 /v1/logs application/x-protobuf 10100 B -> 204 b''
172.17.0.2 01:00:57 /v1/metrics application/x-protobuf 2081 B -> 200 b''
172.17.0.2 01:00:57 /v1/logs application/x-protobuf 884 B -> 204 b''
172.17.0.2 01:01:07 /v1/metrics application/x-protobuf 3234 B -> 200 b''
172.17.0.2 01:01:07 /v1/logs application/x-protobuf 3274 B -> 204 b''
172.17.0.2 01:01:08 /v1/metrics application/x-protobuf 3522 B -> 200 b''
172.17.0.2 01:01:14 /v1/logs application/x-protobuf 5010 B -> 204 b''
172.17.0.2 01:01:19 /v1/metrics application/x-protobuf 2081 B -> 200 b''
172.17.0.2 01:01:25 /v1/logs application/x-protobuf 1474 B -> 204 b''
172.17.0.2 01:01:29 /v1/metrics application/x-protobuf 2081 B -> 200 b''
```

### Run 4, `PROBE_PASSTHROUGH=1`

The relay forwards the container's own Authorization header and prints its presence only.

```
172.17.0.2 01:06:46 /v1/logs application/x-protobuf 8295 B -> 401 b'{"status":"error","error":"authentication error: no credentials provided"}' auth=absent
172.17.0.2 01:06:51 /v1/metrics application/x-protobuf 3234 B -> 401 b'{"status":"error","error":"authentication error: no credentials provided"}' auth=absent
(five more lines, all 401 auth=absent, to 01:07:05)
```

The container sent no Authorization header. The repository secret's first value did not parse as a header pair. It was set before the note that the value must start with `Authorization=Basic`. The operator re-set the secret with the full pair. The workflow went back to the gateway endpoint, and run 5 landed through Squid.

## Grafana

Query: `sum by (session_id) (claude_code_cost_usage_USD_total{service_name="agent-platform-eval-platform"})`. Final values, against the cost in the factory's own log:

| Run | Phase | session_id | Log | Metric |
|---|---|---|---|---|
| 3 | plan | 1a9c399a-d601-49eb-8438-abc4ea34c12d | 0.0856194 | 0.0856 |
| 3 | build | a8446dc5-5272-4190-a7bc-29e5dc1a9351 | 0.073822 | 0.0738 |
| 3 | review | 20c0dd34-c989-4625-99f4-d28086743565 | 0.0445089 | 0.0445 |
| 5 | plan | c3067912-fbeb-4ff5-bb66-1a324eed3268 | 0.0379027 | 0.0116 |
| 5 | build | 32dd0104-df87-442d-8722-8f4b199fbdc7 | 0.0799911 | 0.0719 |
| 5 | review | 26a30f9c-1be4-4e5e-8c39-53ee9c6801aa | 0.0455749 | 0.0387 |

The metric is a floor. The headless process exits without a final flush. A phase loses up to one 10 s export interval plus its last turn. Run 3 matched by timing.

The Loki data source `grafanacloud-ambercroissant1151-logs` holds one event per API request. Query: `{service_name="agent-platform-eval-platform"}`. Each event has scope `com.anthropic.claude_code.events` and `event_name` `api_request`. Its fields:

- `session_id`, `model`, `prompt_id`, `user_id`
- `input_tokens`, `output_tokens` and the cache tokens
- `cost_usd`, `cost_usd_micros`, `duration_ms`, `ttft_ms`
- `terminal_type` `non-interactive`, `query_source` `sdk`, `service_version` 2.1.310

The sum of `cost_usd` over a session's events is the exact figure. This is the per-call record keyed by session that the gateway ledger lacks (its `run_id` column is empty).

## The gateway ledger

The gateway ledger on llm-01 already attributes spend per call. The cloud-logging probe read it for the platform delivery of issue #2 on 2026-10-24. Its 26 calls and the sum of $0.5289, every row `success`, are in [`../cloud-logging/capture-platform.md`](../cloud-logging/capture-platform.md). The ledger keys each row by the gateway consumer and the model. It has no parent, agent or `run_id` column, so one factory job is read by its time window and consumer, not by a session id ([`../run-history/capture-platform.md`](../run-history/capture-platform.md)).
