# Subagent record

Probe for [subagent-record](../../docs/plan.md). Question: where the subagent's record is, and whether it survives the VM. The answer sets whether DSF v2 can audit the work of a subagent on each arm, as it audits the parent agent.

## Cloud Sessions

Inside the VM, the subagent has its own files under the session's `subagents/` folder: a 19-line `agent-<id>.jsonl`, a `.meta.json` and a `.prefix.json`, beside the parent transcript in `/root/.claude/projects/` ([`capture.md`](capture.md)). The parent transcript holds the subagent's report as a message row, and the session repeated the two lines exactly after a Stop. The web UI shows the subagent as a collapsed row "Ran agent" with its name and model, and whether the UI shows the subagent's own transcript was not observed. The subagent's files in the VM go with the container, and the crash-resume reclaim step that checks this is pending ([`../crash-resume/capture.md`](../crash-resume/capture.md)). The server-side transcript holds at least the report. The teleport path writes no file on the workstation ([`../cloud-logging/finding.md`](../cloud-logging/finding.md)), so it gives no copy of the subagent's record.

## Platform

The factory sets the agent's `HOME` to a host directory under the job workspace, `.factory/sandbox-home/<guid>/`, mounted into the container ([`../audit-record/capture-platform.md`](../audit-record/capture-platform.md)). Claude Code writes a subagent's files under the parent's session folder in that `HOME`, so they land in the same place as the parent's transcript, on the runner host. This is read from source and the Cloud layout, and no platform run was checked for a `subagents/` folder. The files stay on the runner until the next job's `git clean -ffdx`, and the sample workflow has no transcript store step, so they are never uploaded. The gateway ledger records each model call of a subagent as a call of consumer `dsf` ([`../cloud-logging/capture-platform.md`](../cloud-logging/capture-platform.md#gateway-ledger)). The subagent's calls are not distinguished: `telemetry.gateway_calls` has no column for an agent or a parent call, and the 66 `dsf` rows of 2026-10-24 all have an empty `run_id` and an empty `span_id`.

## Comparison

| Row | Cloud Sessions | Platform |
|---|---|---|
| subagent transcript inside the sandbox | yes: `subagents/agent-<id>.jsonl` (19 lines), `.meta.json` and `.prefix.json` in the session folder under `/root/.claude/projects/` | from source: the same layout under `.factory/sandbox-home/<guid>/` on the runner host. Not checked in a run. |
| visible in the run record | the report, as a row "Message from subagent", and a collapsed row "Ran agent" with name and model. The subagent's own transcript in the UI: not observed. | no. The job log holds the factory's phase lines, and the transcript is not uploaded. |
| survives the sandbox | the file in the VM goes with the container (reclaim step pending). The server-side transcript holds at least the report. Teleport writes no file. | yes, on the runner host, until the next job's `git clean -ffdx`. No store step in the sample workflow. |
| per-call record | not exposed per session | the gateway ledger, one row per call under `dsf`. Subagent calls not distinguished from the parent's. |

## Managed Agents

Settled by the docs and the delivery, 2026-10-27. Managed Agents documents no subagent, so the `change` skill's three parallel reviewers became three sessions started by the job, each with its own id, metadata, events and cost, listed by `GET /v1/sessions` and read by `GET /v1/sessions/{id}/events` ([`../run-history/finding.md`](../run-history/finding.md)). There is no record to lose, because there is no child: every reviewer is a first-class session, and its transcript outlives its sandbox on the server, read with the API key.

## Report cells

Cloud: the subagent keeps its own transcript in the VM's session folder, and the server-side transcript keeps its report and a row with its model, but whether the subagent's own transcript outlives the container is pending the reclaim step.

Platform: the subagent's transcript lands beside the parent's on the runner host until the next job, it is never uploaded without the v1.2.1 store step, and the gateway ledger counts its calls under `dsf` with no link to the parent.

Managed Agents: there is no subagent; each reviewer is its own session with its own server-side record, and the job is the fan-out.
