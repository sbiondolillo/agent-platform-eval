# Capture: platform side, job log and gateway ledger

Probe step 5 of [cloud-logging](../../docs/plan.md). Taken 2026-10-24 at about 22:30 UTC.

The failure: attempt 1 of the Platform arm's delivery on issue #1, GitHub Actions run 40117342098 in `sbiondolillo/platform-eval-sample`. The test gate failed 4 times on a Squid 403 for the Open-Meteo geocoding call. See [`../platform-delivery/finding.md`](../platform-delivery/finding.md).

## Job log

### Run metadata

Command:

```
gh run view 40117342098 --repo sbiondolillo/platform-eval-sample --json conclusion,createdAt,updatedAt,url,status,jobs
```

| field | value |
|---|---|
| url | https://github.com/sbiondolillo/platform-eval-sample/actions/runs/40117342098 |
| status | completed |
| conclusion | failure |
| createdAt | 2026-10-24T17:42:31Z |
| updatedAt | 2026-10-24T17:47:53Z |
| job | `factory`, runner `sandbox-01`, job id 120941237249 |
| failed step | 4, "Run the factory" |
| repo visibility | public |

### Log lines

Commands:

```
gh run view 40117342098 --repo sbiondolillo/platform-eval-sample --log
gh run view 40117342098 --repo sbiondolillo/platform-eval-sample --log-failed
```

Both commands returned the same 308 lines. `gh` labels every line with step `UNKNOWN STEP`, although the jobs API names the step. That is the GitHub-side zero-steps fault of 2026-10-24, recorded in the plan. The excerpt below is from the last of the 4 test gates. ANSI color codes are removed. Each line keeps its `factory` job and `UNKNOWN STEP` prefix, tab-separated as `gh` prints it. Nothing else is changed.

```
factory	UNKNOWN STEP	2026-10-24T17:47:48.7289628Z command: dotnet test --no-restore --logger trx --results-directory /work/.test-gate-c39d79e1c1d6428396bfd9553cc385c0 exited 0
factory	UNKNOWN STEP	2026-10-24T17:47:50.3848040Z command: dotnet run --no-restore --project tests/Integration exited 1
factory	UNKNOWN STEP	2026-10-24T17:47:50.3848432Z test: failed
factory	UNKNOWN STEP	2026-10-24T17:47:50.3860460Z The budget of 3 Redos is spent. The last build still fails:
factory	UNKNOWN STEP	2026-10-24T17:47:50.3860821Z 
factory	UNKNOWN STEP	2026-10-24T17:47:50.3861022Z dotnet run exited with the code 1
factory	UNKNOWN STEP	2026-10-24T17:47:50.3862950Z standard output: xUnit.net v3 In-Process Runner v3.2.2+728c1dce01 (64-bit .NET 10.0.12)
factory	UNKNOWN STEP	2026-10-24T17:47:50.3863778Z   Discovering: Integration
factory	UNKNOWN STEP	2026-10-24T17:47:50.3864212Z   Discovered:  Integration
factory	UNKNOWN STEP	2026-10-24T17:47:50.3864675Z   Starting:    Integration
factory	UNKNOWN STEP	2026-10-24T17:47:50.3865414Z     Integration.GeocodingTests.ANameNoPlaceHasHasNoResults [FAIL]
factory	UNKNOWN STEP	2026-10-24T17:47:50.3866356Z       Core.GeocodingUnavailableException : The geocoding service gave no answer.
factory	UNKNOWN STEP	2026-10-24T17:47:50.3867662Z       ---- System.Net.Http.HttpRequestException : The proxy tunnel request to proxy 'http://10.26.0.10:3128/' failed with status code '403'."
factory	UNKNOWN STEP	2026-10-24T17:47:50.3868587Z       Stack Trace:
factory	UNKNOWN STEP	2026-10-24T17:47:50.3869645Z         src/Core/GeocodingClient.cs(37,0): at Core.GeocodingClient.SearchAsync(String name, CancellationToken cancellationToken)
factory	UNKNOWN STEP	2026-10-24T17:47:50.3870970Z         tests/Integration/GeocodingTests.cs(11,0): at Integration.GeocodingTests.SearchAsync(String name)
factory	UNKNOWN STEP	2026-10-24T17:47:50.3872229Z         tests/Integration/GeocodingTests.cs(26,0): at Integration.GeocodingTests.ANameNoPlaceHasHasNoResults()
factory	UNKNOWN STEP	2026-10-24T17:47:50.3873620Z         --- End of stack trace from previous location ---
factory	UNKNOWN STEP	2026-10-24T17:47:50.3874194Z         ----- Inner Stack Trace -----
factory	UNKNOWN STEP	2026-10-24T17:47:50.3875265Z            at System.Net.Http.HttpConnectionPool.EstablishProxyTunnelAsync(Boolean async, CancellationToken cancellationToken)
factory	UNKNOWN STEP	2026-10-24T17:47:50.3876899Z            at System.Net.Http.HttpConnectionPool.ConnectAsync(HttpRequestMessage request, Boolean async, CancellationToken cancellationToken)
factory	UNKNOWN STEP	2026-10-24T17:47:50.3878630Z            at System.Net.Http.HttpConnectionPool.CreateHttp11ConnectionAsync(HttpRequestMessage request, Boolean async, CancellationToken cancellationToken)
factory	UNKNOWN STEP	2026-10-24T17:47:50.3880094Z            at System.Net.Http.HttpConnectionPool.InjectNewHttp11ConnectionAsync(QueueItem queueItem)
factory	UNKNOWN STEP	2026-10-24T17:47:50.3881574Z            at System.Threading.Tasks.TaskCompletionSourceWithCancellation`1.WaitWithCancellationAsync(CancellationToken cancellationToken)
factory	UNKNOWN STEP	2026-10-24T17:47:50.3924872Z            at System.Net.Http.HttpConnectionPool.SendWithVersionDetectionAndRetryAsync(HttpRequestMessage request, Boolean async, Boolean doRequestAuth, CancellationToken cancellationToken)
factory	UNKNOWN STEP	2026-10-24T17:47:50.3926851Z            at System.Net.Http.RedirectHandler.SendAsync(HttpRequestMessage request, Boolean async, CancellationToken cancellationToken)
factory	UNKNOWN STEP	2026-10-24T17:47:50.3928567Z            at System.Net.Http.SocketsHttpHandler.<SendAsync>g__CreateHandlerAndSendAsync|115_0(HttpRequestMessage request, CancellationToken cancellationToken)
factory	UNKNOWN STEP	2026-10-24T17:47:50.3931320Z            at System.Net.Http.HttpClient.<SendAsync>g__Core|83_0(HttpRequestMessage request, HttpCompletionOption completionOption, CancellationTokenSource cts, Boolean disposeCts, CancellationTokenSource pendingRequestsCts, CancellationToken originalCancellationToken)
factory	UNKNOWN STEP	2026-10-24T17:47:50.3933536Z         src/Core/GeocodingClient.cs(16,0): at Core.GeocodingClient.SearchAsync(String name, CancellationToken cancellationToken)
[57 lines omitted: the same failure and stack trace for VaduzHasOneResult, BostonHasSeveralResults and KathmanduHasOneResult]
factory	UNKNOWN STEP	2026-10-24T17:47:50.4006490Z   Finished:    Integration (ID = 'd569c5a5a321f4f442ad695c8dcdc0aacf49beb5880723a12ccb3c05f7b08e10')
factory	UNKNOWN STEP	2026-10-24T17:47:50.4007155Z === TEST EXECUTION SUMMARY ===
factory	UNKNOWN STEP	2026-10-24T17:47:50.4007609Z    Integration  Total: 4, Errors: 0, Failed: 4, Skipped: 0, Not Run: 0, Time: 0.197s
factory	UNKNOWN STEP	2026-10-24T17:47:50.4007955Z 
factory	UNKNOWN STEP	2026-10-24T17:47:50.4008101Z standard error: 
factory	UNKNOWN STEP	2026-10-24T17:47:51.6592385Z failed to wait for command termination: exit status 1
factory	UNKNOWN STEP	2026-10-24T17:47:51.6618549Z ##[error]Process completed with exit code 1.
```

The log names the proxy (`10.26.0.10:3128`) and the status (`403`). It does not name the denied host. `geocoding-api.open-meteo.com` comes from issue #1 and the Squid allowlist fix, not from this log.

### Who can read it

| reader | result | proof |
|---|---|---|
| signed-out browser | no | The job page answers 200 and shows "Sign in to view logs". |
| anonymous API | no | `GET /repos/sbiondolillo/platform-eval-sample/actions/jobs/120941237249/logs` with no token answers 403. |
| signed-in GitHub account with read access | yes | `gh run view --log` as the repo owner. The REST docs say anyone with read access can download job logs. On a public repo, that is every signed-in account. A second account was not tried. |

### Retention

The repo setting is 90 days, the maximum for a public repo:

```
gh api repos/sbiondolillo/platform-eval-sample/actions/permissions/artifact-and-log-retention
{"days":90,"maximum_allowed_days":90}
```

Docs: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#configuring-the-retention-period-for-checks-workflow-runs-commit-statuses-artifacts-and-logs-in-your-repository. The page says logs are kept 90 days by default, and a public repo can set 1 to 90 days. This log expires on or about 2027-01-22.

## Gateway ledger

Table `telemetry.gateway_calls` on the lab ClickHouse. Read as role `mcp_ro` from `llm-01`, over the ClickHouse HTTP interface. The role accepts connections only from the Management VLAN. The query selects aggregates only. No request body, header or key column is read.

The rows carry an empty `run_id`. Factory v1.2.1 sends no run id, so the match is by consumer and time window: consumer `dsf`, 17:42:00 to 17:50:00 UTC, which holds the job's 17:42:31 to 17:47:53.

Query:

```sql
SELECT run_id, status, count() AS calls, round(sum(response_cost), 6) AS cost_usd,
       sum(total_tokens) AS tokens, min(event_time) AS first_call, max(event_time) AS last_call,
       countIf(error_str != '') AS rows_with_error_str,
       countIf(error_information != '' AND error_information != '{}') AS rows_with_error_info
FROM telemetry.gateway_calls
WHERE consumer = 'dsf'
  AND event_time >= '2026-10-24 17:42:00' AND event_time < '2026-10-24 17:50:00'
GROUP BY run_id, status
ORDER BY first_call
```

Result:

| run_id | status | calls | cost_usd | tokens | first_call | last_call | rows_with_error_str | rows_with_error_info |
|---|---|---|---|---|---|---|---|---|
| (empty) | success | 26 | 0.52894 | 811088 | 2026-10-24 17:42:55.181 | 2026-10-24 17:47:29.885 | 0 | 26 |

All 26 `error_information` values are the same empty structure. A second query grouped on its first 200 characters:

```
{"error_code": "", "error_class": "", "llm_provider": "", "traceback": "", "error_message": "", ...
```

All 26 calls are model `anthropic/claude-sonnet-5-5`.

The last call is at 17:47:29, before the last test gate at 17:47:36 to 17:47:50. The test gate calls no model, and the 403 is an egress denial, not a gateway call. The ledger holds the spend of the failed run. It does not hold the failure.

Retention: the table has `TTL event_time + toIntervalDay(90) TO VOLUME 'cold'` and no delete TTL. Rows move to cold storage after 90 days and stay in the table.
