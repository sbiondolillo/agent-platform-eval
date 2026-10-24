# Run history

Probe for [run-history](../../docs/plan.md). Question: can a script list the runs and download a transcript from outside the product, by API or CLI? The answer sets whether DSF v2 can keep its own run record on each arm. No Cloud session was used. The row is read from the workstation CLI, the public docs and the GitHub API.

## Cloud Sessions

Export path: not documented. The web UI at claude.ai/code lists sessions in its sidebar, and the Share link shows a session to a signed-in Claude account. The CLI `claude --teleport <session-id>` loads the full conversation from the server into the terminal, but it writes no file, and no CLI command lists cloud sessions (`claude agents --json --all` listed one local session and no cloud session). The in-session MCP tools `list_sessions`, `get_session`, `list_events` and `get_event` read the history, but they exist only inside a session, and the docs describe no public API with the same functions: the only documented HTTP endpoint, the scheduled-task `/fire`, starts a session and is "not part of the Claude Platform API surface". The docs give retention only per account, "Code and session data are subject to the retention and usage policies for your account type", which is 30 days, or 5 years on a consumer plan that allows data use for model improvement.

Captures: [`capture.md`](capture.md). Docs: https://code.claude.com/docs/en/claude-code-on-the-web, https://code.claude.com/docs/en/data-usage, https://code.claude.com/docs/en/cli-reference, https://code.claude.com/docs/en/routines, https://code.claude.com/docs/en/sessions. The URL https://docs.claude.com/en/docs/claude-code/cloud-sessions answers 404.

## Platform

`gh run list` lists the factory runs from outside, and `gh run view --log` downloads the job log, with every phase line and the full output of a failed gate ([`capture-platform.md`](capture-platform.md)). Both are documented GitHub REST endpoints. The log is kept 90 days, the repo setting and the maximum for a public repo, and any signed-in account with read access can read it. The factory uploads no artifact: both delivery runs return an empty artifact list, and v1.2.1 has no `upload-artifact` step.

The factory's own record of the model conversation is Claude Code's JSONL transcript. `src/Core/Sandbox.cs:31-35` mounts the container's home from `.factory/sandbox-home/<guid>/` in the factory checkout on the runner host, so the transcript outlives the container. The v1.2.1 starter workflow then pushes those files to a private store repo (`templates/starter/.github/workflows/factory.yml:40-67`). The target repo was made from the v1.1.0 starter and has no store step, so its transcripts stay on `sandbox-01` only until the next run's checkout cleans `.factory/`. On the day of the probe, `sandbox-01` held the 5 transcripts of the last run, 40118345316, and none from the earlier runs.

The gateway ledger, `telemetry.gateway_calls`, holds one row per model call with model, status, tokens and cost ([`../cloud-logging/capture-platform.md`](../cloud-logging/capture-platform.md#gateway-ledger)). The operator reads it with SQL as `mcp_ro`. It keeps every row and moves rows to cold storage after 90 days. v1.2.1 sends no run id, so a run's rows are matched by consumer and time window.

## Comparison

| | Cloud Sessions | Platform |
|---|---|---|
| list runs from outside | web UI sidebar only. No CLI command and no documented API lists cloud sessions. | yes: `gh run list`, REST "List workflow runs for a repository" |
| download a transcript from outside | not documented. `claude --teleport` renders it in the terminal and writes no file. The Share link shows it to a signed-in account. | the job log: yes, `gh run view --log`. The model transcript: from the store repo when the v1.2.1 store step is set up. Without it, only over SSH to the runner host, until the next run. |
| per-call record | none outside the product. `list_events` and `get_event` exist inside a session only. | the gateway ledger, one row per model call, read with SQL |
| retention | per account: 30 days, or 5 years on a consumer plan that allows model improvement. Deleting a session removes its data. | job log 90 days. Store repo until deleted. Ledger keeps every row, cold after 90 days. Runner host until the next run. |
| documented API | none for listing or reading. Only the scheduled-task `/fire` endpoint, which starts a session. | GitHub REST for runs, logs and artifacts. The ledger is our own ClickHouse table. |

Cell for the report, Cloud Sessions: sessions are listed and read only inside the product, in the web UI, the Share link, `claude --teleport` and the in-session MCP tools, and no documented API or CLI command lists them or exports a transcript to a file.
Cell for the report, Platform: `gh` lists the runs and downloads the 90-day job log, the gateway ledger holds every model call, and the model transcripts are files that the v1.2.1 starter pushes to a private store repo, but this target repo's v1.1.0 workflow has no store step, so they stay on the runner host only until the next run.
