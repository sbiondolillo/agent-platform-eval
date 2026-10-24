# Cloud delivery run

The Cloud arm's delivery on issue #1 of `sbiondolillo/platform-eval-sample`, with the prompt in [`prompt.md`](prompt.md).

## Session

Date 2026-10-24. Environment: agent-platform-eval. Model: Sonnet 5.5, set in the web picker. Effort: default. The delivery took 4 Cloud sessions:

| session title | role | notes |
|---|---|---|
| System environment check | environment probe | see [`probes/cloud-environment/finding.md`](../cloud-environment/finding.md) |
| Platform eval sample issue #1 | delivery | started from the web picker on `main`, prompt from `prompt.md`, sent about 17:45 UTC. Session URL not recorded. |
| Integration test run and timing | integration reruns | after the egress change, see below |
| Build review for issue #1 | review | https://claude.ai/code/session_011T1eDpmxxffi9YkfUqbMeN, see below |

## Score

| value | result |
|---|---|
| gates | build suite 14 passed, 0 failed. `dotnet build` 0 warnings. Integration suite in the Cloud sandbox: flaky after the egress change, then 4 of 4 passed. PR 5 CI on GitHub-hosted runners: `build` and `integration` passed. |
| delivery | https://github.com/sbiondolillo/platform-eval-sample/pull/5, after the operator granted the Claude GitHub App access to the repository |
| review verdict | `APPROVED`, with "one minor non-blocking edge case noted" |
| wall time | build: first prompt about 17:45 to PR 5 at 17:52 UTC, about 7 min including the access block. Agent work about 3.5 min. Review about 2 min. |
| spend | not recorded. The Cloud UI shows no spend per session. The Cloud arm has no per-session cost readout equal to the platform arm's gateway ledger. |
| context percentage | review session 9%. Not recorded for the other sessions. |

## Phases

| phase | wall time | result |
|---|---|---|
| build (delivery session) | 17:45:38 to 17:48:44 | 14 passed, 0 failed. Push failed with 403. |
| access block | 17:48:44 to about 17:51:52 | the operator granted the GitHub App access to the repository |
| pull request | 17:51:52 to before 17:52:03 | PR 5 opened |
| integration reruns | 18:01:12 to after run 4 | 3 of 4 passed three times, then 4 of 4 |
| review | about 2 min, ended 18:08:52 | `APPROVED` |

## Attempt 1 (2026-10-24)

### Build phases

Wall times are as the session reported them. The session ran `date -u` only at some boundaries.

| phase | wall time | result |
|---|---|---|
| read and plan | 17:45:38 to about 17:46 | done |
| implement | to about 17:47:38 | done |
| build and test | to about 17:48:38 | 14 passed, 0 failed |
| pull request | 6 s, failed at 17:48:44 | failed, then pushed after the follow-up |

## Pull request failure

The push failed with 403: "Claude doesn't have GitHub access to sbiondolillo/platform-eval-sample". The MCP `create_branch` also returned 403 "Resource not accessible by integration". The Claude GitHub App had not been granted the repository. The operator added the repository under the app's Repository access at 17:5x UTC. A follow-up prompt pushed at 17:51:52 to 17:51:54 and opened https://github.com/sbiondolillo/platform-eval-sample/pull/5 before 17:52:03.

## Integration suite

In the Cloud sandbox, `dotnet run --no-restore -c Release --project tests/Integration` gives total 4, passed 0, failed 4 (GeocodingTests). The session did not confirm the cause. The environment's Limited allowlist does not include `geocoding-api.open-meteo.com`.

The first prompt asked only for `dotnet test`. That command leaves the integration project out (IsTestProject false). The first report's pass count did not cover the integration suite. The follow-up prompt corrected it.

## Integration suite after the egress change

The operator added `geocoding-api.open-meteo.com` to the environment's Allowed domains at about 17:58 UTC on 2026-10-24. A new session on branch claude/compassionate-bell-0868na, Sonnet 5.5, ran the suite.

- Run 0: `--no-restore` failed with NETSDK1004 because the fresh container had no restore. This was a prompt fault. The session corrected it with `dotnet restore`.
- Run 1 (18:01:12 to 18:01:54): total 4, passed 3, failed 1 (SeveralPlacesHaveTheNameBoston, expected SeveralMatches, got NoAnswer), 33.3 s.
- Run 2: total 4, passed 3, failed 1 (Boston, NoAnswer).
- Run 3: total 4, passed 3, failed 1 (OnePlaceHasTheNameKathmandu, expected Found, got NoAnswer).
- Each of runs 2 and 3 took 33 to 36 s.
- `curl` to the geocoding search URL once returned `000 30.737103`, exit 35 (TLS handshake failure after 30 s). Three later curls returned 200 in 0.76 s, 0.89 s and 1.16 s.
- The proxy status page inside the session showed `enabled: true` and `selective: false`. It has no per-host allowlist view and no per-host counters. `recentRelayFailures` had 19 entries. All were `connect_rejected` for dc.services.visualstudio.com:443 (CONNECT 403, .NET telemetry). None were for open-meteo.
- Run 4: total 4, passed 4, failed 0, skipped 0, 4.008 s.

Reading: the Cloud egress path to an allowed host dropped or stalled requests intermittently over about 15 minutes. The client reports a stall as NoAnswer. The platform arm's proxy passed the same suite twice in attempt 2 (see probes/platform-delivery/finding.md). CI on GitHub-hosted runners passed the suite on PR 5.

## Review

Session: https://claude.ai/code/session_011T1eDpmxxffi9YkfUqbMeN, titled "Build review for issue #1". It was a fresh session on branch claude/compassionate-bell-0868na, Sonnet 5.5, with the prompt from [`review-prompt.md`](review-prompt.md).

- The session ran 5 commands. 1 command failed. The failed command was most likely `gh issue view`. The prompt tells the session to fall back when that command fails.
- The first line of the verdict was `APPROVED`. The prose approved the change with "one minor non-blocking edge case noted".
- The final `date -u` was 18:08:52 UTC on 2026-10-24. The UI did not show the start time, so it was not captured. The review took about 2 min.
- Context: 9%.
- Spend: not recorded. The UI does not show it.

## Subagents

None.

## Side effects

Pending: branches and other changes the session made on the target repo.
