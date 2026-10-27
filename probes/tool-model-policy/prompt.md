# Tool-model-policy probe prompt

Cloud session "Tool and model policy probe" on sbiondolillo/platform-eval-sample, model Sonnet 5.5 in the picker, environment agent-platform-eval, issue #2. Part 1 is the first message. Part 2 is a picker action by the operator, then a one-line message.

## Part 1

```
Two checks on what this session may use. Do not change any file in the repository, do not commit, do not push, do not create a branch. Run each numbered line as one shell call and paste its full output under a heading that shows the command.

1. claude --version; claude mcp list
2. claude mcp add --transport http deepwiki https://mcp.deepwiki.com/mcp; claude mcp list
3. curl -sS -m 20 -o /dev/null -w 'deepwiki endpoint: %{http_code}\n' https://mcp.deepwiki.com/mcp; echo "exit=$?"
4. python3 -c "import json;d=json.load(open('/root/.claude.json'));print('user mcp:',sorted((d.get('mcpServers') or {}).keys()));print('projects:',[(k,sorted((v.get('mcpServers') or {}).keys())) for k,v in (d.get('projects') or {}).items()])"

Then, without a shell: list the MCP servers and tool names available to you in this session right now, names only. If a deepwiki tool such as read_wiki_structure is in your list, call it for sbiondolillo/platform-eval-sample and paste the result or the error. If it is not in your list, say so.

End with one sentence: which control decided whether the new MCP server was usable: none, the egress policy, or the session's tool loading.
```

## Part 2

The operator opened the model picker, noted the models offered, selected Opus 5.5, and sent:

```
Reply with one word: done.
```

## Managed Agents

Create body: `agent_with_overrides` on `agent_015ajBRYm99G5kMdMDSRsEY1` with `model.id: claude-opus-5-5`, on environment `env_01LppsRP6QAsjQcMATGMfiKj`, budget 100 cents. The message:

```text
Answer in one line: which model are you, as your system reports it? Then run with bash exactly: `ls /workspace; printenv | cut -d= -f1 | grep -c -i -E 'mcp|model'`. Report the output verbatim. End with the line DONE.
```
