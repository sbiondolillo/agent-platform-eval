# Crash resume

Probe for [crash-resume](../../docs/plan.md).

## The question

What survives an interruption: history, files, background shells and subagents? The answer sets whether DSF v2 can stop and continue a run on each arm, or must start it again.

## Cloud Sessions

Captures: [`capture.md`](capture.md). Session "Crash resume probe", 2026-10-24 from 23:26 UTC, and 2026-10-25 at about 01:23 UTC.

### The Stop button

The Stop button interrupts the current turn only, and the VM keeps running. Nothing was lost:

- The heartbeat loop and the background `sleep 600` were still running.
- The untracked marker file was still on disk.
- The subagent's transcript, meta and prefix files were unchanged.
- The next message continued the same session with its full history.

### The idle reclaim

The session was left idle after Message 4, answered at about 23:31. At about 01:23 its environment read "Connecting", and Message 4 was sent again. The session reconnected and answered.

- The disk survived. The start file, the heartbeat log, the marker file and the subagent's three files were all unchanged since 23:26.
- Every process died. The heartbeat's last log line is 23:41:49, so the reclaim came about eleven minutes after the answer at 23:31.
- The shell snapshot file name changed, and the session directory's mtime is 01:23, the reconnect.
- The background `sleep 600` had ended at about 23:37, so it proves nothing. The heartbeat is the process evidence.
- The history survived. The session gave the subagent's two lines from its own transcript, and the UI showed the full conversation.

So a session resumes on its own files and history after a reclaim. Any process it started must be started again.

### Harness controls

Two controls showed during the probe. The harness refused a foreground `sleep 180` before it ran, so a long wait moves to a background task. A stop hook asked the session to commit and push the untracked marker. It asked again after the reclaim, and the session declined each time. Both controls change what a delivery run does.

## Platform

Capture: [`capture-platform.md`](capture-platform.md), read from `dotnet-software-factory` `v1.2.1`.

A factory run is one GitHub Actions job. The container is a `docker run --detach ... sleep infinity` on `sandbox-01` (`src/Core/Sandbox.cs:46-65`). It is removed when the run ends (`src/Core/Sandbox.cs:112-114`), and the work tree is deleted too (`src/Core/ConsoleCommands.cs:197-200`). The factory has no resume code. A retry is a new run with a new run id and a new branch `factory/<runId>`.

What remains after the job is what it pushed: the branch and the pull request. The job log stays 90 days ([`../cloud-logging/capture-platform.md`](../cloud-logging/capture-platform.md)). The v1.2.1 starter's store step saves the transcripts to a private repo ([`../run-history/finding.md`](../run-history/finding.md)). The sample repo uses the v1.1.0 starter, so its transcripts stay on `sandbox-01` until the next job's checkout.

The source registers no signal handler. A cancelled job may skip the removal and leave the container running. This case was not tested.

## Comparison

| Row | Cloud Sessions, Stop button | Cloud Sessions, idle reclaim | Platform |
|---|---|---|---|
| interrupt mid-run | the Stop button ends the turn. The VM keeps running. | the container was reclaimed about eleven minutes after the last answer | cancel the Actions job. No resume follows. |
| resume after interrupt | yes: the next message continues the same session | yes: the next message reconnects the session with its history | none. A retry is a new run with a new run id and branch. |
| files after a crash | all survived | all survived | the work tree is deleted. Only pushed work and saved transcripts remain. |
| background processes after a crash | all survived | all died | the container is removed, so nothing keeps running. A cancel was not tested. |
| subagents after a crash | the files survived, unchanged | the files survived, and the session read the report from its history | the files are in the transcripts, kept by the store step |

## Managed Agents

Probed 2026-10-27 in session `sesn_016CYBjUYebbPbNDKCb2Kmx2` ([`capture-ma.md`](capture-ma.md)). Docs: https://platform.claude.com/docs/en/managed-agents/environments. The first message wrote `/tmp/crash-resume-marker` at 15:02:53Z and started `sleep 7200` as PID 259, then the session went idle. A second message 21 minutes later was accepted by `POST /v1/sessions/{id}/events` and the session answered in 18 active seconds: the marker file was there with its content, the sleeper was gone, and `/proc/uptime` read 7 seconds. So the idle sandbox was checkpointed and the resume booted a fresh kernel from that checkpoint, with the filesystem intact and every process lost, which is what the Cloud arm's idle reclaim did. The history is server-side, and the second answer shows the agent read its own first answer. A stop from the caller's side was not tested; the docs name no stop button, and a session that is deleted loses its record. The two halves cost 4 cents together. One fault on the caller's side is worth a note: the events endpoint takes `{"events": [...]}`, and a bare event is refused with 400.

## Report cells

Cloud: the Stop button loses nothing, and an idle reclaim keeps the disk and the history and kills every process, so a session resumes on its own files.

Platform: a factory job has no resume; the container is removed at job end and only the pushed branch, the pull request and the saved transcript remain.

Managed Agents: an idle sandbox is checkpointed, and a message 21 minutes later resumed it on a fresh boot with the files intact and every process gone, the same as the Cloud arm's idle reclaim.
