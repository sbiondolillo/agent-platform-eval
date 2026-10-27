# Setup cost

The question: how many operator steps and how many secrets does each arm need, from nothing to a working delivery, and to the probes that needed extra setup? The count comes from the captures only. It adds no step that a capture does not show.

Sources: [`../cloud-environment/finding.md`](../cloud-environment/finding.md), [`../cloud-delivery/finding.md`](../cloud-delivery/finding.md), [`../platform-delivery/finding.md`](../platform-delivery/finding.md), [`../platform-smoke/finding.md`](../platform-smoke/finding.md), [`../vault-secret/`](../vault-secret/), [`../github-start/`](../github-start/), [`../spend-attribution/`](../spend-attribution/), and the teardown item in [`../../docs/plan.md`](../../docs/plan.md). The platform prerequisites also cite the model-credential, forge-credential, substrate, toolchain, audit-record and tool-model-policy captures.

## Counting rules

- A step is one action by the operator in one place. A repeated action counts once per repetition that a capture shows.
- A step that a capture leaves implicit is counted and marked "(implied)". Examples: an apply after a config commit, a push of a branch.
- A secret is a distinct value the operator created or placed. A value placed in two stores is one secret with two placements.
- The target repo, its two issues, its `.claude/settings.json` pin and the starter code are the same for both arms. They are not counted.
- Steps by Claude, such as writing a workflow file, are not operator steps. The operator's merge of that file is.
- Opening a session, reading a log and querying Grafana to read a result are not setup, except where the session is the delivery itself.

## Cloud Sessions arm

### To a working delivery

| # | Step | Where | Steps | Secret |
|---|---|---|---|---|
| C1 | Create the environment `agent-platform-eval`: Limited network, package managers allowed, five allowed domains, the setup script ([`cloud-environment`](../cloud-environment/finding.md)) | web UI, claude.ai/code | 1 | none |
| C2 | Start a session to check `dotnet --version`, then build and test (the same finding) | web UI | 1 | none |
| C3 | Start the delivery session from the picker, with Sonnet 5.5, and paste the prompt ([`cloud-delivery`](../cloud-delivery/finding.md)) | web UI | 1 | none |
| C4 | Grant the Claude GitHub App access to the repository, after the push failed with 403 | GitHub web UI | 1 | none (an authorization, not a secret) |
| C5 | Send the follow-up prompt that pushes and opens PR 5 | web UI | 1 | none |
| C6 | Add `geocoding-api.open-meteo.com` to the environment's allowed domains, for the integration suite | web UI | 1 | none |
| C7 | Start a new session on the branch to rerun the integration suite | web UI | 1 | none |
| C8 | Start the review session with the review prompt | web UI | 1 | none |

Subtotal: 8 steps, 0 secrets. PR 5 opened after C5, so C6 to C8 are the cost of the integration gate and the separate review pass, not of the pull request.

### To the probes that needed extra setup

| # | Probe | Step | Where | Steps | Secret |
|---|---|---|---|---|---|
| C9 | vault-secret | Generate the throwaway value with `openssl rand` ([`capture`](../vault-secret/capture.md)) | workstation | 1 | the probe value, created |
| C10 | vault-secret | Open a webhook.site inbox (implied) | web UI, webhook.site | 1 | none |
| C11 | vault-secret | Add the network secret in the environment dialog: Bearer, allowed website, header | web UI | 1 | the probe value, placed (1 placement) |
| C12 | github-start | Create the scheduled task `factory-start` with its API trigger ([`capture`](../github-start/capture.md)) | web UI, claude.ai/code/routines | 1 | fire token, created |
| C13 | github-start | Set `CLAUDE_FIRE_URL` as a repository secret (implied: `gh secret set`) | workstation | 1 | `CLAUDE_FIRE_URL`, placed |
| C14 | github-start | Set `CLAUDE_FIRE_TOKEN`, first with a wrong value | workstation | 1 | `CLAUDE_FIRE_TOKEN`, placed |
| C15 | github-start | Merge PR 8, the workflow file | GitHub | 1 | none |
| C16 | github-start | Create the label `cloud-start` and add it to issue #2 | GitHub | 1 | none |
| C17 | github-start | Set `CLAUDE_FIRE_TOKEN` again with the right value | workstation | 1 | same secret, re-placed |
| C18 | github-start | Apply the label again | GitHub | 1 | none |
| C19 | spend-attribution | Create the Grafana Cloud stack and its OTLP token (implied) ([`finding`](../spend-attribution/finding.md)) | web UI, Grafana Cloud | 1 | Grafana token, created |
| C20 | spend-attribution | Add the seven OTEL variables to the environment | web UI | 1 | none |
| C21 | spend-attribution | Add the network secret for the Grafana host, header `Authorization`, prefix `Basic` | web UI | 1 | Grafana token, placed (implied: the same token) |
| C22 | spend-attribution | Add `PROBE_MARKER` and `OTEL_PROBE_MARKER` before session 2 | web UI | 1 | none |
| C23 | spend-attribution | Add `OTEL_EXPORTER_OTLP_HEADERS` before session 3, the wizard's value | web UI | 1 | Grafana token, placed again |
| C24 | spend-attribution | Add the cumulative temporality variable before session 4 | web UI | 1 | none |
| C25 | spend-attribution | Export the same variables in a workstation shell and run the relay, to bisect the fault ([`capture-workstation`](../spend-attribution/capture-workstation.md)) | workstation | 1 | none (reuses the Grafana token) |

Subtotal: 17 steps. Distinct secrets: 4 (the probe value, the fire token, `CLAUDE_FIRE_URL`, the Grafana token). Of these, `CLAUDE_FIRE_URL` is a URL stored as a secret, so 3 are credentials. Placements: 5 (C11, C13, C14 with its re-set C17, C21 and C23).

### Cloud totals

| Measure | Value |
|---|---|
| Operator steps | 25 (8 to the delivery, 17 for the probes) |
| Distinct secrets | 4 (3 credentials and one URL) |
| Places touched | 5: claude.ai, GitHub, webhook.site, Grafana Cloud, the workstation |
| Lab hosts touched | 0 |

## Platform arm

### What the lab already had in place

None of these rows is an operator step of this experiment. The lab built each before the experiment, and the captures show them. They are the price of the platform arm that the Cloud arm does not pay.

| # | Item | Where it lives | Secret | Cited in |
|---|---|---|---|---|
| L1 | The VM `sandbox-01` on the Sandbox VLAN, from an OpenTofu apply | hypervisor (implied), `homelab-compute` commit `429c6a7` | none | plan, Platform arm |
| L2 | The runner host role: Docker, the host SDK, the Docker client proxy config, the runner registered to the target repo | `sandbox-01`, `homelab-ansible` `roles/dsf_runner_host`, commits `f54cbb2` and `3ee4df0` | the runner registration token (implied) | [`toolchain/capture-platform.md`](../toolchain/capture-platform.md), [`substrate/capture-platform.md`](../substrate/capture-platform.md) |
| L3 | Four Squid allowlist lines for `sandbox-01` that the experiment did not add: `.github.com`, `.githubusercontent.com`, `.blob.core.windows.net`, `artifacts-cli.infisical.com` | `egress-01`, `roles/squid_proxy/defaults/main.yml` at `a17bb31`, lines 77 to 97 | none | [`tool-model-policy/capture-platform.md`](../tool-model-policy/capture-platform.md) |
| L4 | The Infisical project `dsf`, `prod` environment, holding two secrets | Infisical web UI | holds L6 and L7 | [`model-credential/capture-platform.md`](../model-credential/capture-platform.md) |
| L5 | The machine identity `dsf-sandbox01`, Universal Auth, with its client file `/etc/homelab/dsf/.infisical-auth.env`, mode 0640 | Infisical and `sandbox-01` | the client secret | [`forge-credential/capture-platform.md`](../forge-credential/capture-platform.md) |
| L6 | The fine-grained PAT `FACTORY_GITHUB_TOKEN` | GitHub settings, stored in L4 | the PAT | [`forge-credential/finding.md`](../forge-credential/finding.md) |
| L7 | The gateway key for consumer `dsf`, a static entry in the gateway's auth map, stored as `ANTHROPIC_API_KEY` in L4 | the gateway host, `homelab-services` at `bff7a03` | the gateway key | [`model-credential/capture-platform.md`](../model-credential/capture-platform.md) |
| L8 | The firewall permit from `sandbox-01` to the gateway port 8200 | the firewall | none | [`model-credential/finding.md`](../model-credential/finding.md), [`audit-record/capture-platform.md`](../audit-record/capture-platform.md) |
| L9 | The workflow `.github/workflows/factory.yml` and the repository variable `INFISICAL_PROJECT_ID` | the target repo, GitHub | none (the variable is not a secret) | [`model-credential/capture-platform.md`](../model-credential/capture-platform.md) |

Prerequisite totals: 9 items, 4 secrets (3 shown, the runner token implied), 6 lab hosts or services: hypervisor (implied), `sandbox-01`, `egress-01`, Infisical, the gateway host and the firewall, plus GitHub.

### To a working delivery

| # | Step | Where | Steps | Secret |
|---|---|---|---|---|
| P1 | Land the factory change that passes `ANTHROPIC_BASE_URL` into the container, pull request 345 (the capture does not show the merge) | GitHub | 1 | none |
| P2 | Dispatch the smoke run on issue #2, four times, three of which failed (implied: `gh workflow run`) ([`platform-smoke`](../platform-smoke/finding.md)) | workstation | 4 | none |
| P3 | Fix the SDK tree ownership for the runner user and apply the playbook (implied apply) | workstation, `sandbox-01` | 1 | none |
| P4 | Add `aka.ms` to the allowlist and apply (implied apply) | workstation, `egress-01` | 1 | none |
| P5 | Fix the CIDR in `NO_PROXY` and apply (implied apply) | workstation, `sandbox-01` | 1 | none |
| P6 | Dispatch delivery attempt 1 on issue #1 ([`platform-delivery`](../platform-delivery/finding.md)) | workstation | 1 | none |
| P7 | Add `geocoding-api.open-meteo.com` to the allowlist and apply (implied apply) | workstation, `egress-01` | 1 | none |
| P8 | Dispatch delivery attempt 2, which delivered PR 6 | workstation | 1 | none |

Subtotal: 11 steps, 0 new secrets.

### To the probes that needed extra setup

| # | Probe | Step | Where | Steps | Secret |
|---|---|---|---|---|---|
| P9 | vault-secret | Add `PROBE_SECRET` by hand in the `dsf` project ([`capture-platform`](../vault-secret/capture-platform.md)) | Infisical web UI | 1 | the probe value from C9, placed (1 placement) |
| P10 | vault-secret | Widen the allowlist for `webhook.site`, commit `a17bb31`, and apply | workstation, `egress-01` | 1 | none |
| P11 | vault-secret | Merge PR 7, the probe workflow | GitHub | 1 | none |
| P12 | vault-secret | Dispatch the probe workflow with the inbox URL | workstation | 1 | none |
| P13 | github-start | None. The `factory` label already starts the run through `factory.yml` ([`github-start/finding.md`](../github-start/finding.md)) | none | 0 | none |
| P14 | spend-attribution | Create the throwaway branch `probe/spend-attribution` on the factory repo (implied push) ([`capture-platform`](../spend-attribution/capture-platform.md)) | workstation | 1 | none |
| P15 | spend-attribution | Create the same branch on the target repo (implied push) | workstation | 1 | none |
| P16 | spend-attribution | Add the Grafana host to the allowlist, `homelab-ansible` `1ea1431`, and apply (`changed=2`) | workstation, `egress-01` | 1 | none |
| P17 | spend-attribution | Set the repository secret `OTEL_EXPORTER_OTLP_HEADERS`, first with a value that did not parse | GitHub | 1 | the Grafana token from C19, placed (implied: the same token) |
| P18 | spend-attribution | Set the same secret again with the full `Authorization=Basic` pair | GitHub | 1 | same secret, re-placed |
| P19 | spend-attribution | Place `otlp-relay.py` on `sandbox-01` (implied) | workstation, `sandbox-01` | 1 | none |
| P20 | spend-attribution | Start the relay in an SSH shell, for run 3 and again for run 4 in passthrough mode | `sandbox-01` | 2 | none |
| P21 | spend-attribution | Dispatch the five factory runs on the throwaway branch | workstation | 5 | none |

Subtotal: 17 steps. Distinct new secrets: 0. Both secrets reuse values that the Cloud arm created (C9, C19). Placements: 2 (P9, and P17 with its re-set P18).

### Platform totals

| Measure | Experiment steps only | With the lab prerequisites |
|---|---|---|
| Operator steps | 28 (11 to the delivery, 17 for the probes) | 28 plus 9 prerequisite items |
| Distinct secrets | 0 new (2 placements of reused values) | 4 (the PAT, the gateway key, the Infisical client secret, the runner token implied) |
| Places touched | 5: the workstation, GitHub, `egress-01`, `sandbox-01`, Infisical | 7 lab hosts or services, plus GitHub and the workstation |
| Lab hosts touched | 3: `egress-01`, `sandbox-01`, Infisical | 6 |

## Reading

The two counts are close: 25 steps for Cloud and 28 for the platform. The arms differ in what the steps are.

- Cloud setup is web forms and one GitHub grant. Its delivery needed 8 steps and no secret. The GitHub App grant (C4) is the only step the captures show that blocked a first push.
- The platform delivery looks cheap in steps (11) only because the lab already held 9 items and 4 secrets. A reader who starts from nothing pays those first. The captures do not count their steps, so their cost is a floor.
- Both arms hit one egress gap for the same host, `geocoding-api.open-meteo.com`. Cloud fixed it in a web form (C6). The platform fixed it with a commit and an apply on `egress-01` (P7).
- Probes cost more secrets on Cloud (4) than on the platform (0 new), but only because the Cloud arm ran first and created the shared probe value and Grafana token. The platform arm reused them. The count shows each arm's placements, which are 5 and 2.
- The platform probes are mostly dispatches (P2, P21). Three of its fixes (P3 to P5) came from smoke-run failures, so first-run faults add steps that a Cloud form does not.
- One step differs from the vault-secret finding's own count. That finding counts 2 Cloud steps and 4 platform steps for the probe only. This count adds the value generation and the inbox on the Cloud side (C9, C10), which the platform arm reuses.
- This count covers only the listed sources. Other probes, such as egress, changed environment or allowlist settings and are not counted. So both totals are lower bounds.

## Managed Agents

Counted 2026-10-27 from the captures and the plan. Operator steps from zero to the first posted review: create a Console workspace and enable the beta, create its API key, create a read-only fine-grained token, write the two files (one block), set two secrets and two variables (one block), and merge the workflow pull request: 6 steps, 2 new secrets. On top of that, one Console dialog for the OpenTelemetry destination, which the row does not need. Everything else was the session's: the environment, the agent, the probes, the workflow and the delivery dispatch. The lab items the platform arm counted, a VM, a proxy, a vault and a gateway, are absent, because the sandbox, the egress list, the credential helper and the model credential are the product's.

## Report cells

Cloud: Cloud Sessions took 25 operator steps and 4 secrets, all in web forms, GitHub and the workstation, with 8 steps and no secret to reach the first pull request and no lab host touched.

Platform: the platform took 28 operator steps and no new secret in the experiment, on top of 9 lab items and 4 secrets that the lab already held, and it touched 3 lab hosts in the experiment and 6 with its prerequisites.

Managed Agents: 6 operator steps and 2 new secrets from zero to the first posted review, with none of the platform arm's 9 lab items.
