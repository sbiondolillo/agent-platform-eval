# @claude side experiment

Side experiment for [issue #2](../../docs/plan.md). Question: where the run behind an `@claude` mention executed, an Actions log on a GitHub runner or a session at claude.ai/code. The answer tells DSF v2 whether `@claude` is a third way to start an agent run from GitHub. The evidence is in [`capture.md`](capture.md), and the steps are in [`prompt.md`](prompt.md).

## Result

The Claude GitHub App grant alone answers nothing: the first mention at 23:38:24Z got no reply and started no run, because the repo had no workflow that listens for `@claude`. The CLI command `/install-github-app` adds two things to the repo: a pull request with `.github/workflows/claude.yml`, and the repository secret `CLAUDE_CODE_OAUTH_TOKEN`. After the merge, the second mention ran as Actions job [40143995075](https://github.com/sbiondolillo/platform-eval-sample/actions/runs/40143995075) on a GitHub-hosted `ubuntu-24.04` runner, with `anthropics/claude-code-action@v1`, Claude Code 2.1.310 and `claude-sonnet-5-5` under the subscription OAuth token, in 40 s of wall time and 12 s of model work over 6 turns. No session appeared at claude.ai/code, so the run log is the record, with the same 90-day retention as any Actions log, and the action hides the full model output from that log unless `show_full_output` is set. The action obeyed the "do not change any file" instruction: it pushed no branch, opened no pull request, and posted only the reply, as `claude[bot]`, with a GitHub App token that it got from the job's OIDC token and revoked at the end. This is a third execution substrate beside the Cloud microVM and the lab container, and it uses the forge's own runner with the forge's credential model.

| Row | `@claude` mention |
|---|---|
| Trigger | A comment, review or issue that contains `@claude`, matched by the `if:` of `.github/workflows/claude.yml`. The App grant alone does not trigger a run. |
| Where it ran | An Actions job on a GitHub-hosted runner: `ubuntu-24.04`, image 20261012.334.1, Azure `westus3`. |
| Credential | Model: the subscription OAuth token in the repository secret `CLAUDE_CODE_OAUTH_TOKEN`. Forge: a Claude GitHub App token from the job's OIDC exchange, revoked at job end, plus a read-only `GITHUB_TOKEN`. |
| Record | The Actions job log, kept 90 days by default, and the edited issue comment. Full model output is hidden from the log by default. No claude.ai/code session. |
| Cost readout | `total_cost_usd: 0.0804783` in the log's result line, an estimate that Claude Code computes. The run draws on the subscription, so it is not a per-run charge. |

Sentence for the report: an `@claude` mention runs only after `/install-github-app` adds a workflow and an OAuth secret, and then it runs as an ordinary Actions job on a GitHub-hosted runner with the job log as its only record, not as a Cloud session.
