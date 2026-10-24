# Capture: tool-model-policy probe, Cloud session

Probe [tool-model-policy](../../docs/plan.md). Session "Tool and model policy probe" on sbiondolillo/platform-eval-sample, model Sonnet 5.5 in the picker, environment agent-platform-eval. Taken 2026-10-24 at about 23:45 UTC. Prompt: [`prompt.md`](prompt.md). Two parts: an MCP server added from inside the sandbox, and a model switch from the picker.

## Part 1: the session's reply, unedited

## 1. `claude --version; claude mcp list`
```
2.1.310 (Claude Code)
No MCP servers configured. Use `claude mcp add` to add a server.
```

## 2. `claude mcp add --transport http deepwiki https://mcp.deepwiki.com/mcp; claude mcp list`
```
Added HTTP MCP server deepwiki with URL: https://mcp.deepwiki.com/mcp to local config
File modified: /root/.claude.json [project: /home/user/platform-eval-sample]
Checking MCP server health…

deepwiki: https://mcp.deepwiki.com/mcp (HTTP) - × Failed to connect — ERR_PROXY_TUNNEL: Proxy refused to open a tunnel: 403 Forbidden
```

## 3. `curl -sS -m 20 -o /dev/null -w 'deepwiki endpoint: %{http_code}\n' https://mcp.deepwiki.com/mcp; echo "exit=$?"`
```
curl: (56) CONNECT tunnel failed, response 403
deepwiki endpoint: 000
exit=56
```
The `exit=56` is curl's exit code. The `$?` was read after `curl`, so it is curl's status and not the `echo`'s.

## 4. `python3 -c "import json;d=json.load(open('/root/.claude.json')); ..."`
```
user mcp: []
projects: [('/home/user/platform-eval-sample', ['deepwiki'])]
```

## MCP servers and tools in this session (names only)

- **Claude_Docs:** `batch`, `guide`, `update`, plus the deferred `create`, `delete`, `export`, `query`, `read`.
- **claude-code-remote:** `add_repo`, `archive_session`, `confirm_repository_trust`, `create_session`, `create_trigger`, `delete_trigger`, `fire_trigger`, `get_event`, `get_session`, `get_trigger`, `interrupt_session`, `list_environments`, `list_events`, `list_repos`, `list_sessions`, `list_triggers`, `read_documentation`, `register_repo_root`, `send_later`, `send_message`, `set_session_tags`, `set_session_title`, `subscribe_pr_activity`, `unarchive_session`, `unsubscribe_pr_activity`, `unwatch_url`, `update_trigger`, `watch_url`.
- **github (deferred):** `actions_get`, `actions_list`, `actions_run_trigger`, `add_comment_to_pending_review`, `add_issue_comment`, `add_reply_to_pull_request_comment`, `assign_copilot_to_issue`, `create_branch`, `create_or_update_file`, `create_pull_request`, `create_pull_request_with_copilot`, `create_repository`, `delete_file`, `disable_pr_auto_merge`, `enable_pr_auto_merge`, `fork_repository`, `get_check_run`, `get_commit`, `get_copilot_job_status`, `get_file_contents`, `get_job_logs`, `get_label`, `get_latest_release`, `get_me`, `get_release_by_tag`, `get_tag`, `get_team_members`, `get_teams`, `issue_read`, `issue_write`, `list_branches`, `list_commits`, `list_issue_fields`, `list_issue_types`, `list_issues`, `list_pull_requests`, `list_releases`, `list_repository_collaborators`, `list_tags`, `merge_pull_request`, `pull_request_read`, `pull_request_review_write`, `push_files`, `request_copilot_review`, `resolve_review_thread`, `run_secret_scanning`, `search_code`, `search_commits`, `search_issues`, `search_pull_requests`, `search_repositories`, `search_users`, `sub_issue_write`, `unresolve_review_thread`, `update_issue_comment`, `update_pull_request`, `update_pull_request_branch`.
- **Google_Drive (deferred):** `copy_file`, `create_file`, `download_file_content`, `get_file_metadata`, `get_file_permissions`, `list_recent_files`, `read_file_content`, `search_files`, `share_file`, `trash_file`, `update_file`.

**deepwiki:** it is not in my list, and `read_wiki_structure` is not available to me. I did not call it, because I have no such tool.

**Side effect:** command 2 wrote a `deepwiki` entry to `/root/.claude.json`, under the project `/home/user/platform-eval-sample`. That file is outside the repo. The repo, branches and commits are untouched. I can remove the entry with `claude mcp remove deepwiki` if you want.

The egress policy decided it: the proxy refused the tunnel to `mcp.deepwiki.com` with a 403, both for `claude mcp list` and for plain `curl`.

## Part 2: the model switch

The picker at the bottom of the composer offered these models, with an Effort setting beside them:

| Group | Models |
|---|---|
| Top level | Opus 5.5, Fable 5.1, Sonnet 5.5, Haiku 5.5 |
| More models | Haiku 4.5, Sonnet 5, Opus 5, Fable 5, Opus 4.8, Opus 4.7, Opus 4.6, Sonnet 4.6 |

The operator selected Opus 5.5. A dialog titled "Switch model?" appeared with this text: "This session is cached for Sonnet 5.5. Switching to Opus 5.5 means Claude re-reads the whole session on your next message, which uses more of your limit." It offered a "Don't ask again" checkbox, Cancel and Switch model. The dialog is a cost notice about the prompt cache, not a policy control. The operator chose Switch model and sent "Reply with one word: done." The reply "done" arrived with the composer label reading "Opus 5.5 Medium". No policy message appeared. The repository's `.claude/settings.json` model entry is ignored by the web session, as the environment probe recorded ([`../cloud-environment/finding.md`](../cloud-environment/finding.md)).
