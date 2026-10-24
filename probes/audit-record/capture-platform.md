# Capture: audit-record probe, platform arm

Probe [audit-record](../../docs/plan.md). Taken 2026-10-24. This is a documentary reading. It cites source and public GitHub reads only. No write test ran on any host.

Sources:

- The factory, `sbiondolillo/dotnet-software-factory` at tag `v1.2.1`, read with `git show v1.2.1:<path>`.
- The platform arm's workflow, `.github/workflows/factory.yml` in `sbiondolillo/platform-eval-sample`, read with `gh api repos/sbiondolillo/platform-eval-sample/contents/.github/workflows/factory.yml`.
- `actions/checkout` at tag `v7`, `action.yml`, read with `gh api`.
- The earlier captures [`../substrate/capture-platform.md`](../substrate/capture-platform.md), [`../cloud-logging/capture-platform.md`](../cloud-logging/capture-platform.md), [`../forge-credential/finding.md`](../forge-credential/finding.md) and [`../model-credential/finding.md`](../model-credential/finding.md).

## 1. The agent's own transcript

Claude Code writes its transcript under `$HOME/.claude/projects/`. The factory sets `HOME` to a host directory that it mounts into the container.

`src/Core/Sandbox.cs`, lines 9 and 29 to 35:

```csharp
    private const string Home = "/tmp/sandbox-home";
...
        string user = string.Create(CultureInfo.InvariantCulture, $"{GetUid()}:{GetGid()}");

        // The home is a directory on the host, so the transcript that Claude Code writes under it outlives the container.
        // The process that creates it owns it, and that is the user the container runs as.
        string home = Path.Combine(rootDirectory, ".factory", "sandbox-home", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(home);
        List<string> volumes = ["--volume", $"{workTree}:/work", "--volume", $"{home}:{Home}"];
```

Lines 55 and 58 of the same file pass `"--user", user` and `"--env", $"HOME={Home}"` to `docker run`. `GetUid` and `GetGid` call libc `getuid` and `getgid` (lines 116 to 120).

- The container runs as the uid and gid of the factory process. On sandbox-01 that is the runner user `github-runner`, `997:998` ([`../substrate/capture-platform.md`](../substrate/capture-platform.md)).
- The factory process creates the home directory, so `github-runner` owns it on the host. The container writes into it as the same uid. The agent thus owns its own transcript file.
- The mount is read-write. The `.git` directory of the work tree is the one mount with `:ro` (line 43). The home has no such flag.
- Claude Code runs with `--dangerously-skip-permissions` (`src/Core/ClaudeCodeAgent.cs` line 43). No permission prompt and no classifier stands between a shell command and the file.

The home is not under the work tree. `rootDirectory` is `host.RootDirectory`, which `src/App/Program.cs` line 23 sets to `Directory.GetCurrentDirectory()`. The workflow's "Run the factory" step runs `dotnet run` in the job's workspace, the checkout of the factory at `v1.2.1` (sample repo `factory.yml` lines 29 to 32 and 46). The host path is therefore `<job workspace>/.factory/sandbox-home/<guid>/`, under the runner's work directory on sandbox-01.

The work tree itself is a temporary directory, `Directory.CreateTempSubdirectory("factory-run-")` (`src/Core/ConsoleCommands.cs` line 187). The factory deletes it in a `finally` block (lines 197 to 200, and `Remove` at lines 319 to 325). Nothing in `src/` deletes `.factory/sandbox-home`. A grep of `src/` at `v1.2.1` for `Delete`, `cleanup` and `.factory` finds `directory.Delete(recursive: true)` in `Remove` (the work tree), `File.Delete(reportFile)` in `FeedbackRun.cs` line 98 (the agent's `threads.json`), and no other delete.

The transcript thus stays on the runner after the job. The next job on the runner removes it: `actions/checkout` has `clean` with the default `true`, described as "Whether to execute `git clean -ffdx && git reset --hard HEAD` before fetching" (`action.yml` lines 57 to 59 at `v7`). `-x` removes ignored files, and the factory's `.gitignore` line 1 is `.factory/`.

Each `Sandbox.StartAsync` call makes a new `<guid>` home. A factory run starts one container for all its phases (`src/Core/FactoryRun.cs` line 158), and each feedback run starts its own (`src/Core/FeedbackRun.cs` line 79). A container thus mounts its own transcript only. The homes of earlier runs on the same workspace are not mounted into it.

## 2. The factory's own output

A grep of `src/` and `.github/` at `v1.2.1` for `Report`, `transcript`, `WriteAllText` and `upload-artifact`, plus `GITHUB_STEP_SUMMARY` and `AppendAllText`:

| output | written by | where | source |
|---|---|---|---|
| progress lines, such as `agent: plan end, N turns, $X, S s` | the factory process on the host | its stdout, which the runner puts in the job log | `src/Core/ClaudeCodeAgent.cs` lines 34 and 60 to 62 |
| the job summary, a table of phases with time and spend | the factory process on the host | the file named by `GITHUB_STEP_SUMMARY`, which GitHub shows on the run | `src/Core/ConsoleCommands.cs` line 194, `src/Core/FactoryRun.cs` lines 655 to 666 |
| the pull request body: base commit, passed tests, check gate, Redos, spend, seconds, factory version | the factory process on the host | the pull request on GitHub | `src/Core/Deliver.cs` lines 6 and 21 |
| `.factory/plan.md`, `.factory/review.json`, `.factory/threads.json` | the agent, inside the container | the temporary work tree, mounted at `/work`. `.factory/` is in the target's `.gitignore`, so `git add -A` does not commit them. Deleted with the work tree. | `src/Core/PlanPhase.cs` line 16, `src/Core/ReviewPhase.cs` lines 12 and 32, `src/Core/FeedbackRun.cs` lines 32 and 76 |
| the agent's transcript | Claude Code, inside the container | `.factory/sandbox-home/<guid>/` on the runner | section 1 |

The phase files are the agent's own reports to the factory. The agent writes them, so they are inputs, not records.

Nothing in `src/` uploads a file. The platform arm's workflow has no `upload-artifact` step and no step after "Run the factory". The factory's own self-build workflow and its starter template at `v1.2.1` have a step "Push the transcripts to the store" (`.github/workflows/factory.yml` lines 39 to 66, `templates/starter/.github/workflows/factory.yml` from line 40). That step runs on the host after the factory, copies each `.jsonl` under `.factory/sandbox-home` to a private store repo, and pushes with a deploy key from Actions secrets. The sample repo was made from the starter at `v1.1.0`, which has no such step, and it holds no Actions secret. In the platform arm, the transcript therefore never leaves sandbox-01.

## 3. The GitHub job log

From [`../cloud-logging/capture-platform.md`](../cloud-logging/capture-platform.md):

- The runner service on sandbox-01, user `github-runner`, uploads the job's output to GitHub. It runs on the host, outside the container.
- The repo's retention setting is 90 days, the maximum for a public repo.
- Any signed-in GitHub account with read access can read it. On a public repo, that is every signed-in account. A signed-out reader gets "Sign in to view logs".

The agent adds text to the log only through output that the factory prints, such as a test gate's stdout. It has no path to change or remove a line after the runner sends it.

## 4. The gateway ledger

From [`../cloud-logging/capture-platform.md`](../cloud-logging/capture-platform.md) and [`../model-credential/finding.md`](../model-credential/finding.md):

- The LiteLLM gateway on `llm-01` writes one row per model call to `telemetry.gateway_calls` on the lab ClickHouse, under consumer `dsf`.
- The table has a 90-day TTL that moves rows to cold storage and deletes none.
- The read role `mcp_ro` accepts connections only from the Management VLAN.

The container holds the gateway key in `ANTHROPIC_API_KEY` and reaches `10.99.0.186:8200`, the one port the Sandbox VLAN may reach on `llm-01`. Each call it makes therefore adds a row. It has no route and no credential to the ClickHouse store, so it cannot change or remove a row.

## 5. The git history of the pull request branch

From [`../forge-credential/finding.md`](../forge-credential/finding.md) and the source:

- The factory process on the host runs `git add -A`, `git commit` and `git push origin <branch>` (`src/Core/Git.cs` lines 46 to 85). The push authenticates with `FACTORY_GITHUB_TOKEN`, a fine-grained token on the operator account, injected by `infisical run` into the factory process.
- The container receives only `ANTHROPIC_API_KEY` and `ANTHROPIC_BASE_URL` (`src/Core/Sandbox.cs` lines 59 and 60). It holds no forge credential.
- The work tree's `.git` is mounted read-only in the container (`src/Core/Sandbox.cs` line 43), so the agent cannot write a hook or rewrite a commit that the host's git reads.

The agent writes the file contents that the factory commits. It cannot change the history once the factory pushes it.

## Inventory

| Record | Written by | Lives on | Inside the container's reach |
|---|---|---|---|
| agent transcript, `.jsonl` under `$HOME/.claude/projects/` | Claude Code in the container, as `997:998` | sandbox-01, `<job workspace>/.factory/sandbox-home/<guid>/`, owned by `github-runner`, until the next job's `git clean -ffdx`. Not uploaded. | yes: a read-write mount, owned by the uid the container runs as, with `--dangerously-skip-permissions` and no classifier |
| phase files, `.factory/plan.md`, `review.json`, `threads.json` | the agent in the container | the temporary work tree on sandbox-01, deleted at the end of the run | yes: the work tree mount. The agent writes them. |
| job summary | the factory process on the host | GitHub, with the run | no path: the summary file is named in the host's environment, which the container does not receive |
| GitHub job log | the runner service on the host, from the factory's output | GitHub, 90 days, readable by any signed-in account | no path to edit or remove. The agent adds lines only through output that the factory prints. |
| gateway ledger, `telemetry.gateway_calls` | the gateway on `llm-01` | the lab ClickHouse, 90 days hot, then cold, no delete | no path to edit or remove: the gateway key adds rows, and the store is reachable only from the Management VLAN |
| pull request branch history | the factory process on the host, with `FACTORY_GITHUB_TOKEN` | GitHub, branch `factory/<runId>` | no credential: the container holds no forge token, and `.git` is mounted read-only |
