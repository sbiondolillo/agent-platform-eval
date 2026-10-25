# Forge credential

Probe for [issue #2](../../docs/plan.md). Question: what the sandbox holds for GitHub, and its scope. The answer sets how far a stolen forge credential reaches in each arm of the DSF v2 decision.

## Cloud Sessions

The first prompt ran the probe as a stated credential sweep, and the model-side safeguard refused it and moved the session to a different model ([`capture-refusal.md`](capture-refusal.md)). The second prompt, framed as the access check a developer runs before work, was answered in full ([`capture.md`](capture.md)). The sandbox holds no working GitHub token in its environment: `GH_TOKEN` is a 14-character invalid placeholder, no credential helper is configured, and `GIT_ASKPASS` is set but empty. Git reaches `github.com` through the local agent proxy at `127.0.0.1`, which reports `gitConfigInjection: true` and terminates TLS with its own CA, so the proxy injects the credential into each request rather than leaving it on disk. The injected identity is the operator's own account `sbiondolillo`, with admin permission on the granted repo `platform-eval-sample`, and the dry-run push was accepted, so a real push would be allowed. A second repository of the same owner, `agent-platform-eval`, returned HTTP 403 "GitHub access to this repository is not enabled for this session. Use add_repo", so the credential is scoped to the one granted repo and does not spill to the owner's other repositories.

## Platform

The runner host `sandbox-01` carries two GitHub credentials, and neither enters the agent's container ([`capture-platform.md`](capture-platform.md)). The push and the pull request run in the factory process on the host, not in the sandbox, and use `FACTORY_GITHUB_TOKEN`, a fine-grained personal access token on the operator account `sbiondolillo`, held in the Infisical `dsf` project and injected by `infisical run` into the factory process (`factory.yml` line 45; DSF `src/Core/Deliver.cs`, `Git.cs` lines 234 to 242). Git authenticates over HTTPS as `x-access-token` with the token as the password, through an inline credential helper set per command. The pull request is opened by the token's identity: `gh pr view 6` reports author `sbiondolillo`, not `github-actions[bot]`, which confirms the PAT and not the Actions token does the work. The workflow also carries the Actions `GITHUB_TOKEN` as `FACTORY_CHECKS_TOKEN`, with `permissions: checks: read`; it is scoped to the one repository, reads check runs only, and expires when the job ends or after at most 24 hours on a self-hosted runner ([GITHUB_TOKEN docs](https://docs.github.com/en/actions/concepts/security/github_token)). The container the agent runs in receives only `ANTHROPIC_API_KEY` and `ANTHROPIC_BASE_URL` (DSF `src/Core/Sandbox.cs` lines 59 to 60), so no forge credential is reachable from inside the model's sandbox at all.

## Comparison

| row | Cloud Sessions | Platform |
|---|---|---|
| credential inside the sandbox (shape) | no working token; `GH_TOKEN` is a 14-character invalid placeholder, no credential helper, empty `GIT_ASKPASS`. The working credential is injected per request by the local proxy at `127.0.0.1` (`gitConfigInjection: true`). | none. The container gets `ANTHROPIC_API_KEY` and `ANTHROPIC_BASE_URL` only. The forge token lives in the factory process on the host, never in the agent's sandbox. |
| identity on the forge | the operator's own account `sbiondolillo`, injected by the managed proxy | the operator's own account `sbiondolillo`, via a fine-grained PAT. Pull request 6 is authored by `sbiondolillo`. |
| permission on the target repo | admin on `platform-eval-sample`; dry-run push accepted | push, through the PAT's Contents and Pull requests write; the Actions token adds `checks: read` |
| reach beyond the target repo | none by default. A second repo of the same owner returns 403 "not enabled for this session, use add_repo". | the PAT reaches whatever repositories it is scoped to on the account (selected-repositories scope; exact list unverified). The Actions token reaches only this repository. |
| lifetime | the session's grant, mediated by the proxy; not read by this probe | PAT: a long-lived token rotated by the operator in GitHub settings. Actions token: expires at job end, at most 24 hours on a self-hosted runner. |
| where the secret lives | not on disk in the sandbox; held by the managed proxy and injected per request | the PAT in the Infisical `dsf` project, read by machine identity `dsf-sandbox01` through the host file `/etc/homelab/dsf/.infisical-auth.env`. The Actions token is minted by GitHub per job. |

The attempt 1 refusal is itself a reading for the [tool-model-policy](../../docs/plan.md) row: the model-side safeguard stopped a self-directed credential sweep and switched models, where the identical sweep for an Anthropic key one probe earlier was answered.

## Report cells

Cloud: the sandbox holds no token on disk, but the managed proxy injects the operator's own account credential with admin on the one granted repo, scoped away from the owner's other repos until `add_repo` is called.

Platform: the agent's container holds no forge credential at all; the operator's fine-grained PAT and a job-scoped Actions token both sit in the factory process on the host, and the pull request is opened under the operator account.
