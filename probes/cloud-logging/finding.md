# Cloud logging

Probe for [issue #2](../../docs/plan.md). Question: does a Cloud session keep the error text of a failed command, and who can read it.

## Step 1: expand the failed rows in the web UI

Answer: yes. The failed tool row shows its error text, and the shell row shows its full stdout. The `git push` stderr was not checked as a separate row.

Capture: [`capture.md`](capture.md).

## Step 2: Share link in a private window

Answer: no for a reader without an account. The Share dialog has two scopes, "Private: Only you have access" and "Public: Anyone with the link can view". With Public set, the link opened in a private window redirected to the Claude sign-in page. The anonymous reader saw no transcript text. "Anyone with the link" thus means any signed-in Claude account. A signed-in account can retrieve the error text through the link, and nobody without an account can. The signed-in case was not tested with a second account.

Capture: [`capture.md`](capture.md#step-2-share-link-in-a-private-window).

## Step 3: `claude --teleport` on the workstation

Answer: yes in the terminal, no on disk. The teleport checked out the session's branch and rendered the whole conversation, with the exact 403 error text of the failed tool row and the full stdout of the shell row. No transcript file appeared under `~/.claude/projects/`, during the session or after `/exit`. The CLI reads the record from the server each time and holds the error text only in the terminal view. The reader is the account owner, with the CLI signed in.

Capture: [`capture.md`](capture.md#step-3-claude---teleport-on-the-workstation).

## Step 4: repeat step 1 after the container is reclaimed

Answer: yes. The container was reclaimed when the capture was taken, and the transcript still rendered from the web UI. The failed tool row and the shell row showed the same text as in step 1.

Capture: [`capture.md`](capture.md). The same file holds both captures.

## Step 5: platform side

Answer: yes for the job log, no for the gateway ledger. The GitHub job log of run 40117342098 holds the 403 line and the full stack trace for all 4 failed tests. The ledger holds the run's 26 model calls and their cost, $0.52894, all with status `success`. It does not hold the failure, because the 403 is an egress denial and the test gate calls no model.

| record | holds the 403 | who can read it | retained |
|---|---|---|---|
| GitHub job log, job `factory`, step "Run the factory" | yes, with stack trace | any signed-in GitHub account with read access to the public repo. A signed-out reader gets "Sign in to view logs". | 90 days, the repo setting and GitHub's default. Expires on or about 2027-01-22. |
| gateway ledger, `telemetry.gateway_calls` | no, spend only | the lab operator, over the `mcp_ro` role from the Management VLAN | as long as the table. A TTL moves rows to cold storage after 90 days. It deletes none. |

Capture: [`capture-platform.md`](capture-platform.md).

## Summary

| step | Record | Error text kept | Who can read it | Retention |
|---|---|---|---|---|
| 1 | Cloud transcript, web UI | yes: the tool error text and the full shell stdout | the account owner, signed in | not recorded by this probe. The transcript outlived the container. |
| 2 | Cloud transcript, Share link | yes, for a signed-in reader. Not tested with a second account. | any signed-in Claude account, with the Public scope set. Nobody without an account. | as for step 1, while the scope stays Public |
| 3 | Cloud transcript, `claude --teleport` | yes, in the terminal view only. No file on disk. | the account owner, with the CLI signed in | as for step 1. Nothing is kept on the workstation. |
| 4 | Cloud transcript, after the container is reclaimed | yes, the same text as step 1 | the account owner, signed in | not recorded by this probe. The record does not depend on the container. |
| 5 | GitHub job log, run 40117342098 | yes, with stack trace | any signed-in GitHub account with read access to the public repo | 90 days, to on or about 2027-01-22 |
| 5 | Gateway ledger, `telemetry.gateway_calls` | no, spend only | the lab operator, over `mcp_ro` from the Management VLAN | as long as the table. No row is deleted. |

Cloud Sessions keep the error text in the server-side transcript, readable by signed-in accounts through the web UI, the Share link and the CLI; nothing is exported to disk.
