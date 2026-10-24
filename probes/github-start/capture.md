# GitHub-start probe: capture

All facts are from 2026-10-24 and are public. Times are UTC. No secret value is copied: the Actions log masks the token as `***`, and this file names secrets only. The steps and the workflow are in [`prompt.md`](prompt.md).

## 1. The scheduled task

The operator created the scheduled task `factory-start` at claude.ai/code/routines. The create dialog held these fields:

| field | value |
|---|---|
| Name | `factory-start` |
| Prompt | the routine prompt from [`prompt.md`](prompt.md) |
| Permissions | the line "Permissions set by environment", with the model selector beside it (Default, Sonnet 5.5). The operator chose Sonnet 5.5. |
| Trigger | API, with the text "Token will be generated when you save" |
| Advanced settings | tabs General, Connectors, Behavior, Notifications |
| General: Repository | `sbiondolillo/platform-eval-sample`, with the text "Picking a repository makes this a Claude Code task" |
| General: Cloud environment | `agent-platform-eval`, with the text "Permissions and network are set here" |

After Create, the dialog showed the token once. The token starts with the documented `sk-ant-oat01-` prefix. The Fire URL is:

```
https://api.anthropic.com/v1/claude_code/routines/trig_012MB9CP7cLaKr3TXt9sGyPx/fire
```

The trigger id in the URL is not a secret. The token is the only credential.

## 2. The repository setup

- Secret `CLAUDE_FIRE_URL`: set at 23:49:17Z.
- Secret `CLAUDE_FIRE_TOKEN`: set first with a wrong value, then set again at 23:52:11Z (the `updatedAt` from `gh secret list`).
- [PR 8](https://github.com/sbiondolillo/platform-eval-sample/pull/8) "ci: add the github-start probe workflow": merged (squash) at 23:50:50Z as `f5fe225`. The repo does not allow auto-merge, so `gh pr merge --auto` failed with "Auto merge is not allowed for this repository". A plain merge was used.
- The operator created the label `cloud-start` and added it to issue #2.

## 3. Run 40144384611: wrong token

[Run 40144384611](https://github.com/sbiondolillo/platform-eval-sample/actions/runs/40144384611) "Probe: GitHub start", event `issues`, created 23:50:56Z, conclusion failure.

| step | conclusion | started | completed |
|---|---|---|---|
| job `fire` | failure | 23:50:58 | 23:51:02 |
| Set up job | success | 23:50:58 | 23:50:58 |
| Fire the scheduled task | failure | 23:50:58 | 23:50:59 |
| Comment on the issue | success | 23:50:59 | 23:51:00 |
| Complete job | success | 23:51:00 | 23:51:00 |

The fire step's log, from the `shell:` line to the error:

```
2026-10-24T23:50:58.9397865Z shell: /usr/bin/bash -e {0}
2026-10-24T23:50:59.0580816Z Response body:
2026-10-24T23:50:59.0641589Z {"type":"error","error":{"type":"authentication_error","message":"Invalid bearer token"},"request_id":"req_011CgMxcDthamJefKU26wwkt"}
2026-10-24T23:50:59.0664491Z ##[error]The fire endpoint returned HTTP 401
2026-10-24T23:50:59.0676076Z ##[error]Process completed with exit code 1.
```

The 401 came back about 0.12 s after the `shell:` line. The log shows the `Authorization` header as `***`.

The same label event also started [run 40144384635](https://github.com/sbiondolillo/platform-eval-sample/actions/runs/40144384635) of the `factory` workflow, created 23:50:56Z. Its job `factory` was skipped, because the label was not `factory`.

## 4. Run 40144473941: correct token

The operator set `CLAUDE_FIRE_TOKEN` again and applied the label again. [Run 40144473941](https://github.com/sbiondolillo/platform-eval-sample/actions/runs/40144473941) "Probe: GitHub start", created 23:52:19Z, conclusion success.

| step | conclusion | started | completed |
|---|---|---|---|
| job `fire` | success | 23:52:21 | 23:52:27 |
| Set up job | success | 23:52:22 | 23:52:22 |
| Fire the scheduled task | success | 23:52:22 | 23:52:23 |
| Comment on the issue | success | 23:52:23 | 23:52:25 |
| Complete job | success | 23:52:25 | 23:52:25 |

The fire step's log:

```
2026-10-24T23:52:22.9667704Z shell: /usr/bin/bash -e {0}
2026-10-24T23:52:23.9016932Z Response body:
2026-10-24T23:52:23.9020233Z {"claude_code_session_id":"cse_0199MGjiwzUgfL8ApR3HSKGL","claude_code_session_url":"https://claude.ai/code/cse_0199MGjiwzUgfL8ApR3HSKGL","type":"routine_fire"}
```

The response came back about 0.94 s after the `shell:` line. The run took 8 s from creation to the end of the job, and the job took 6 s.

## 5. The comments on issue #2

From `gh api repos/sbiondolillo/platform-eval-sample/issues/2/comments`:

| created_at | user | body |
|---|---|---|
| 2026-10-24T23:50:59Z | github-actions[bot] | Probe github-start: the fire endpoint returned HTTP 401. Invalid bearer token |
| 2026-10-24T23:52:24Z | github-actions[bot] | Probe github-start: the scheduled task started a session. https://claude.ai/code/cse_0199MGjiwzUgfL8ApR3HSKGL |

## 6. The session

The operator opened https://claude.ai/code/cse_0199MGjiwzUgfL8ApR3HSKGL.

- Title "factory-start", with a lightning icon.
- Activity line: "Ran 2 scheduled check-ins, found files, used 3 tools".
- The reply summarises issue #2: the `--shout` option. It would add the option in `src/Core/GreetCommand.cs` and touch `specs/features/greeting.feature` and `tests/Specs/Steps/GreetingSteps.cs`. It would leave `src/App/` and `tests/Integration/` alone.
- The reply notes: "The issue is already closed by PR #3, and a similar summary was posted on it earlier, so this may be a repeat request".
- The reply ends: "I changed no file, made no commit or push, and created no branch."
- The composer label reads "Sonnet 5.5 Medium".
- The environment panel shows `agent-platform-eval` "Not connected", the repository, and a branch `claude/wonderful-d…nci-d4lo1e`.
- The session is not listed under Recents in the sidebar.
- The session posted nothing to GitHub. The two comments above are from the workflow's `github-actions[bot]`.
