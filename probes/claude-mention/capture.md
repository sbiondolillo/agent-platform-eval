# @claude side experiment: capture

All facts are from 2026-10-24 and are public. Times are UTC. No secret value is copied: the log masks each token as `***`.

## 1. The App grant alone

- 23:38:24Z: the operator posted the comment from [`prompt.md`](prompt.md) on issue #2 of `sbiondolillo/platform-eval-sample`.
- Nothing answered within five minutes. No Actions run started.
- The repo had no Claude workflow. `.github/workflows/` held `ci.yml`, `factory.yml`, `probe-vault-secret.yml`, `review-feedback.yml` and `runner-smoke.yml`.
- The Claude GitHub App was already installed with the repo granted. That grant is what lets Cloud sessions push (see [`../forge-credential/finding.md`](../forge-credential/finding.md)).

## 2. `/install-github-app`

- The operator ran `/install-github-app` in the Claude Code CLI on the workstation.
- It opened [PR 9](https://github.com/sbiondolillo/platform-eval-sample/pull/9) "Add Claude Code GitHub Workflow", from branch `add-claude-github-actions-1792885407850`. The pull request adds `.github/workflows/claude.yml`.
- It set one repository secret, `CLAUDE_CODE_OAUTH_TOKEN`, at 23:43:30Z.
- The operator merged PR 9 (squash) at 23:44:59Z.

The merged workflow, read with `git show origin/main:.github/workflows/claude.yml`:

```yaml
name: Claude Code

on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
  issues:
    types: [opened, assigned]
  pull_request_review:
    types: [submitted]

jobs:
  claude:
    if: |
      (github.event_name == 'issue_comment' && contains(github.event.comment.body, '@claude')) ||
      (github.event_name == 'pull_request_review_comment' && contains(github.event.comment.body, '@claude')) ||
      (github.event_name == 'pull_request_review' && contains(github.event.review.body, '@claude')) ||
      (github.event_name == 'issues' && (contains(github.event.issue.body, '@claude') || contains(github.event.issue.title, '@claude')))
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: read
      issues: read
      id-token: write
      actions: read # Required for Claude to read CI results on PRs
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 1

      - name: Run Claude Code
        id: claude
        uses: anthropics/claude-code-action@v1
        with:
          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}

          # This is an optional setting that allows Claude to read CI results on PRs
          additional_permissions: |
            actions: read

          # Optional: Give a custom prompt to Claude. If this is not specified, Claude will perform the instructions specified in the comment that tagged it.
          # prompt: 'Update the pull request description to include a summary of changes.'

          # Optional: Add claude_args to customize behavior and configuration
          # See https://github.com/anthropics/claude-code-action/blob/main/docs/usage.md
          # or https://code.claude.com/docs/en/cli-reference for available options
          # claude_args: '--allowed-tools Bash(gh pr *)'
```

## 3. The second comment

- 23:45:02Z: the operator posted the same comment again.
- Run [40143995075](https://github.com/sbiondolillo/platform-eval-sample/actions/runs/40143995075) "Claude Code", event `issue_comment`, started 23:45:05Z and completed 23:45:45Z with conclusion `success`.
- Run 40144010120, at 23:45:18Z, fired on the bot's own comment and was skipped.
- `claude[bot]` posted "Claude Code is working…" at 23:45:15Z. It edited that comment to the final reply at 23:45:41Z.

### Job log lines

From `gh run view 40143995075 --repo sbiondolillo/platform-eval-sample --log`. The timestamp prefix is cut to the time of day.

Runner and image:

```text
23:45:08 Current runner version: '2.338.0'
23:45:08 ##[group]Runner Image Provisioner
23:45:08 Hosted Compute Agent
23:45:08 Region: westus3
23:45:08 Cloud: Azure
23:45:08 ##[group]Runner Image
23:45:08 Image: ubuntu-24.04
23:45:08 Version: 20261012.334.1
23:45:08 ##[group]GITHUB_TOKEN Permissions
23:45:08 Actions: read
23:45:08 Contents: read
23:45:08 Issues: read
23:45:08 Metadata: read
23:45:08 PullRequests: read
23:45:08 Secret source: Actions
```

Action version:

```text
23:45:08 Download action repository 'anthropics/claude-code-action@v1' (SHA:925afb53776cf1a2b738c6bdbed37b4d4000ef13)
23:45:24 Installing Claude Code native build 2.1.310...
```

Tokens. The model credential is the subscription OAuth token from the repository secret. The forge credential is a GitHub App token that the action gets from the workflow's OIDC token, and revokes at the end:

```text
23:45:10   claude_code_oauth_token: ***
23:45:13   CLAUDE_CODE_OAUTH_TOKEN: ***
23:45:13 Comment contains exact trigger phrase '@claude'
23:45:13 Auto-detected mode: tag for event: issue_comment
23:45:13 Requesting OIDC token...
23:45:13 OIDC token successfully obtained
23:45:13 Exchanging OIDC token for app token...
23:45:14 App token successfully obtained
23:45:14 Using GITHUB_TOKEN from OIDC
23:45:14 Checking permissions for actor: sbiondolillo
23:45:15 Permission level retrieved: admin
23:45:41 ##[start-action display=Revoke app token;id=claude.__run_9]
```

Allowed tools and output visibility:

```text
23:45:26 Running Claude Code via SDK (full output hidden for security)...
23:45:26 Rerun in debug mode or enable `show_full_output: true` in your workflow file for full output.
23:45:26   "allowedTools": [
23:45:26     "Glob",
23:45:26     "Grep",
23:45:26     "LS",
23:45:26     "Read",
23:45:26     "mcp__github_comment__update_claude_comment",
23:45:26     "mcp__github_ci__get_ci_status",
23:45:26     "mcp__github_ci__get_workflow_run_details",
23:45:26     "mcp__github_ci__download_job_log",
23:45:26     "Bash(git add:*)",
23:45:26     "Bash(git commit:*)",
23:45:26     "Bash(/home/runner/work/_actions/anthropics/claude-code-action/v1/scripts/git-push.sh:*)",
23:45:26     "Bash(git rm:*)"
23:45:26   ],
```

Model, turns and cost:

```text
23:45:27   "message": "Claude Code initialized",
23:45:27   "model": "claude-sonnet-5-5"
23:45:39   "type": "result",
23:45:39   "subtype": "success",
23:45:39   "is_error": false,
23:45:39   "duration_ms": 12464,
23:45:39   "num_turns": 6,
23:45:39   "total_cost_usd": 0.0804783,
23:45:39   "permission_denials_count": 0,
23:45:39   "modelUsage": {
23:45:39     "claude-haiku-5-5": {
23:45:39     "claude-sonnet-5-5": {
23:45:40 Log saved to /home/runner/work/_temp/claude-execution-output.json
23:45:40 Set session_id: ae4eb46b-74db-4919-aa2f-e754438d8686
```

No change was pushed. The action looked for its work branch and did not find it:

```text
23:45:40 Branch claude/issue-2-20261024-2345 does not exist remotely, no branch link will be added
23:45:41 ✅ Updated issue comment 6391028501 with job link
```

### The final reply

From `gh api repos/sbiondolillo/platform-eval-sample/issues/2/comments --jq '.[-1].body'`, unedited:

````markdown
**Claude finished @sbiondolillo's task in 12s** —— [View job](https://github.com/sbiondolillo/platform-eval-sample/actions/runs/40143995075)

---
### Summary

The issue asks for a `--shout` option on the console program, so that `Ada --shout` prints `HELLO, ADA!` and `--shout` alone prints `HELLO, WORLD!`. The option must also appear in `--help`. I would add the option as a symbol in the command tree in `src/Core/GreetCommand.cs`. Its action would upper-case the greeting when the flag is set. `src/App/` stays untouched, as the issue says.

I would also touch these test files:
- **`specs/features/greeting.feature`:** add the three scenarios from the issue.
- **`tests/Specs/Steps/GreetingSteps.cs`:** bind the new steps. It currently has only the greeter steps, so it needs three new ones:
  - `the console program runs with the arguments {string}`
  - `the console program prints {string}`
  - `the console program prints a line that contains {string}`

  These steps would call the command tree in process and capture its output.

I would probably leave `src/Core/Greeter.cs` alone and do the upper-casing in the command action. I would also not add a test under `tests/Integration/`, because the new scenarios use no stubbed service. I haven't changed any file or opened a pull request.
````
