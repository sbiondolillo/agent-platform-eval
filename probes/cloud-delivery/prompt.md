# Cloud delivery run: prompt

The Cloud arm's single end-to-end delivery on issue #1 of `sbiondolillo/platform-eval-sample`. The ask is the one the factory gets from the issue. The prompt gives no hint about the solution, and it does not repeat the repo's `AGENTS.md`, which the session reads by itself.

Session settings, selected by the operator at claude.ai/code:

| setting | value |
|---|---|
| environment | `agent-platform-eval` |
| repository | `sbiondolillo/platform-eval-sample` |
| branch | `main` |
| model | Sonnet 5.5, selected in the picker. The repo pin does not apply: see [the environment finding](../cloud-environment/finding.md). |
| effort | the default |

The prompt, pasted unedited:

```
Deliver issue #1 of sbiondolillo/platform-eval-sample end to end. Work without asking me questions. If you cannot read the issue, stop and say why.

1. Read issue #1. Its full text is the specification.
2. Implement the change.
3. Run `dotnet build -c Release` and `dotnet test -c Release`. Both must pass.
4. Push a branch and open a pull request against `main`. The pull request body names issue #1 and summarises the change.

Run `date -u` at the start and at the end of each phase: read and plan, implement, build and test, pull request.

When the pull request is open, end with a report that holds:

- the wall time of each phase
- whether you used subagents, and for what
- the final test counts: passed, failed, skipped, total
- the pull request URL
```
