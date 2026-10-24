# Capture: run-history probe, Cloud Sessions side

Probe [run-history](../../docs/plan.md). Read from the workstation, where the operator's `claude` CLI is signed in, and from the public docs. Taken 2026-10-24 at about 23:20 UTC. Commands: [`prompt.md`](prompt.md). No interactive session was started.

## 1. The workstation CLI

### `claude --version`

```
2.1.310 (Claude Code)
```

### `claude --help`, the lines about cloud or remote sessions

The full help has about 70 options and 20 commands. These are the lines that name a cloud session, a remote session or a session list. Each is quoted as printed, with line wraps joined.

```
--bg, --background                    Start the session in the background and return immediately. Prints the id that `claude attach`, `logs`, `stop` and `rm` take; `claude agents` lists them. ...
--cloud [description|session_id|url]  Create a cloud session with the given description, or attach to an existing one by session ID or claude.ai/code URL
--environment <environment_id>        Create a new cloud session that runs on the given self-hosted environment (ccpool_...).
--from-pr [value]                     Resume a session linked to a PR by PR number/URL, or open interactive picker with optional search term
--remote-control [name]               Start an interactive session with Remote Control enabled (optionally named)
-r, --resume [value]                  Resume a conversation by session ID or name, or open interactive picker with optional search term
--teleport [session]                  Resume a teleport session, optionally specify session ID

Commands:
  agents [options]                      Manage background agents
  attach <id|name>                      Open a background session in this terminal. ...
  logs <id|name>                        Print a background session's recent terminal output
  purge [options] [path]                Delete all Claude Code state for a project (transcripts, tasks, file history, config entry)
  rm <id>                               Delete a background session, and its worktree when that is safe. ...
  stop|kill <id>                        Stop a background session. ...
```

No command lists cloud sessions. No command or option exports or downloads a transcript. `--teleport` with no session ID opens an interactive picker, so the probe did not run it.

### Subcommand help

| command | result |
|---|---|
| `claude agents --help` | "Manage background agents". `--json`: "Print active sessions (interactive and background) as a JSON array and exit". `--all`: "With --json: also include completed background sessions". The help names no cloud session. |
| `claude logs --help` | "Print the background session's recent terminal output." |
| `claude attach --help` | "Open the background session in this terminal." |
| `claude remote --help` | Prints the help of `claude remote-control`: "Remote Control - Control local sessions from claude.ai/code or the Claude mobile app". The description says: "Remote Control allows you to control sessions on your local device from claude.ai/code". It lists no cloud sessions. |
| `claude sessions --help` | No such command. The CLI prints the top-level help. |
| `claude teleport --help` | No such command. The CLI prints the top-level help. Teleport is the option `--teleport`. |
| `claude purge --help` | "Delete all Claude Code state for a project (transcripts, tasks, file history, config entry)". This acts on local state only. |

### `claude agents --json --all`, counted

The output was counted and its keys listed. It was not dumped.

```
type: list, 1 entry
keys: cwd, kind, name, pid, sessionId, startedAt, status
kind: interactive (1)
status: busy (1)
```

The one entry is a local interactive session on this workstation. The list holds no cloud session. The operator's account holds the cloud sessions of this eval, the delivery session and the probe sessions, and none of them appears.

## 2. Public docs

`https://docs.claude.com/en/docs/claude-code/<page>` redirects to `https://code.claude.com/docs/en/<page>`. The text below was read from the Markdown form of each page, `https://code.claude.com/docs/en/<page>.md`.

### https://docs.claude.com/en/docs/claude-code/cloud-sessions

The redirect goes to https://code.claude.com/docs/en/cloud-sessions, which answers 404. The docs index, https://code.claude.com/docs/llms.txt, lists the cloud sessions page as "Use Claude Code in the cloud" at https://code.claude.com/docs/en/claude-code-on-the-web.

### https://code.claude.com/docs/en/claude-code-on-the-web

How to list sessions:

> Sessions appear in the sidebar at claude.ai/code. From there you can review changes, share with teammates, archive finished work, or delete sessions permanently.

> You can archive sessions to keep your session list organized. Archived sessions are hidden from the default session list but can be viewed by filtering for archived sessions.

How to read a session from the terminal:

> **Using `--teleport`**: from the command line, run `claude --teleport` for an interactive session picker, or `claude --teleport <session-id>` to resume a specific session directly.

> When you teleport a session, Claude verifies you're in the correct repository, fetches and checks out the branch from the cloud session, and loads the full conversation history into your terminal. The terminal gets its own copy of the session: new work there stays local and doesn't appear in the cloud session on claude.ai or the Claude mobile app.

> `--teleport` is distinct from `--resume`. `--resume` reopens a conversation from this machine's local history and doesn't list cloud sessions; `--teleport` pulls a cloud session and its branch.

Teleport requirements, from the same page: "You must run `--teleport` from a checkout of the same repository, not a fork", and "You must be authenticated to the same claude.ai account used in the cloud session".

How to share:

> To share a session, toggle its visibility according to the account types below. After that, share the session link as-is. Recipients see the latest state when they open the link, but their view doesn't update in real time.

How to delete:

> Deleting a session permanently removes the session and its data. This action can't be undone.

How to write to a session from the CLI. This queues a message. It does not read the transcript:

> Pass `--output-format json` for a machine-readable result: `{ok, session_id, url}` on success, or `{ok: false, session_id, error}` when the send fails, for example when the session is missing or archived.

Export: no sentence on export on this page. Retention: the page links to Data usage for "what Anthropic retains from cloud sessions".

### https://code.claude.com/docs/en/sessions

> Run `/export` to open a menu that lets you copy the current conversation to your clipboard or save it as a plain-text file, with messages and tool outputs rendered as readable text. Pass a filename to skip the menu and write directly to that file.

> By default, Claude Code stores transcripts as JSONL at `~/.claude/projects/<project>/<session-id>.jsonl`, where `<project>` is your working directory path with non-alphanumeric characters replaced by `-`.

`/export` acts on "the current conversation" inside a running session. The page does not name cloud sessions, and it does not say whether `/export` works in a teleported session. The probe did not test it, because the test needs an interactive session. The local transcript path is for local sessions. The cloud-logging probe found that a teleport writes no file there.

### https://code.claude.com/docs/en/data-usage

Retention:

> Anthropic retains Claude Code data based on your account type and preferences.

> **Consumer users (Free, Pro, and Max plans)**:
> * Users who allow data use for model improvement: 5-year retention period to support model development and safety improvements
> * Users who don't allow data use for model improvement: 30-day retention period

> **Commercial users (Team, Enterprise, and API)**:
> * Standard: 30-day retention period

> You can delete individual cloud sessions at any time. Deleting a session permanently removes the session's event data.

Cloud sessions:

> **Code and data storage:** Your repository is cloned into the session's isolated VM. Anthropic stores the session transcript so you can return to the session later. Code and session data are subject to the [retention and usage policies](#data-retention) for your account type

Export: no sentence on export on this page.

### https://code.claude.com/docs/en/cli-reference

> `--teleport` | Resume a [cloud session](https://code.claude.com/docs/en/claude-code-on-the-web.md) in your local terminal

> `--cloud` | With a task description, create a new cloud session. With a session ID (`session_...` or `cse_...`) or a claude.ai/code URL, queue a message into that existing session instead, with `-p`.

> `claude agents` | Open agent view to monitor and dispatch parallel background sessions. ... `--json` to print active sessions as a JSON array for scripting (`--json --all` also includes completed background sessions).

Export: no sentence on export on this page. No command lists cloud sessions.

### https://code.claude.com/docs/en/routines

This page holds the one public HTTP endpoint for cloud sessions. It starts a session. It does not list or read one.

> An API trigger gives a scheduled task a dedicated HTTP endpoint. POSTing to the endpoint with the task's bearer token starts a new session and returns a session URL.

> The `/fire` endpoint is available to claude.ai users only and is not part of the Claude Platform API surface.

> To see what a run did, click it in the **History** list on the detail page. The run opens as a full session, a new one for each run, where you can see what Claude did, review changes, and create a pull request.

Export: no sentence on export on this page.

### https://code.claude.com/docs/en/cross-session-messaging

> A cloud session, including one on a self-hosted runner, can't use `SendMessage` to answer a message from another machine, even when the message carries a reply address. The message still arrives. Read the cloud session's response in its transcript at [claude.ai/code](https://claude.ai/code).

Export: no sentence on export on this page.

### https://code.claude.com/docs/en/zero-data-retention

> Cloud sessions, including those started from the Desktop app | Requires server-side storage of session data, including conversation history with prompts and completions.

Export: no sentence on export on this page.

### https://code.claude.com/docs/llms-full.txt, searched

The full docs text was searched for `list_sessions`, `get_session`, `list_events`, `get_event`, `claude-code-remote` and "Sessions API".

- https://code.claude.com/docs/en/self-hosted-environments-configuration names the in-session server: "Anthropic's control plane attaches its own MCP server, named Claude Code Remote, to cloud sessions. Claude uses the server's tools to create cloud scheduled tasks, start and steer other cloud sessions, attach more repositories, and follow pull request activity." The page tells how to deny the server. It does not list the tools as a public API.
- https://code.claude.com/docs/en/errors names a "Sessions API" only in an error text: "This message means Claude Code found the cloud session you asked to pull into your terminal but couldn't read its conversation history from Anthropic's servers". The docs give no reference for that API.
- https://code.claude.com/docs/en/agent-sdk/python documents `list_sessions()` and `get_session_messages()` in the Agent SDK. They read the sessions of a project directory on the machine that runs the SDK. The page does not say that they list cloud sessions.

## 3. The in-session MCP tools

The tool-model-policy probe listed the tools of the `claude-code-remote` server inside a Cloud session ([`../tool-model-policy/capture.md`](../tool-model-policy/capture.md)). The ones that read run history are `list_sessions`, `get_session`, `list_events` and `get_event`. These tools exist inside the product. A script outside a session cannot call them, and the docs describe no public HTTP API with the same functions. The only documented HTTP endpoint for cloud sessions is the scheduled-task `/fire` endpoint, and it starts a session only.

## 4. Teleport, from the cloud-logging probe

Step 3 of [cloud-logging](../cloud-logging/finding.md#step-3-claude---teleport-on-the-workstation) ran `claude --teleport` for the delivery session. The CLI rendered the whole conversation, with the exact error text, in the terminal. No transcript file appeared under `~/.claude/projects/`, during the session or after `/exit`. The CLI reads the record from the server each time and writes no file to disk.
