# Capture: tool-model-policy probe, platform arm

Probe [tool-model-policy](../../docs/plan.md). Taken 2026-10-24 from source only. No host was changed and no run was started. The sources and their commits:

- `sbiondolillo/dotnet-software-factory` at tag `v1.2.1` (commit `69b7f49`), read with `git show v1.2.1:<path>` and `git grep v1.2.1`.
- `sbiondolillo/platform-eval-sample` at `main` (`3d571b5`), the target repository that the factory clones into the container's `/work`.
- `homelab-ansible` `roles/squid_proxy/defaults/main.yml` at `a17bb31`.

## 1. Where the model is chosen

### `git grep -n -i -E 'model|claude-|ANTHROPIC_MODEL|--model' v1.2.1 -- src sandbox templates`

The hits, by role:

| File:line | What it is |
|---|---|
| `src/Core/ConsoleCommands.cs:15` | `private const string Model = "claude-sonnet-5-5";` |
| `src/Core/ConsoleCommands.cs:193` | the factory run request: `Model, 50, Model, 200, Model, 50`, which is the plan, build and review model, each with its turn limit |
| `src/Core/ConsoleCommands.cs:254` | the feedback run request: `Model, 200, Model, 50`, the build and review model |
| `src/Core/FactoryRun.cs:16,18,20` | the record fields `PlanModel`, `BuildModel`, `ReviewModel` |
| `src/Core/PlanPhase.cs:84`, `src/Core/BuildPhase.cs:27`, `src/Core/ReviewPhase.cs:38` | each phase passes its model to `agent.RunAsync` |
| `src/Core/ClaudeCodeAgent.cs:40` | `"--model", model,` on the `claude` command line |
| `sandbox/Dockerfile:14` | `RUN npm install -g @anthropic-ai/claude-code`, the image's Claude Code |

No hit for `ANTHROPIC_MODEL`. No command-line option, configuration file or environment variable sets the model. The workflow line that starts the factory passes `--repo`, `--issue` and `--pass-env ANTHROPIC_BASE_URL` only (`platform-eval-sample` `.github/workflows/factory.yml`, line 46, quoted in [`../model-credential/capture-platform.md`](../model-credential/capture-platform.md#1-the-job-step-fetches-the-secrets)).

The model is a single constant in code, the same for all three phases. A change of model is a code change and a new factory release.

### The `claude` command line

`src/Core/ClaudeCodeAgent.cs`, lines 36 to 46:

```csharp
        CommandResult result = await sandbox.RunAsync(
            "claude",
            [
                "-p", prompt,
                "--model", model,
                "--max-turns", maxTurns.ToString(CultureInfo.InvariantCulture),
                "--output-format", "json",
                "--dangerously-skip-permissions",
            ],
            [],
            cancellationToken).ConfigureAwait(false);
```

### Settings files inside the container

- The image's user is `node`, with home `/home/node` (`sandbox/Dockerfile`, lines 27 to 29). The image writes no Claude Code settings file.
- The factory overrides the home. `src/Core/Sandbox.cs`, line 9, `private const string Home = "/tmp/sandbox-home";`. Lines 33 to 35 make a new empty host directory, `.factory/sandbox-home/<guid>`, and mount it at that path. Line 58 sets `HOME={Home}`. Line 62 makes `{Home}/.config` and nothing else. The container thus starts with no `~/.claude/settings.json` and no `~/.claude.json`.
- The work tree at `/work` is the target repository. Its `.claude/settings.json` holds one entry, `"model": "claude-sonnet-5-5"` (`platform-eval-sample` `main`, lines 1 to 3). That is the same value as the factory constant. Claude Code gives a `--model` flag precedence over a settings file, so the file does not decide the model on the platform.

### Can the agent inside the container change the model?

Not for the factory's own calls. Each call is a new `claude -p` process with `--model` fixed by the factory, and a flag wins over any settings file that the agent could write.

The agent can still call another model. `src/Core/Sandbox.cs`, lines 59 and 60, put `ANTHROPIC_API_KEY` and `ANTHROPIC_BASE_URL` in the environment of every process in the container. Line 43 of `ClaudeCodeAgent.cs` passes `--dangerously-skip-permissions`, so the agent runs shell commands with no approval. A shell command such as `claude -p ... --model <other>`, or a direct HTTP call to the gateway, reaches any model the gateway serves with the same key. The factory does not see such a call, and its cost is outside the `total_cost_usd` that the factory sums. The gateway ledger records it under consumer `dsf`. This was read from source and was not run.

## 2. Where the tools are chosen

### `git grep -n -i -E 'mcp|allowedTools|disallowedTools|permission-mode|settings\.json|dangerously|\.claude' v1.2.1 -- src sandbox templates`

```
src/Core/ClaudeCodeAgent.cs:43:                "--dangerously-skip-permissions",
templates/starter/docs/write-an-issue.md:150:... runs the skill `write-issue` in `.claude/skills/` ...
```

No hit for `mcp`, `allowedTools`, `disallowedTools`, `permission-mode` or `settings.json` in `src/`. The factory passes no allowed-tools list, no MCP configuration and no settings file. It passes `--dangerously-skip-permissions`, so every built-in tool is allowed with no prompt. The template hit is a doc line for a person, not factory code.

The target repository holds no `.mcp.json` (`git ls-tree -r --name-only origin/main` lists `.claude/settings.json` and `.claude/skills/write-issue/` only). The container thus starts with no MCP server.

### Can the agent add an MCP server inside the container?

Yes, by the same command that the Cloud arm ran: `claude mcp add` writes the server to `$HOME/.claude.json`, which is in the mounted sandbox home. Nothing in the factory prevents the command. One container serves the whole run: `src/Core/FactoryRun.cs`, line 158, starts one sandbox, and line 161 makes one agent that the plan, build and review phases share (`src/Core/FeedbackRun.cs`, lines 79 and 82, the same for a feedback run). By Claude Code's local scope, a server added in one phase would load in the next phase's `claude -p` call from `/work`. This was not run on the platform.

### Would its egress reach one?

The container's only path out is Squid on `egress-01`, and a remote MCP server is a hostname that must be on an allowlist ([`../egress/finding.md`](../egress/finding.md)). `homelab-ansible` `roles/squid_proxy/defaults/main.yml` at `a17bb31`:

- The shared list, lines 26 to 62: package, image and SDK hosts, for example `.npmjs.org` (line 27), `.pypi.org` (line 29), `.docker.io` (line 35), `.nuget.org` (line 55).
- The `sandbox01` block, lines 77 to 97, for source `10.25.0.10`: `.github.com` (81), `.githubusercontent.com` (82), `.blob.core.windows.net` (83), `artifacts-cli.infisical.com` (84), `aka.ms` (89), `geocoding-api.open-meteo.com` (93) and `webhook.site` (97, a probe host that the experiment's teardown removes).

`mcp.deepwiki.com` is on neither list, so Squid refuses its CONNECT with 403, as it refused the apex `open-meteo.com` in the egress probe. The same holds for any remote MCP host not on the lists. Two gaps remain. A stdio MCP server is a local process: the agent can install one from `.npmjs.org` or `.pypi.org`, and only the hosts that process calls are then checked. And the `.github.com` and `.githubusercontent.com` grants are wildcards over the whole forge.

## 3. The gateway

[`../model-credential/capture-platform.md`](../model-credential/capture-platform.md#3-what-the-key-is), section 3, quotes the gateway's `custom_auth.py` at `homelab-services` `bff7a03`, lines 13 to 25. The auth function maps the `dsf` key to the consumer name `dsf` and returns nothing else: no spend budget, no rate limit and no model list. That capture states that the key thus reaches every model in the gateway's `config.yaml`, four Anthropic models and three local models. It does not name them. Section 5 of the same capture records that `/v1/models` from sandbox-01 returns 401 with no key, so the model list was not read from the host again.

The gateway is thus not a model control for the factory. It only attributes each call to `dsf`.

## 4. The review gate

`src/Core/ReviewPhase.cs`, lines 20 to 38: `RunAsync` takes a `model` parameter (line 23), builds its own prompt from the issue and the diff (line 30), and calls `agent.RunAsync(prompt, model, maxTurns, "review", ...)` (line 38). The caller passes `request.ReviewModel` (`src/Core/FactoryRun.cs`, lines 226, 356, 462 and 595), which `ConsoleCommands.cs` line 193 sets to the same `Model` constant as the plan and build phases. The review gate is a second call to the same model, in the same container, with a different prompt and a limit of 50 turns. It is not an independent model.
