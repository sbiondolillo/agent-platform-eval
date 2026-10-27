# Finding: spend-attribution

The row asks whether the cost of one session can be read from an operator-owned store, keyed by the session id. Capture: [`capture.md`](capture.md) (Cloud), [`capture-workstation.md`](capture-workstation.md) (workstation bisect), [`capture-platform.md`](capture-platform.md) (platform). The store is a Grafana Cloud stack, ambercroissant1151.

## What the docs say

The docs were read after the first session, on 2026-10-24.

- [Cloud environments](https://code.claude.com/docs/en/cloud-environments): a session passes the environment's values to the commands Claude runs, "except `OTEL_*` variables. Claude Code uses those for its own telemetry export and doesn't pass them to the commands it runs." The Bash result of every session matches this.
- [Monitoring usage](https://code.claude.com/docs/en/monitoring-usage): telemetry from a cloud session is configured in the organization's server-managed settings, or in the environment's variables. A credential belongs in server-managed settings, because "Anyone who uses an environment can read its variables". The export "doesn't go through the agent proxy", and the collector host must be on the environment's allowlist. The session attribute is `ccr.session.id`, the value of `CLAUDE_CODE_REMOTE_SESSION_ID`.
- [Settings](https://code.claude.com/docs/en/settings): the telemetry variables are dropped from a repository's `.claude/settings.json` `env` block, so a repository cannot turn telemetry on.
- The Grafana Cloud "Claude Code" integration page (Connections > Add new connection > Claude Code) sets `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=cumulative` in its shell snippet. The Claude Code monitoring docs and the Grafana OpenTelemetry setup wizard do not mention temporality.

## Cloud Sessions

Four sessions ran with the environment's variables as the route, the second documented one. Nothing was exported. The Claude Code process held none of the telemetry variables in any session, read from `/proc/<pid>/environ` by name. No metric reached the stack with the header variable, nor with cumulative temporality.

The workstation run proves the variables and the stack. The same variables, with cumulative temporality, landed seven series in the same stack. So the cause is upstream of the gateway: the process in the VM never received the variables. The VM also resolves no hostname without the proxy, so an export that bypasses the proxy has no route out.

The other documented route, server-managed settings, needs an organization Owner and was not tried. Spend for a Cloud session is read where Anthropic shows it: the account's usage view, which [`../cloud-logging/finding.md`](../cloud-logging/finding.md) records.

## Platform

The factory owns the environment of the agent. DSF v1.2.1 passes the agent container three names: `HOME`, `ANTHROPIC_API_KEY` and `ANTHROPIC_BASE_URL` (`src/Core/Sandbox.cs`). A throwaway branch adds eleven: nine telemetry names, `NO_PROXY` and `no_proxy`.

With that branch, the cost metric lands in Grafana keyed by `session_id`, one series per factory phase. The metric is a floor. The headless process exits without a final flush, so a phase loses up to one 10 s export interval and its last turn. One run matched the factory's log to four places; the other read low on every phase. A LogQL sum of cost_usd over a session's api_request events matches the factory log to four decimals for all six sessions.

The log events are exact. Loki holds one `api_request` event per API request, keyed by `session_id`, with model, tokens, `cost_usd` and latency. The sum of `cost_usd` over a session's events is the exact cost. The gateway ledger on llm-01 holds every call with its cost too, but its `run_id` column is empty ([`../run-history/finding.md`](../run-history/finding.md)).

Two faults stood in the way:

- Claude Code exports delta counters by default, and the Grafana gateway refuses them with 400. Only the Grafana integration page documents the fix, cumulative temporality.
- The repository secret's first value was not a header pair, so the container sent no Authorization header. The relay saw 401 with `auth=absent`.

The exporter is silent on failure in every arm. No log line, in the CLI or the Actions log, showed a refused export. The local relay, [`otlp-relay.py`](otlp-relay.py), was the only instrument that read the gateway's answer.

## Open

- Why the Claude Code process in a Cloud session got none of the environment's telemetry variables is a question for Anthropic.
- Server-managed settings as the Cloud route is untested.
- For DSF v2, a factory that passes the telemetry names natively. It sets cumulative temporality, and either flushes on exit or sums cost over the events.

## Managed Agents

Probed 2026-10-27 from the workstation. Docs: https://platform.claude.com/docs/en/managed-agents/session-observability. Each session carries the `metadata` the create body set, `arm` and `row`, and `usage.list_cost` in whole cents. The list by agent read back, on 2026-10-27:

| session | row | list_cost (cents) | active seconds |
|---|---|---|---|
| `sesn_01BdfqEvYjyeHEFzS61c1VgR` | substrate | 6 | 53 |
| `sesn_01DEn3e9vkgUfUE1gLFDyTMU` | forge-credential | 12 | 197 |
| `sesn_01CzTF7pWYJrPg4cnkJsLcor` | egress | 3 | 46 |
| `sesn_01ShSm9niXACrBsUXsV7xeD9` | tool-model-policy | 3 | 7 |

The `session.usage` event in the transcript holds the same figures with the token counts. `list_cost` is at list price, not the contract rate, and a session on a shared agent is told apart by its metadata, so a job that tags `repo`, `pr` and `sha` gets the cost of one review per pull request from the list call. Nothing had to be exported from the sandbox.

The OpenTelemetry route, proven 2026-10-27: the Claude Console's OpenTelemetry settings (Organization settings, OpenTelemetry, beta) take a telemetry destination with a provider, an OTLP endpoint, credentials in header values, a content mode and a workspace filter. Docs: https://platform.claude.com/docs/en/manage-claude/opentelemetry/api. The operator added Grafana Cloud stack `ambercroissant1151` as a destination with content mode Metadata only and the managed-agents workspace selected. Session `sesn_01RLfMHCpiSUNJLmDpw2myJ4`, created at 15:53:19Z, appeared in Tempo as trace `8e3b749d1efb663d86c92e3`, service `claude-platform`, root span `anthropic.sessions.create`, 4.95 s, found by `{ span.anthropic.session.id = "sesn_01RLfMHCpiSUNJLmDpw2myJ4" }` within the minute. The API's usage for that session is 94 output tokens, 6 input, 4370 cache read, 4462 cache write, 1 cent. The vendor emits the spans: nothing in the sandbox and nothing in the job exports, which is the opposite of both earlier arms. The spans carry `anthropic.session.id`, the environment id and the GenAI token attributes per model request, and not the session's `metadata`, so a pull request is joined to its trace by the session id the judge writes into its review comment. Read back in Grafana's Agent Observability view on 2026-10-27: the trace has 5 spans, three `anthropic.model_request` calls, the first with `gen_ai.usage.output_tokens` 64, `gen_ai.usage.input_tokens` 4374 and `gen_ai.usage.cache_write.input_tokens` 4370, and the conversation view sums the three calls to 8.9k tokens, 94 output tokens and $0.01, equal to the API's 94 output tokens and `list_cost` of 1 cent. So the cost of one session is readable in Grafana by session id, which is the instrument the row names. The spans also carry `anthropic.organization.id`, `anthropic.workspace.id` and `gen_ai.conversation.id`, a thread id. The conversation view showed the bash tool's input and output, which the Metadata only mode says it never carries; whether the destination was saved as Metadata only or Full content is the operator's check. `list_cost` is on the API only; Grafana's dollar figure is its own pricing of the token counts.

## Report cells

Cloud: the documented environment route exported nothing in four sessions, the Claude Code process held none of the variables, and spend is read only from Anthropic's usage view.

Platform: with a nine-name pass-through in the factory, the cost metric and one event per API request land in the operator's Grafana keyed by session id, and the metric reads within one export interval of the factory's own log.

Managed Agents: `usage.list_cost` per session, with the caller's `metadata` on it, gives the cost of one review keyed by pull request from a list call, and a telemetry destination in the Console sends every session's spans with token counts to Grafana Cloud with no export from the sandbox or the job.
