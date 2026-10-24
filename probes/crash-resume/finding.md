# Crash resume

Probe for [crash-resume](../../docs/plan.md). Question: what survived an interruption: history, files, background shells, subagents. The answer sets whether DSF v2 can stop and continue a run on each arm, or must start it again.

## Cloud Sessions, interruption from the UI

The Stop button interrupts the current turn only, and the VM keeps running ([`capture.md`](capture.md)). After a Stop, the heartbeat loop and the background `sleep 600` were still running, and the untracked marker file was still on disk. The subagent's three files were unchanged, and the next message continued the same session with its full history. Two harness controls showed during the probe: the harness refused a foreground `sleep 180` before it ran, and a stop hook asked the session to commit and push the untracked files. Both controls change what a delivery run does, because a long foreground wait moves to a background task, and an untracked file triggers a request to commit it.

## Cloud Sessions, after the container is reclaimed

Pending. The session is left idle; the step runs when the UI shows Connecting.

## Platform

A factory run is one GitHub Actions job, started by an `issues: labeled` event or by `workflow_dispatch` (sample repo `.github/workflows/factory.yml` lines 7 to 18). Each run makes a new run id and a new temporary work tree (`src/Core/ConsoleCommands.cs:186-187` at `v1.2.1`), and each phase calls `claude -p` with no session flag (`src/Core/ClaudeCodeAgent.cs:36-44`). There is no resume code: a grep of `src/` for "resume", "Resume" and "continue" finds only `continue;` statements in loops, so a retry is a new run on a new branch `factory/<runId>` (`src/Core/Deliver.cs:24`). A failed run removes the container (`src/Core/Sandbox.cs:112-114`) and the work tree (`src/Core/ConsoleCommands.cs:197-200`), and leaves `.factory/sandbox-home/` with the transcripts on the runner until the next job's checkout. The source registers no signal handler, so a cancelled job can skip both removals, and this case was not tested.

## Comparison

| Row | Cloud Sessions, interruption | Cloud Sessions, after reclaim | Platform |
|---|---|---|---|
| interrupt mid-run | the Stop button ends the turn. The VM keeps running. | pending | cancel the Actions job. No resume follows. |
| resume after interrupt | yes: the next message continues the same session with its history | pending | none. No resume code. A retry is a new run with a new run id and branch. |
| files after a crash | the untracked file survived | pending | a failed run deletes the work tree. `.factory/sandbox-home/` stays until the next checkout. A cancel was not tested. |
| background processes after a crash | the heartbeat loop and the background sleep survived | pending | a failed run removes the container, so nothing keeps running. A cancel was not tested. |
| subagents after a crash | the subagent's files survived, unchanged | pending | the subagent's files sit in `.factory/sandbox-home/` and stay until the next checkout |
