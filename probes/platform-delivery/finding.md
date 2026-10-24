# Platform delivery run

The Platform arm's delivery on issue #1 of `sbiondolillo/platform-eval-sample`.

## Session

Date 2026-10-24. Factory v1.2.1 on the self-hosted runner sandbox-01. Model claude-sonnet-5-5 through the lab gateway. Started by `gh workflow run factory.yml -f issue=1`. Two attempts: attempt 1 failed at the test gate on egress. Attempt 2 delivered.

## Score

| value | result |
|---|---|
| gates | attempt 1 failed at the test gate, because the egress allowlist did not include `geocoding-api.open-meteo.com`. Attempt 2 passed plan, build, test, review and deliver. PR 6 checks `build` and `integration` passed. |
| delivery | https://github.com/sbiondolillo/platform-eval-sample/pull/6, from attempt 2 |
| review verdict | review 1 blocked. Review 2 approved after one redo. |
| wall time | attempt 2: 6 min 45 s, dispatch to finish |
| spend | attempt 2: $0.6514 on the gateway ledger, 28 calls, equal to the agent spend lines |

## Attempt 1 (2026-10-24)

Dispatch: `gh workflow run factory.yml -f issue=1` at 17:42:31Z. Run: https://github.com/sbiondolillo/platform-eval-sample/actions/runs/40117342098. Factory at v1.2.1. Runner: sandbox-01. Model: claude-sonnet-5-5 through the gateway.

### Score

| value | result |
|---|---|
| gates | failed at the test gate. No review gate. No PR. |
| review verdict | not run |
| wall time | 5 min 22 s to the failure |
| spend | agent spend lines $0.4758. Gateway ledger $0.5289. Not reconciled. |

GitHub rendered zero steps for the job.

### Phases

| phase | wall time | turns | spend | result |
|---|---|---|---|---|
| plan | 29 s | 4 | $0.1041 | passed |
| build 1 | 138 s | 13 | $0.2653 | done |
| test 1 | not recorded | n/a | n/a | failed |
| build 2 | 15 s | 3 | $0.0531 | done |
| test 2 | not recorded | n/a | n/a | failed |
| build 3 | 16 s | 3 | $0.0531 | done |
| test 3 | not recorded | n/a | n/a | failed |
| build 4 | 15 s | 3 | $0.0533 | done |
| test 4 | not recorded | n/a | n/a | failed |
| review | not run | n/a | n/a | not run |

### Cause

All 4 `Integration.GeocodingTests` failed with `HttpRequestException: proxy tunnel request to proxy 'http://10.26.0.10:3128/' failed with status code '403'`. The sandbox egress allowlist did not include `geocoding-api.open-meteo.com`. Issue #1 names that host.

### Gateway ledger

Consumer dsf, 17:42:00 to 17:50:00 UTC: 26 calls, 811088 tokens, $0.5289. First call 17:42:55. Last call 17:47:29. The ledger and the four agent spend lines ($0.4758) are not reconciled. The difference is the test gate's and retry overhead. The cause is unexplained for now.

### Fix for attempt 2

`geocoding-api.open-meteo.com` was added to the sandbox-01 Squid allowlist.

## Attempt 2 (2026-10-24)

Precondition: `geocoding-api.open-meteo.com` is in the sandbox-01 Squid allowlist.

Dispatch: `gh workflow run factory.yml -f issue=1`. Run: https://github.com/sbiondolillo/platform-eval-sample/actions/runs/40118345316. Created 17:55:38Z. Finished 18:02:23Z. Conclusion: success. Wall time 6 min 45 s. Factory v1.2.1. Runner: sandbox-01. Model: claude-sonnet-5-5 through the gateway. The job rendered 7 steps live. The gate lines streamed in the log.

| gate | wall time | turns | spend | result |
|---|---|---|---|---|
| plan | 27 s | 4 | $0.1014 | passed |
| build 1 | 112 s | 9 | $0.2302 | lint and test passed |
| test 1 | 17:58:24 to 17:58:41 | n/a | n/a | passed (integration project exited 0; the log prints no counts) |
| review 1 | 34 s | 6 | $0.1310 | blocked |
| build 2 (redo) | 36 s | 6 | $0.0733 | passed |
| test 2 | 17:59:58 to 18:00:17 | n/a | n/a | passed |
| review 2 | 25 s | 4 | $0.1155 | approved |
| deliver and watch | 18:00:41 to 18:02:20 | n/a | n/a | "checks: green, unresolved threads: 0" |

Agent spend sum: $0.6514. Gateway ledger, consumer dsf, 17:55:38 to 18:03:23 UTC: 28 calls, 973884 tokens, response_cost $0.651404. First call 17:55:59. Last call 18:00:41. The ledger equals the agent spend.

PR: https://github.com/sbiondolillo/platform-eval-sample/pull/6. Branch factory/45752200. Created 18:00:44Z. Title: "A person can add a tracked location by name and list the tracked locations". Checks: build pass (39 s), integration pass (26 s).

Review verdict: approved on review 2. Review 1 blocked.

## Subagents

Attempt 1 and attempt 2: none. The factory runs one agent per gate.

## Side effects

Attempt 2: none beyond the PR branch factory/45752200.
