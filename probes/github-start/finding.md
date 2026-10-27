# GitHub-start probe

Cloud Sessions probe on [issue #2](../../docs/plan.md). Question: does a session start from the label, or what error does the endpoint return? The answer tells DSF v2 whether a GitHub label can start a Cloud Session, the way the `factory` label starts a run on the platform arm. The evidence is in [`capture.md`](capture.md), and the steps and the workflow are in [`prompt.md`](prompt.md). Docs: https://code.claude.com/docs/en/routines.

## Cloud Sessions

The `cloud-start` label on issue #2 starts a job on a GitHub-hosted runner, and the job sends a POST to the scheduled task's fire endpoint with a bearer token that belongs to that one task. The endpoint returned a session id and a session URL about one second after the POST ([run 40144473941](https://github.com/sbiondolillo/platform-eval-sample/actions/runs/40144473941)). The session runs the saved prompt in the saved environment and repository, and it gets the fire payload as untrusted text, not as instructions. The reply stays in the session unless the prompt tells it to post on GitHub, so the issue got only the workflow's own comment with the URL. The session is listed under the task's History and not under Recents in the sidebar. A wrong token gave a clean HTTP 401 "Invalid bearer token" in about 0.1 s and started no session ([run 40144384611](https://github.com/sbiondolillo/platform-eval-sample/actions/runs/40144384611)). The docs set a limit of 30 fires an hour per task and 100 API fires an hour per account, and the endpoint takes no idempotency key, so a retried POST can start a second session.

## Platform

The `factory` label on an issue starts the delivery run on the self-hosted runner `sandbox-01` (see [`../platform-delivery/finding.md`](../platform-delivery/finding.md)). The trigger is `issues: types: [labeled]` in `.github/workflows/factory.yml` of `sbiondolillo/platform-eval-sample`, lines 8 and 9. Line 27 gates the job to the `factory` label and to the repository owner as sender: `github.event.label.name == 'factory' && github.event.sender.login == github.repository_owner`. The same label event that fired the probe also started run 40144384635 of `factory`, and that job skipped itself because the label was `cloud-start`. No external endpoint and no start credential are involved: GitHub itself queues the job on the runner.

## Comparison

| row | Cloud Sessions | Platform |
|---|---|---|
| trigger | `issues: labeled` with label `cloud-start`, in a workflow that the repo owner writes | `issues: labeled` with label `factory` and the owner as sender, `factory.yml` lines 8, 9 and 27 |
| who runs the glue | a GitHub-hosted job, written and kept by the repo owner, that calls `curl` and posts a comment | GitHub Actions itself. No glue job: the label queues the factory job on the self-hosted runner. |
| credential for the start | a per-task bearer token (`sk-ant-oat01-` prefix), shown once at create and kept as the repo secret `CLAUDE_FIRE_TOKEN` | none beyond GitHub's own event. The runner's registration does the rest. |
| what starts | a Cloud session that runs the task's saved prompt, model, repository and environment, with the payload as untrusted text | the factory's delivery run, one job on `sandbox-01` |
| start latency | fire response in about 0.94 s. The glue job took 6 s, and the run 8 s from creation. | the job is queued at once on the runner. The delivery run took 6 min 45 s in attempt 2. |
| where the result lands | in the session at claude.ai/code, under the task's History. GitHub gets only what the prompt tells the session to post. | the pull request, the job log, and the gateway ledger |
| retry semantics | no idempotency key: each POST starts a new session. Limits 30 fires an hour per task, 100 an hour per account. A wrong token returns HTTP 401 and starts nothing. | "Re-run" on the Actions run, or `gh workflow run factory.yml`. Each attempt is a new job. |

## Managed Agents

Settled by the delivery, 2026-10-27 ([`../platform-delivery/finding.md`](../platform-delivery/finding.md)). Managed Agents has no GitHub trigger; a session starts only from `POST /v1/sessions`. So the start is a GitHub Actions job that holds a workspace API key as a repository secret and calls the API, the same glue shape as the Cloud arm's fire endpoint, with two differences. The credential is a workspace API key, which starts any session and reads every vault of that workspace, where the Cloud arm's token fired one saved task; the arm uses a dedicated workspace for that reason. And the job is the whole orchestrator, not a trigger: it waits for the sessions, computes the verdict and posts the result, where the Cloud session's reply stayed at claude.ai/code. There is no idempotency key on session creation, so the job dedupes on the head SHA with a marker comment before it calls the API. Both sessions were listed as `running` with their metadata 45 s after the dispatch.

## Report cells

Cloud: a label can start a Cloud session, but only through a GitHub job that the repo owner writes and that holds a per-task bearer token, and the session's reply stays at claude.ai/code unless the prompt posts it back.

Platform: the `factory` label starts the delivery run on the self-hosted runner directly through the workflow's `issues: labeled` trigger, gated to the repo owner, with no start credential.

Managed Agents: a workflow job starts a session with a workspace API key held as a repository secret, with no trigger in the product and no idempotency key, so the job dedupes and orchestrates.
