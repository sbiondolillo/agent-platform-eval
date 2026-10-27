# Tool and model policy

Probe for [issue #2](../../docs/plan.md). Question: when the agent or the operator picks a model outside the pin, and when the agent adds an MCP server that the environment does not configure, the control that stopped each, or none. The answer sets who decides the model and the tools in each arm of the DSF v2 decision.

## Cloud Sessions

The agent ran `claude mcp add` for `mcp.deepwiki.com`, and the command wrote the server to the VM's `/root/.claude.json`, but the egress policy refused the tunnel with a 403, and the session's tool list did not change, because the session loads its tools from the account's connectors at start ([`capture.md`](capture.md)). The control was thus the egress policy plus the session's tool loading. That tool list holds the account's Google Drive connector, which the environment never configured, and the GitHub connector with write tools such as `merge_pull_request` and `create_repository`. The model picker offered twelve models, and the switch to Opus 5.5 went through with no prompt, no confirmation and no policy message. The repository's model pin in `.claude/settings.json` is ignored ([`../cloud-environment/finding.md`](../cloud-environment/finding.md)). One prompt earlier, the model-side safeguard refused a credential sweep and switched that session to Sonnet 5 ([`../forge-credential/capture-refusal.md`](../forge-credential/capture-refusal.md)). That is the one model-side control observed, and it acts on prompt content, not on configuration.

## Platform

The factory picks the model in code: one constant, `claude-sonnet-5-5`, at `src/Core/ConsoleCommands.cs` line 15 of `v1.2.1`, passed as `--model` to every `claude` call for the plan, build and review phases ([`capture-platform.md`](capture-platform.md)). A flag wins over the target repository's settings file, so no file in the work tree changes it. The agent cannot change the model of the factory's calls, but it holds the gateway key in its environment and runs shell commands with no approval, so it can start its own call to any of the seven gateway models, because the gateway sets no model list on the `dsf` key. The factory passes no allowed-tools list, no MCP configuration and no settings file, only `--dangerously-skip-permissions`, so the container starts with no MCP server and every built-in tool allowed. The agent can add an MCP server with `claude mcp add`, and it would persist across the phases of one run, because the run uses one container. A remote server is stopped by Squid, whose allowlists for sandbox-01 do not name `mcp.deepwiki.com`, but a stdio server installed from an allowed package registry runs as a local process. The review gate is a second call to the same model constant, with its own prompt. No content safeguard was observed on the platform, because no platform run sent a prompt that would trigger one.

## Comparison

| Row | Cloud Sessions | Platform |
|---|---|---|
| who picks the model | the operator, in the session picker. The repository pin is ignored. | the factory code: one constant, `claude-sonnet-5-5` (`ConsoleCommands.cs:15`), for all phases |
| can the agent change it | not tested. The agent can read the account's OAuth token ([`../model-credential/finding.md`](../model-credential/finding.md)), so a call of its own would not depend on the picker. | not for the factory's calls (`--model` at `ClaudeCodeAgent.cs:40`). Yes for its own calls, with the gateway key in its environment. |
| where the model list is enforced | nowhere observed. The picker offered twelve models and allowed the switch. | nowhere. The gateway's auth sets no model list on the `dsf` key, so all seven models answer. |
| who picks the tools | the account: connectors loaded at session start, including Google Drive and GitHub write tools that the environment did not configure | the factory: no tools list, no MCP config, `--dangerously-skip-permissions`, so all built-in tools and no MCP server |
| can the agent add an MCP server | it can write the config, but the running session does not load it | yes, with `claude mcp add`. It would load in the next phase of the same run. Not run. |
| what stops a new server's egress | the egress relay, 403 on CONNECT to `mcp.deepwiki.com` | Squid, 403 to any host not on the shared or `sandbox01` list. A stdio server from an allowed registry is not stopped. |
| a content safeguard observed | yes. A model-side safeguard refused a credential sweep and switched the session to Sonnet 5. It acts on the prompt. | none observed |

## Managed Agents

Probed 2026-10-27 in session `sesn_01ShSm9niXACrBsUXsV7xeD9` ([`capture-ma.md`](capture-ma.md)). Docs: https://platform.claude.com/docs/en/managed-agents/sessions#agent-with-overrides. The `judge` agent is pinned to `claude-sonnet-5-5`. A create body of `agent_with_overrides` with `model.id: claude-opus-5-5` returned 200, and the session's `agent.model.id` read back as `claude-opus-5-5`, so the pin on the agent is a default, not a control. The model itself reports no version. The override lives in the create body, and so do `tools` and `mcp_servers`, which `POST /v1/sessions/{id}` can replace on a live session. Nothing inside the sandbox can reach that endpoint: the environment holds no API key, the tool set is fixed by the caller, and no name in the environment matches `mcp` or `model`. So the control on model and tools is the holder of the API key, which on this arm is the workflow job, and a pin that holds against the job is not documented. The session cost 3 cents in 7 active seconds.

## Report cells

Cloud: the operator picks any of twelve models with no control and the account's connectors set the tools, so the only controls observed were the egress relay, the start-time tool loading and a model-side safeguard that acts on prompt content.

Platform: the factory fixes the model and the tools in code and Squid stops a new remote server, but the agent holds a gateway key with no model list and runs with every tool allowed, so it can call any gateway model on its own.

Managed Agents: the agent's model pin is a default that any `agent_with_overrides` create body replaces, so the control on model and tools is whoever holds the API key, and the sandbox holds none.
