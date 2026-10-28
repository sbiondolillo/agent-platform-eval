# Capture: spend-attribution probe, Cloud sessions

Probe [spend-attribution](../../docs/plan.md). Four sessions on sbiondolillo/platform-eval-sample, model Sonnet 5.5 in the picker, environment agent-platform-eval. Taken 2026-10-25 from 00:09 UTC. Prompts: [`prompt.md`](prompt.md). The environment held the seven OTEL variables from the plan and a network secret for host otlp-gateway-prod-us-east-2.grafana.net (header Authorization, prefix Basic). The replies are pasted unedited.

## Session 1, "Spend attribution probe"

## 1. `env | grep -i -E 'otel|telemetry' | cut -d= -f1 | sort`
```
CLAUDE_CODE_ENABLE_TELEMETRY
SBX_TELEMETRY_SOCKET
```

## 2. `basename -s .jsonl "$(ls -t /root/.claude/projects/*/*.jsonl | head -1)"`
```
76dec028-2d6c-571f-94ba-94a735e27096
```

## 3. `curl -sS -m 20 -o /dev/null -w 'otlp metrics endpoint: %{http_code}\n' -X POST ... /otlp/v1/metrics`
```
otlp metrics endpoint: 200
```

## 4. `for i in 1 2 3; do date -u; sleep 12; done`
```
Sun Oct 25 00:09:05 UTC 2026
Sun Oct 25 00:09:17 UTC 2026
Sun Oct 25 00:09:29 UTC 2026
```

## 5. `basename -s .jsonl "$(ls -t /root/.claude/projects/*/*.jsonl | head -1)"`
```
76dec028-2d6c-571f-94ba-94a735e27096
```

All five commands ran, and I made no edits, commits, pushes or branches.

## Grafana Explore, stack ambercroissant1151

Data source `grafanacloud-ambercroissant1151-prom`, range Last 1 hour, run about 00:15 UTC, after three export intervals:

| Query | Result |
|---|---|
| `{__name__=~"claude_code.*", session_id="76dec028-2d6c-571f-94ba-94a735e27096"}` | No data |
| `{__name__=~"claude_code.*"}` | No data |

The empty POST in command 3 returned 200, so the proxy attached the Basic auth header and the gateway accepted the request. The gateway received no metric from the session.

## Session 2, "Spend attribution probe 2"

Before this session the operator added `PROBE_MARKER=present` and `OTEL_PROBE_MARKER=present` to the environment, nine variables in all.

## 1. `env | grep -i -E 'otel|telemetry|probe' | cut -d= -f1 | sort`
```
CLAUDE_CODE_ENABLE_TELEMETRY
PROBE_MARKER
SBX_TELEMETRY_SOCKET
```

## 2. `cat /proc/1/environ | tr '\0' '\n' | grep -i -E 'otel|telemetry|probe' | cut -d= -f1 | sort`
```
cat: /proc/1/environ: Permission denied
```

## 3. `p=$(pgrep -f 'claude' | head -1); echo "pid $p"; cat /proc/$p/environ | tr '\0' '\n' | grep -i -E 'otel|telemetry|probe' | cut -d= -f1 | sort`
```
pid 88
SBX_TELEMETRY_SOCKET
```

## 4. `basename -s .jsonl "$(ls -t /root/.claude/projects/*/*.jsonl | head -1)"`
```
64994760-5021-5f0c-a4f3-2c46a5c4931e
```

All four commands ran as written, with no edits, commits, pushes or branches.

## Session 3, "Spend attribution probe 3"

Before this session the operator read the docs ([`finding.md`](finding.md) cites them) and added `OTEL_EXPORTER_OTLP_HEADERS` to the environment with the value the Grafana wizard generated, ten variables in all. Taken 2026-10-25 from 00:20 UTC.

### Message 1

## 1. `echo "remote session id: ${CLAUDE_CODE_REMOTE_SESSION_ID:-unset}"`
```
remote session id: cse_01D7vsPZA8YLqpouY5irixVd
```

## 2. `basename -s .jsonl "$(ls -t /root/.claude/projects/*/*.jsonl | head -1)"`
```
cafe17ea-1ba7-5643-ab84-5e72d0c4c35c
```

## 3. `for i in 1 2 3 4; do date -u; sleep 12; done`
```
Sun Oct 25 00:20:36 UTC 2026
Sun Oct 25 00:20:48 UTC 2026
Sun Oct 25 00:21:00 UTC 2026
Sun Oct 25 00:21:12 UTC 2026
```

## 4. `echo "remote session id: ${CLAUDE_CODE_REMOTE_SESSION_ID:-unset}"`
```
remote session id: cse_01D7vsPZA8YLqpouY5irixVd
```

All four commands ran as written, and the remote session id was the same in commands 1 and 4.

### Grafana Explore, after four export intervals

| Query | Result |
|---|---|
| `{__name__=~"claude_code.*", ccr_session_id="cse_01D7vsPZA8YLqpouY5irixVd"}` | No data |
| `{__name__=~"claude_code.*"}` | No data |

### Message 2

## 1. `ps -eo pid,ppid,comm --no-headers | head -30`
The first thirty rows were `process_api` as pid 1 and kernel threads. The user processes sit above pid 85 and the scan in command 2 covers them.

## 2. telemetry env scan
The loop printed `Permission denied` for pid 1 and `No such process` for every kernel thread, then:
```
pid 772 bash: 1 telemetry names
/bin/bash: line 1: /proc/773/environ: No such file or directory
scan done
```
Every other user process had a readable environment with zero telemetry names. Pid 772 is the scan's own shell, the Bash tool, which holds `CLAUDE_CODE_ENABLE_TELEMETRY`.

## 3. direct POST (no proxy)
```
curl: (6) Could not resolve host: otlp-gateway-prod-us-east-2.grafana.net
direct: 000
exit=6
```

## 4. POST via proxy
```
via proxy: 200
exit=0
```

Only a bash process (pid 772, likely the scan's own shell) showed a telemetry-named variable, the direct POST failed DNS resolution, and the proxied POST returned 200.

## Session 4, "Spend attribution probe 4"

Before this session the workstation bisect in [`capture-workstation.md`](capture-workstation.md) found that the gateway refuses delta counters. The operator added `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=cumulative` to the environment, eleven variables in all. Taken 2026-10-25 at 00:46 UTC.

## 1. `echo "remote session id: ${CLAUDE_CODE_REMOTE_SESSION_ID:-unset}"`
```
remote session id: cse_0175hRnZVhdzYK2JGHcGc1ob
```

## 2. `for i in 1 2 3 4; do date -u; sleep 12; done`
```
Sun Oct 25 00:46:19 UTC 2026
Sun Oct 25 00:46:31 UTC 2026
Sun Oct 25 00:46:43 UTC 2026
Sun Oct 25 00:46:55 UTC 2026
```

## 3. `echo "remote session id: ${CLAUDE_CODE_REMOTE_SESSION_ID:-unset}"`
```
remote session id: cse_0175hRnZVhdzYK2JGHcGc1ob
```

The session id was the same before and after the 48-second loop.

### Grafana Explore

Range Last 15 minutes:

| Query | Result |
|---|---|
| `{__name__=~"claude_code.*", ccr_session_id="cse_0175hRnZVhdzYK2JGHcGc1ob"}` | No data |

The same variables exported from the workstation produced series in this stack ([`capture-workstation.md`](capture-workstation.md)). So the variables and the stack are sound, and the Cloud result stands.

## Session 5, "Spend attribution probe 5", 2026-10-28

The teardown of 2026-10-25 had removed every variable and the network secret. Before this session the operator added `otlp-gateway-prod-us-east-2.grafana.net` to the environment's Allowed domains, and restored nine variables: the seven from the plan, `OTEL_EXPORTER_OTLP_HEADERS` and cumulative temporality. Service name `agent-platform-eval-cloud`. No network secret. Taken 2026-10-28 at 01:18 UTC. Prompt: [`prompt.md`](prompt.md).

## 1. `echo "remote session id: ${CLAUDE_CODE_REMOTE_SESSION_ID:-unset}"`
```
remote session id: cse_01VD1PnVJDYJwdg65troLXCf
```

## 2. empty POST, no auth header, via the session's network
```
otlp metrics endpoint, no auth: 401
exit=0
```

## 3. `for i in 1 2 3 4 5; do date -u; sleep 12; done`
```
Wed Oct 28 01:18:45 UTC 2026
Wed Oct 28 01:18:57 UTC 2026
Wed Oct 28 01:19:09 UTC 2026
Wed Oct 28 01:19:21 UTC 2026
Wed Oct 28 01:19:33 UTC 2026
```

## 4. `echo "remote session id: ${CLAUDE_CODE_REMOTE_SESSION_ID:-unset}"`
```
remote session id: cse_01VD1PnVJDYJwdg65troLXCf
```

All four commands ran in separate Bash calls, and I made no edits, commits, pushes or branches.

### Grafana Explore, about 01:20 UTC

Range Last 1 hour:

| Query | Result |
|---|---|
| `{__name__=~"claude_code.*", ccr_session_id="cse_01VD1PnVJDYJwdg65troLXCf"}` | 12 series |

Every series carries `ccr_session_id="cse_01VD1PnVJDYJwdg65troLXCf"`, `job="agent-platform-eval-cloud"`, `service_name="agent-platform-eval-cloud"` and `organization_id`. Among them:

| Series | Value |
|---|---|
| `claude_code_cost_usage_USD_total{query_source="main", model="claude-sonnet-5-5"}` | 0.11928 |
| `claude_code_cost_usage_USD_total{query_source="auxiliary", model="claude-sonnet-5-5"}` | 0.0096523 |
| `claude_code_active_time_seconds_total{type="cli"}` | 76.467 |
| `claude_code_session_count_total{start_type="resume"}` | 1 |
| `claude_code_token_usage_tokens_total` | one series per `type` |

The `session_id` label on the cost series is `cc671e66-dffd-5637-9183-29b225cdb9bd`, and on the session count series `1b1a4017-15dd-4f15-8523-9e372897c171`. The `ccr_session_id` label is the same on both, which is why the docs say to group on it.

## Reading

Sessions 1 to 4 exported nothing. Session 5 exported everything, keyed by `ccr_session_id`. One change separates them: the collector host on the environment's Allowed domains. The variables of session 5 are the variables of session 4.

The cloud-environments doc states the rule. A network secret opens its host to the session, "except the hosts that never get the secret", and Claude Code's own telemetry export is on that list. The export goes through the session's network allowlist, which never held the Grafana host before session 5. The proxy refused it, and the exporter is silent on a refusal.

The `curl` checks of sessions 1 and 3 measured the wrong client. A Bash command is a request Claude runs, so the network secret's host exception applied to it, and the proxy answered 200. The exporter never had that path.

The earlier reading, that the Claude Code process never received the variables, rested on `/proc/<pid>/environ`. That file is the exec-time snapshot. The harness delivers the environment's values after launch, into `process.env`, which `/proc` never shows. The Bash child of session 2 held `CLAUDE_CODE_ENABLE_TELEMETRY` while its parent's `/proc` environment did not, which fits that. So the variables did reach the process in every session. The `/proc` read is not an instrument for this question.
