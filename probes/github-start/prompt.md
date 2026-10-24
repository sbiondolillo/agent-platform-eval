# GitHub-start probe

Cloud Sessions arm. A GitHub Actions workflow in sbiondolillo/platform-eval-sample fires a scheduled task through its API trigger when an issue gets the `cloud-start` label. The label is not `factory`, because factory.yml starts a delivery run on that label. The workflow is in [PR 8](https://github.com/sbiondolillo/platform-eval-sample/pull/8).

## The routine's prompt

The operator pastes this prompt into the scheduled task. The fire payload reaches the session as a `<routine-fire-payload>` block.

```
You were started from a GitHub issue label. The fire payload names the issue. Read that issue in sbiondolillo/platform-eval-sample with the GitHub tool, then reply here with a one-paragraph summary of what it asks for and which files you would touch. Do not change any file, do not commit, do not push, do not create a branch.
```

## Operator steps

1. Create the scheduled task at claude.ai/code/routines. Name `factory-start`, model Sonnet 5.5, repository sbiondolillo/platform-eval-sample, environment agent-platform-eval, trigger API. Paste the prompt above. Select Generate token and copy the Fire URL and the token.
2. Store the Fire URL and the token as repository secrets. Each command asks for the value, so the value does not go into the shell history.

   ```
   gh secret set CLAUDE_FIRE_URL --repo sbiondolillo/platform-eval-sample
   gh secret set CLAUDE_FIRE_TOKEN --repo sbiondolillo/platform-eval-sample
   ```

3. Merge PR 8.
4. Create the label and add it to issue #2.

   ```
   gh label create cloud-start --repo sbiondolillo/platform-eval-sample
   gh issue edit 2 --repo sbiondolillo/platform-eval-sample --add-label cloud-start
   ```

5. Read the run log of "Probe: GitHub start" and the comment on issue #2. If the comment holds a session URL, open the session and read its reply.

At teardown, the operator deletes the workflow file, the two secrets, the label and the scheduled task.

## The workflow

`.github/workflows/probe-github-start.yml` in sbiondolillo/platform-eval-sample:

```yaml
# The github-start probe of agent-platform-eval, Cloud Sessions arm: the `cloud-start` label on an issue fires a scheduled task through its API trigger, and the run log and an issue comment show whether a session started.
# The job runs on a GitHub-hosted runner, so the platform arm's egress allowlist is not involved.
# The operator deletes this file and the secrets CLAUDE_FIRE_URL and CLAUDE_FIRE_TOKEN at teardown.
name: "Probe: GitHub start"

on:
  issues:
    types: [labeled]

permissions:
  contents: read
  issues: write

jobs:
  fire:
    if: github.event.label.name == 'cloud-start'
    runs-on: ubuntu-latest
    steps:
      - name: Fire the scheduled task
        id: fire
        env:
          CLAUDE_FIRE_URL: ${{ secrets.CLAUDE_FIRE_URL }}
          CLAUDE_FIRE_TOKEN: ${{ secrets.CLAUDE_FIRE_TOKEN }}
        run: |
          set -euo pipefail
          # jq reads the issue from the event file, so the title cannot inject into the JSON.
          jq -c '{text: "issue #\(.issue.number) of \(.repository.full_name): \(.issue.title)"}' "$GITHUB_EVENT_PATH" > request.json
          code=$(curl -sS -o response.json -w '%{http_code}' -X POST "$CLAUDE_FIRE_URL" \
            -H "Authorization: Bearer $CLAUDE_FIRE_TOKEN" \
            -H 'anthropic-version: 2026-10-21' \
            -H 'Content-Type: application/json' \
            --data @request.json) || true
          echo "code=$code" >> "$GITHUB_OUTPUT"
          echo "Fire endpoint HTTP status: $code" >> "$GITHUB_STEP_SUMMARY"
          # The response body holds the session URL or the error, and no secret.
          echo "Response body:"
          cat response.json 2>/dev/null || echo "(no body)"
          echo
          case "$code" in
            2??) ;;
            *) echo "::error::The fire endpoint returned HTTP $code"; exit 1 ;;
          esac

      - name: Comment on the issue
        if: always()
        env:
          GH_TOKEN: ${{ github.token }}
          GH_REPO: ${{ github.repository }}
          ISSUE_NUMBER: ${{ github.event.issue.number }}
          CODE: ${{ steps.fire.outputs.code }}
        run: |
          set -euo pipefail
          url=$(jq -r '.claude_code_session_url // empty' response.json 2>/dev/null || true)
          if [ -n "$url" ]; then
            msg="Probe github-start: the scheduled task started a session. $url"
          else
            err=$(jq -r '.error.message // empty' response.json 2>/dev/null || true)
            [ -n "$err" ] || err=$(head -c 2000 response.json 2>/dev/null || echo "no response body")
            msg="Probe github-start: the fire endpoint returned HTTP ${CODE:-none}. ${err}"
          fi
          gh issue comment "$ISSUE_NUMBER" --body "$msg"
```
