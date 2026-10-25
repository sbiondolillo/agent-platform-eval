# Capture: spend-attribution probe, workstation bisect

Probe [spend-attribution](../../docs/plan.md). Taken 2026-10-25 from about 00:40 UTC. The purpose is to separate the exporter from the lab network. Every step ran from the operator's shell on the workstation. The shell held the same seven variables as the Cloud environment, plus `OTEL_EXPORTER_OTLP_HEADERS`. The service name was `agent-platform-eval-workstation`. The relay is [`otlp-relay.py`](otlp-relay.py). Its times are local, 20:41 EDT = 00:41 UTC.

## Step 1: direct export, debug log

```
claude -p 'Reply with one word: done.' --model claude-sonnet-5-5
```

With `OTEL_LOG_LEVEL=debug` set. The command printed `done` and no exporter line.

| Query | Result |
|---|---|
| `{__name__=~"claude_code.*", service_name="agent-platform-eval-workstation"}` | No data |

The exporter is silent on failure.

## Step 2: through the relay, default temporality

The relay listened on 127.0.0.1:4318, and the Claude Code endpoint was `http://127.0.0.1:4318`. Headless prompt, with `--allowedTools Bash`:

```
Run this Bash command and reply with its output: for i in 1 2 3; do date -u; sleep 8; done
```

Relay output:

```
20:41:51 /v1/logs application/x-protobuf 10031 B -> 204 b''
20:41:56 /v1/metrics application/x-protobuf 3348 B -> 400 b'\x08\x90\x03\x12\xfc\x01otlp parse error: invalid temporality and type combination for metric "claude_code.session.count"\ninvalid temporality and type combination for metric "claude_code.cost.usage"\ninvalid temporality and type combination for metric "claude_code.token.usage"'
20:42:14 /v1/logs application/x-protobuf 2842 B -> 204 b''
20:42:15 /v1/metrics application/x-protobuf 3344 B -> 400 b'\x08\x90\x03\x12\x80\x02otlp parse error: invalid temporality and type combination for metric "claude_code.cost.usage"\ninvalid temporality and type combination for metric "claude_code.token.usage"\ninvalid temporality and type combination for metric "claude_code.active_time.total"'
```

The gateway accepted the logs and refused every metrics batch with 400.

## Step 3: through the relay, cumulative temporality

The same run with `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=cumulative` added:

```
20:43:43 /v1/logs application/x-protobuf 10029 B -> 204 b''
20:43:48 /v1/metrics application/x-protobuf 3348 B -> 200 b''
20:43:58 /v1/metrics application/x-protobuf 3348 B -> 200 b''
20:44:06 /v1/logs application/x-protobuf 2842 B -> 204 b''
20:44:07 /v1/metrics application/x-protobuf 3847 B -> 200 b''
```

| Query | Result |
|---|---|
| `{__name__=~"claude_code.*", service_name="agent-platform-eval-workstation"}` | 7 series |

Among the series:

| Series | Value |
|---|---|
| `claude_code_cost_usage_USD_total` | 0.0062662 |
| `claude_code_session_count_total` | 1 |
| `claude_code_active_time_seconds_total` | 27.631 |
| `claude_code_token_usage_tokens_total` | one series per `type` |

## Earlier checks on the token

- An empty POST with the header returned 200. It did so with the value as pasted, and with `%20` decoded to a space.
- A hand-made JSON gauge, `probe_gauge`, posted with curl was ingested under job `probe-curl`. So the token can write metrics.

## Documentation

- The Claude Code monitoring docs do not mention temporality.
- The Grafana Cloud OpenTelemetry setup wizard does not mention temporality.
- The Grafana Cloud "Claude Code" integration page does (Connections > Add new connection > Claude Code). Its shell snippet sets `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=cumulative`.

## Reading

Claude Code exports delta counters by default, and the Grafana gateway refuses them. With cumulative temporality the same variables land in the stack. The variables, the token and the stack are sound. Without a relay, a refused export leaves no trace on the sending side.
