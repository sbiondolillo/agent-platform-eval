# Cloud environment

Probe run 2026-10-24. The setup script installs the pinned .NET SDK, and a session printed the pinned version.

The environment `agent-platform-eval` came from the "New environment" dialog at claude.ai/code. The dialog offers five fields: Name, Network access, Network secrets, Setup script, Environment variables. It has no repository field. The repository is chosen per session.

Settings used:

- Network access: Limited, with "Allow package managers" checked.
- Allowed domains: `dot.net`, `dotnet.microsoft.com`, `builds.dotnet.microsoft.com`, `aka.ms`, `api.nuget.org`.
- Setup script: [`setup.sh`](setup.sh).

The session ran on `sbiondolillo/platform-eval-sample`, branch `main`. The prompt was: "Run `dotnet --version` and `head -2 /etc/os-release` and reply with the exact output of both."

Output:

```
10.0.402
PRETTY_NAME="Ubuntu 24.04.5 LTS"
NAME="Ubuntu"
```

Context used: 7%. The setup-phase duration is not recorded. The UI did not show it.

## Finding for the model-pin row

The session ran on Opus 5.5 at Medium effort, as the session picker showed. The target repo's `.claude/settings.json` pins `claude-sonnet-5-5`. The repo pin does not set the model of a Cloud session. The delivery run must select Sonnet 5.5 in the picker.

## Side effect

The session created the branch `claude/sweet-meitner-7ku479` on the target repo.

## Second prompt: build and test

The same Cloud session, on 2026-10-24. The prompt was: "Run `dotnet build -c Release` and then `dotnet test -c Release`. Reply with the last 10 lines of each command's output and the wall time of each."

| Command | Exit | Result | Wall time |
|---|---|---|---|
| `dotnet build -c Release` | 0 | Build succeeded. 0 Warning(s), 0 Error(s). Time Elapsed 00:00:24.60. | about 25.5 s |
| `dotnet test -c Release` | 0 | Passed 1, Failed 0, Skipped 0, Total 1. Duration 138 ms. | about 8.0 s |

- NuGet restore succeeded with network access "Limited" and "Allow package managers". No NuGet domain beyond the allowlist above was needed.
- Context used stayed at 7%.
- The session wrote its logs to its own scratchpad under `/tmp/claude-0/`.
