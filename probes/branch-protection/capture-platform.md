# Capture: branch-protection probe, the rule and the platform arm

Probe [branch-protection](../../docs/plan.md). Read from the workstation on 2026-10-24, where the operator's `gh` is signed in as `sbiondolillo` with full rights. Every call is a read. No rule was changed, and nothing was pushed to the sample repo. The factory source is `sbiondolillo/dotnet-software-factory` at tag `v1.2.1`, read from the local clone.

## 1. The rule on `main`

The repository has no ruleset. The protection on `main` is classic branch protection.

`gh api repos/sbiondolillo/platform-eval-sample/rulesets`:

```
[]
```

`gh api repos/sbiondolillo/platform-eval-sample/rules/branches/main`:

```
[]
```

`gh api repos/sbiondolillo/platform-eval-sample/branches/main/protection`, selected fields:

```
{"contexts":["build","integration"],"enforce_admins":false,"restrictions":null,"reviews":null,"strict":false}
```

- Required status checks: `build` and `integration`, with no app pinned to either context, and `strict` off.
- `enforce_admins` is `false`. GitHub's setting "Do not allow bypassing the above settings" is off, so a repository administrator can push past the rule. That is the bypass list of classic protection: no bypass actors are named, and the administrator role bypasses by default.
- No push restrictions, no required reviews. Force pushes and deletions are not allowed. Required signatures, linear history and conversation resolution are off.

The task asked for the `bypass_actors` of each ruleset. With no ruleset, there is no `bypass_actors` field. The equivalent reading is `enforce_admins: false`.

`gh api repos/sbiondolillo/platform-eval-sample --jq .permissions` for the operator account:

```
{"admin":true,"maintain":true,"pull":true,"push":true,"triage":true}
```

## 2. The identity behind the probe commit

`gh api repos/sbiondolillo/platform-eval-sample/commits/c1c0122f3e0526b32302b705a04308b75b843de3 --jq '{author: .author.login, committer: .committer.login, verified: .commit.verification.verified}'`:

```
{"author":"claude","committer":"claude","verified":true}
```

The commit's author and committer email is `noreply@anthropic.com`, and GitHub maps that email to the user account `claude`. The verification reason is `valid`, so the commit carries a signature that GitHub accepts. The commit author is not the pusher.

The pusher comes from the repository activity, `gh api "repos/sbiondolillo/platform-eval-sample/activity?ref=refs/heads/main&per_page=3"`:

```
{"activity_type":"push","actor":"sbiondolillo","after":"c1c0122f3e0526b32302b705a04308b75b843de3","timestamp":"2026-10-24T23:36:06Z"}
```

The push to `main` was made by `sbiondolillo`, the operator's account, which holds admin on the repository. This agrees with the forge-credential probe: the session's proxy injects the operator's account ([`../forge-credential/finding.md`](../forge-credential/finding.md)).

## 3. The platform arm

The factory never pushes to `main`. It pushes a `factory/<id>` branch and opens a pull request, both with `FACTORY_GITHUB_TOKEN`, a fine-grained personal access token on the operator account `sbiondolillo`, read from Infisical ([`../forge-credential/finding.md`](../forge-credential/finding.md), [`../forge-credential/capture-platform.md`](../forge-credential/capture-platform.md) section 2).

- `src/Core/Deliver.cs` line 24 names the branch `"factory/" + runId`. Line 26 pushes it with `git.PushAsync(branch, ...)`. Line 29 opens the pull request against `baseBranch`.
- `src/Core/Git.cs` lines 75 to 86: `PushAsync` runs `git push origin <branch>`, and the branch is the only ref it pushes.
- `src/Core/FeedbackRun.cs` line 45 reads the pull request's head branch, and line 170 pushes that branch. This is the only other push.
- `src/Core/ConsoleCommands.cs` line 180 reads `default_branch` only as the pull request's base.
- A grep of `src/` at `v1.2.1` for `merge` returns nothing. A grep for `main` finds only `IssueScenarios.cs`, where `main` names the feature file text on the base branch. No push to `main` in `src/`, and no merge call in `src/`.

The merge of a factory pull request is a human click, or `gh pr merge --auto`. The required contexts `build` and `integration` apply at that merge, because the merge moves `main`. No merge refusal is recorded in this repo: a grep of `probes/` for "base branch policy" and "prohibits" returns nothing. Pull requests 5 and 6 are open, both by `sbiondolillo`, with `build` and `integration` at `SUCCESS`.

The same `enforce_admins: false` covers the merge. An administrator can merge past a failed or missing check, as the push in section 2 went past the expected checks.

## Unverified

- Whether a direct push to `main` with the factory's PAT is allowed as a bypass. This was not tested. The PAT is on the same account, `sbiondolillo`, which is an administrator, so the same bypass applies unless GitHub limits the bypass for a fine-grained token. The factory's source never makes that push.
