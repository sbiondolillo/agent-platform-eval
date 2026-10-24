# Cloud logging

Probe for [issue #2](../../docs/plan.md). Question: does a Cloud session keep the error text of a failed command, and who can read it.

## Step 1: expand the failed rows in the web UI

Answer: yes. The failed tool row shows its error text, and the shell row shows its full stdout. The `git push` stderr was not checked as a separate row.

Capture: [`capture.md`](capture.md).

## Step 2: Share link in a private window

Pending.

## Step 3: `claude --teleport` on the workstation

Pending.

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
