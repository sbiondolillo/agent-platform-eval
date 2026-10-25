# Finding: spend-attribution

The row asks whether the cost of one session can be read from an operator-owned store, keyed by the session id. Capture: [`capture.md`](capture.md), [`capture-platform.md`](capture-platform.md).

## What the docs say

The docs were read after the first session, on 2026-10-24.

- [Cloud environments](https://code.claude.com/docs/en/cloud-environments): a session passes the environment's values to the commands Claude runs, "except `OTEL_*` variables. Claude Code uses those for its own telemetry export and doesn't pass them to the commands it runs." The Bash result of every session matches this.
- [Monitoring usage](https://code.claude.com/docs/en/monitoring-usage): telemetry from a cloud session is configured in the organization's server-managed settings, or in the environment's variables. A credential belongs in server-managed settings, because "Anyone who uses an environment can read its variables". The export "doesn't go through the agent proxy", and the collector host must be on the environment's allowlist. The session attribute is `ccr.session.id`, the value of `CLAUDE_CODE_REMOTE_SESSION_ID`.
- [Settings](https://code.claude.com/docs/en/settings): the telemetry variables are dropped from a repository's `.claude/settings.json` `env` block, so a repository cannot turn telemetry on.

## Cloud Sessions

Three sessions ran with the environment's variables as the route, the second documented one. The Claude Code process held none of the eight telemetry variables in any session, read from `/proc/<pid>/environ` by name. No metric reached the stack, with or without the header variable. The VM resolves no hostname without the proxy, so an export that bypasses the proxy has no route out of the VM. The proxy route itself is open: an empty POST through the network secret returned 200. The documented route did not work on 2026-10-25 and the docs do not explain the result. The other route, server-managed settings, needs an organization Owner and was not tried.

Spend for a Cloud session is therefore read where Anthropic shows it: the account's usage view, which [`../cloud-logging/finding.md`](../cloud-logging/finding.md) records. The docs document no per-session cost figure outside the telemetry export.

## Platform

DSF v1.2.1 starts the agent container with three names: `HOME`, `ANTHROPIC_API_KEY` and `ANTHROPIC_BASE_URL` (`src/Core/Sandbox.cs`). The `--pass-env` names go to the integration tests only. The agent has no telemetry variable and no route for one without a factory change. The factory owns the environment of the agent, so the change is one list in one file.

Spend on the platform is read from the gateway ledger on llm-01, which holds every call with its cost. The cloud-logging probe summed one issue #2 delivery to $0.5289 over 26 calls. The key is the consumer and the time window. A `run_id` column exists and is empty ([`../run-history/finding.md`](../run-history/finding.md)).

## Open

- Why the environment's telemetry variables did not reach the Claude Code process is a question for Anthropic.
- Server-managed settings as the route is untested.
- A factory that passes the telemetry names to the agent would give the platform the per-session metric with `session.id`, from the same OpenTelemetry export, to a collector the lab owns.

## Report cells

Cloud: the documented export route, telemetry variables on the environment, delivered nothing in three sessions, the Claude Code process held none of them, and spend is read only from Anthropic's usage view.

Platform: the gateway ledger holds every call with its cost, attributed by consumer and time window; DSF v1.2.1 passes no telemetry variable to the agent, which is one list in one file to change.
