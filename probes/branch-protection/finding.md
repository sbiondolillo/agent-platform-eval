# Branch protection

Probe for [issue #2](../../docs/plan.md). Question: what happens to a push to the protected `main`, and whether the required checks apply. The answer sets what holds the agent back from the default branch in each arm of the DSF v2 decision.

## Cloud Sessions

The session pushed an empty commit straight to `main`, and the push landed: `3d571b5..c1c0122`, exit 0 ([`capture.md`](capture.md)). The remote saw the violation and reported "Bypassed rule violations for refs/heads/main: 2 of 2 required status checks are expected", so the protection let the push through as a bypass, and `main` moved. The protection is classic branch protection with required checks `build` and `integration` and `enforce_admins` off, and the repository has no ruleset ([`capture-platform.md`](capture-platform.md)). The session's token got a 403 on the branch protection API, so the agent could not read the rule it bypassed. The push was made by the operator's account `sbiondolillo`, which the session's proxy injects with admin on the repository ([`../forge-credential/finding.md`](../forge-credential/finding.md)). So the protection does not bind a session, unless the protection stops administrators from bypassing it or the session pushes as an account that is not an administrator.

## Platform

The factory never pushes to `main`. At `v1.2.1` it pushes only a `factory/<id>` branch and the head branch of its own pull request, and it has no merge call (DSF `src/Core/Deliver.cs` lines 24 to 29, `src/Core/Git.cs` lines 75 to 86, `src/Core/FeedbackRun.cs` lines 45 and 170). The pull request is opened with a fine-grained PAT on the same operator account, and the merge is a human click or `gh pr merge --auto`, where the required checks `build` and `integration` apply. With `enforce_admins` off, an administrator can still merge past a failed check. A direct push to `main` with the PAT was not tested, and the PAT is on the same administrator account, so the same bypass applies unless GitHub limits it for a fine-grained token.

## Comparison

| Row | Cloud Sessions | Platform |
|---|---|---|
| identity that pushes | the operator's account `sbiondolillo`, admin, injected by the session's proxy. The commit author is `claude` (`noreply@anthropic.com`). | the operator's account `sbiondolillo`, through a fine-grained PAT from Infisical, in the factory process on the host |
| direct push to `main` | allowed as a bypass. `main` moved to `c1c0122` with both checks missing. | never made: the source pushes only `factory/<id>` and its own pull request branch. The bypass is untested and likely, since the account is an administrator. |
| required checks at merge | apply to a merge, but a direct push skips the merge, and the session made one | apply at the merge of the factory's pull request. An administrator can still merge past them. |
| can the agent read the rule | no: the branch protection API returns 403 for the session's token | no: the agent's container holds no forge credential. The factory process could read it with the PAT, but does not. |
| what binds the agent | nothing on the forge. Only the prompt keeps the agent off `main`. | the factory's source, which pushes a branch and opens a pull request. The forge rule binds the merge, except for an administrator. |

Action, a build item under either outcome: turn on "Do not allow bypassing the above settings" on the `main` protection, or move it to a ruleset with no bypass actors, or push from an identity that is not an administrator.

## Report cells

Cloud: the session pushed to protected `main` and the push landed as an administrator bypass, because the proxy pushes as the operator's admin account and the protection lets administrators bypass, so the protection does not bind the agent.

Platform: the factory's source pushes only its own branch and opens a pull request, so the required checks apply at the merge, but the PAT is on the same admin account and the protection would not stop a direct push.
