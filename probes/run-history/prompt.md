# Run-history probe

No Cloud session. This row is read from the workstation CLI, the public docs and the GitHub API.

The operator's `claude` CLI is signed in on the workstation. Every command is read-only. No command starts an interactive session. Taken 2026-10-24 at about 23:20 UTC.

```
# Cloud Sessions side, workstation CLI
claude --version
claude --help
claude agents --help
claude logs --help
claude attach --help
claude remote --help
claude sessions --help
claude teleport --help
claude purge --help
claude agents --json --all        # counted and keys listed, not dumped

# Cloud Sessions side, public docs
curl -sL https://docs.claude.com/en/docs/claude-code/cloud-sessions
curl -sL https://docs.claude.com/en/docs/claude-code/data-usage
curl -sL https://docs.claude.com/en/docs/claude-code/cli-reference
curl -sL https://docs.claude.com/en/docs/claude-code/claude-code-on-the-web
curl -sL https://code.claude.com/docs/llms.txt
curl -sL https://code.claude.com/docs/en/claude-code-on-the-web.md
curl -sL https://code.claude.com/docs/en/sessions.md
curl -sL https://code.claude.com/docs/en/data-usage.md
curl -sL https://code.claude.com/docs/en/cli-reference.md
curl -sL https://code.claude.com/docs/en/routines.md
curl -sL https://code.claude.com/docs/en/cross-session-messaging.md
curl -sL https://code.claude.com/docs/en/zero-data-retention.md
curl -sL https://code.claude.com/docs/llms-full.txt     # searched for the session tool names and "Sessions API"

# Platform side, GitHub
gh run list --repo sbiondolillo/platform-eval-sample --workflow factory.yml --limit 5 --json databaseId,conclusion,createdAt
gh run download --help | head -20
gh api repos/sbiondolillo/platform-eval-sample/actions/runs/40117342098/artifacts --jq '.artifacts | map({name, size_in_bytes, expires_at})'
gh api repos/sbiondolillo/platform-eval-sample/actions/runs/40118345316/artifacts --jq '.artifacts | map({name, size_in_bytes, expires_at})'

# Platform side, factory source at dotnet-software-factory v1.2.1
git show origin/main:.github/workflows/factory.yml                     # in platform-eval-sample
git grep -n -i "upload-artifact" v1.2.1 -- .
git grep -n -i "transcript" v1.2.1 -- src
git grep -n '"\.factory"\|\.factory/' v1.2.1 -- src .github templates/starter/.github .gitignore
git grep -n -E "Report" v1.2.1 -- src
git show v1.2.1:src/Core/Sandbox.cs
git show v1.2.1:templates/starter/.github/workflows/factory.yml
git log --oneline v1.1.0..v1.2.1 -- templates/starter/.github/workflows/factory.yml

# Platform side, runner host sandbox-01, read-only: names, counts, sizes and times only
ls -ld .factory .factory/sandbox-home
find .factory/sandbox-home -name '*.jsonl' -printf '%TY-%Tm-%Td %TH:%TM %s\n'
```
