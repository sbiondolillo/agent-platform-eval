# Plan

The to-do list comes first. The settled design follows as reference. A step is done when its completion criterion holds. Tick the box and write the proof on the same line.

## Status 2026-10-24

Both arms delivered issue #1 with an approved review. PR 5 (Cloud) and PR 6 (platform) stay open and unmerged as evidence. Both arms hit the same egress block on `geocoding-api.open-meteo.com`, and the operator widened both allowlists. After that, the Cloud egress path stalled intermittently for about 15 minutes. Live job steps on GitHub returned the same day. Next: the probe sessions on issue #2 (one per controls row), the fire endpoint start probe (`github-start`), the `@claude` side experiment, the Grafana Cloud OTel export, then the report table and the Pages site.

## To-do

### Setup

- [x] The eval repo `agent-platform-eval` is public on GitHub, and this file is on `main`. Proof: https://github.com/sbiondolillo/agent-platform-eval, `PUBLIC main` from `gh repo view`, 2026-10-24.
- [x] The target repo is public on GitHub, made from the starter at `dotnet-software-factory` tag `v1.1.0`, with `main` protected. Proof: https://github.com/sbiondolillo/platform-eval-sample, protection contexts `build` and `integration` read back, 2026-10-24.
- [x] Issue #1 of the target repo carries the `forecast-sample` issue #1 text. Issue #2 is the probe issue, the factory's demo issue `--shout`. Proof: issues 1 and 2 on the target repo, 2026-10-24.
- [x] The target repo's committed `.claude/settings.json` pins `claude-sonnet-5-5`. Proof: the first commit of the target repo.
- [x] A cloud environment exists for the target repo. Its setup script installs the .NET SDK that `global.json` pins, and a session runs `dotnet --version` with the pinned value. Proof: [`probes/cloud-environment/finding.md`](../probes/cloud-environment/finding.md).

### Platform arm

- [x] A lab VM sits on the Sandbox VLAN. Proof: `sandbox-01`, 10.25.0.10, VLAN 25. The plan showed one VM added and the stopped template's known computed-attribute noise. `homelab-compute` commit `429c6a7`, 2026-10-24.
- [x] The VM runs a GitHub self-hosted runner registered to the target repo. Proof: the runners API lists `sandbox-01 online self-hosted,Linux,X64,dsf`. `homelab-ansible` commits `f54cbb2` and `3ee4df0`.
- [x] The runner job pulls `FACTORY_GITHUB_TOKEN` and the gateway key from Infisical. Proof: the job's `infisical run` line in the Actions log of run 40115249577, and the target repo holds no Actions secret. The machine identity file is `/etc/homelab/dsf/.infisical-auth.env`, 0640 root:github-runner.
- [x] The container reaches the model through the lab gateway. Proof: `telemetry.gateway_spend` has 12 calls for consumer `dsf`, model `anthropic/claude-sonnet-5-5`, $0.1915, between 17:15:20 and 17:17:06 UTC on 2026-10-24, equal to the job summary's three phase figures summed. The container received `ANTHROPIC_BASE_URL` only after `dotnet-software-factory` pull request 345, because the factory's `docker run` passed only the key. The runner holds a gateway consumer key, not a personal key.
- [x] Egress from the VM is the Sandbox VLAN's deny-by-default rules plus Squid's allowlist. Proof: from the host, a direct probe to 1.1.1.1 is blocked and `api.nuget.org` through Squid answers 200. During the delivered run, Squid logged 23 `TCP_DENIED` for `api.anthropic.com:443` from the container's side calls, with no effect on the run. Captures in `probes/platform-smoke/`.
- [x] The smoke run on issue #2 delivers a pull request. Proof: run 40115249577 on the target repo, every phase passed, pull request 3 opened by the factory at `ref=sandbox-anthropic-base-url`. Three earlier runs failed on the host's SDK ownership, the `aka.ms` redirect and a CIDR in `NO_PROXY`, each fixed in `homelab-ansible` `3ee4df0`.
- [x] GitHub shows the job's steps and their output live while the job runs on `sandbox-01`. Proof: a screenshot of a running job with the "Run the factory" step open and phase lines visible, saved under `probes/platform-live-steps/`. Retest on a later day. Found 2026-10-24: no run created that day rendered steps, on any runner. A three-step echo job on `sandbox-01`, the same job on the proxy-free `llm-01` runner, and the GitHub-hosted `ci` jobs all showed a blank job panel and zero steps from the jobs API, while a run from 2026-10-03 still returned four steps. The runner's own log reported every upload as a success, and Squid denied no GitHub host. GitHub's status page listed no incident. A GitHub-hosted `ci` job in `sbiondolillo/dotnet-software-factory` run 40116466637 also rendered zero steps while it ran, and the jobs API still returned zero steps after the run completed. The fault is not tied to the self-hosted runner or to `platform-eval-sample`. Proof, 2026-10-24 at about 18:05 UTC: GitHub rendered steps live again. The self-hosted factory job in run 40118345316 showed its four steps while running, and the GitHub-hosted `build` job in run 40118075866 showed all ten steps. The earlier zero-step runs were a GitHub-side fault of the same day, not a runner fault.

### Cloud Sessions probes

One probe session per row, on issue #2's branch or on no branch. A probe never touches issue #1's branch. Each probe writes `probes/<row>/prompt.md`, `probes/<row>/capture.*` and `probes/<row>/finding.md`, where the finding names the docs URL and states the cell in one sentence. "Not documented" is a finding.

- [x] **cloud-logging**: first probe to run. Whether a Cloud session keeps the error text of a failed command, and who can read it. Captures go to `probes/cloud-logging/`. Proof: [`probes/cloud-logging/finding.md`](../probes/cloud-logging/finding.md).
   1. Open the Cloud delivery session "Platform eval sample issue #1" and expand the failed command rows. Record whether the full stdout and stderr of `git push` (403) and of the integration run (`NoAnswer`) are shown. Copy the exact text into `probes/cloud-logging/capture.md`.
   2. Open the session's Share link in a private window. Record what a reader without the account sees.
   3. Run `claude --teleport` for that session on the workstation. Record whether a transcript file appears under `~/.claude/projects/` and whether it holds the command output.
   4. After the container is reclaimed (the UI says so, or a day later), repeat step 1 and record any difference.
   5. On the platform side, record that the same failure is in the GitHub job log for run 40117342098 (the 403 line with a stack trace, 90 days retention) and in the gateway ledger.

   Completion criterion: `probes/cloud-logging/finding.md` states, for each of the four Cloud checks (steps 1 to 4), whether the error text is retrievable and by whom, with a capture file for each yes.

- [x] **substrate**: `uname -a`, `/proc/cpuinfo` hypervisor flags, `id`, `capsh --print`, `systemd-detect-virt`. Finding: who runs the code, as what user, with which capabilities. Proof: [`probes/substrate/finding.md`](../probes/substrate/finding.md).
- [ ] **model-credential**: search environment, filesystem and process list for an Anthropic key or a token. Finding: what the VM holds, by shape only. No value is captured.
- [ ] **forge-credential**: the same search for a GitHub credential, then `gh auth status` and the token's scopes. Finding: what the VM holds and its scope.
- [ ] **vault-secret**: a network secret for a throwaway lab hostname. From inside the VM, `env` shows no value, and the endpoint's log shows the header present. Finding: where the key is attached.
- [ ] **egress**: Custom level with one allowed domain. `curl` to the allowed domain, to `open-meteo.com`, to a raw IP and to a port other than 443. Finding: what the proxy returns for each.
- [ ] **tool-model-policy**: `/model` with a model outside the pin, and a tool call to an MCP server the environment does not configure. Finding: the control that stopped each, or none.
- [ ] **run-history**: list sessions and download a transcript from outside the product, by API or CLI. Finding: the export path, or "not documented".
- [ ] **spend-attribution**: OpenTelemetry to Grafana Cloud with the auth header in `OTEL_EXPORTER_OTLP_HEADERS`. If blocked, to the lab collector. Finding: the cost metric for one session, read by `ccr.session.id`.
- [ ] **audit-record**: where the transcript lives, and whether a session command can edit or delete it. Finding: the record a compromised agent cannot erase, or none.
- [ ] **github-start**: a workflow on the `factory` label calls the scheduled-task fire endpoint. Finding: a session starts from the label, or the error the endpoint returns.
- [ ] **crash-resume**: kill a session mid-run from the UI, then resume. Finding: what survived: history, files, background shells, subagents.
- [ ] **subagent-record**: spawn one subagent, then look for its transcript in the UI, under `~/.claude/projects/` in the VM, and after a teleport. Finding: where the subagent's record is, and whether it survives the VM.
- [ ] **toolchain**: the setup script's run time, its cache hit on the next session, and its expiry. Finding: the cost of a non-default toolchain.
- [ ] **branch-protection**: push to the protected `main` from a session. Finding: the result, and whether required checks apply.
- [ ] **setup-cost**: the steps and secrets from zero to the first delivered pull request, counted from the captures.

### Delivery run

- [x] The platform arm delivers a pull request on issue #1. Gates, review verdict, wall time and spend are recorded in `probes/platform-delivery/finding.md`. Proof: [PR 6](https://github.com/sbiondolillo/platform-eval-sample/pull/6) from attempt 2, review approved, 6 min 45 s, $0.6514 on the ledger, in [`probes/platform-delivery/finding.md`](../probes/platform-delivery/finding.md).
- [x] The cloud arm delivers a pull request on issue #1. The same four values are in `probes/cloud-delivery/finding.md`, with the start path named. The prompt is at `probes/cloud-delivery/prompt.md`. The delivery run starts from the web session picker, because the picker is the only place that pins the model to Sonnet 5.5 (see [`probes/cloud-environment/finding.md`](../probes/cloud-environment/finding.md)). The start mechanisms, `github-start` and `claude --cloud`, remain their own probe on issue #2. The Cloud arm's review verdict comes from a second Cloud session on the pull request branch. That session uses the review prompt from the factory's public review gate, in `probes/cloud-delivery/review-prompt.md`, so both arms score a separate review pass. Proof: [PR 5](https://github.com/sbiondolillo/platform-eval-sample/pull/5) from the web picker, review `APPROVED`, build about 7 min, spend not exposed per session, in [`probes/cloud-delivery/finding.md`](../probes/cloud-delivery/finding.md).
- [x] Both pull requests are open or merged on the target repo, side by side. Proof: PR 5 (Cloud) and PR 6 (platform) are open and unmerged on 2026-10-24.

### Side experiment: the product behind `@claude`

- [ ] The Claude GitHub App is installed on the target repo. An `@claude` mention on issue #2 is answered. Finding: where the run executed, an Actions log on a GitHub runner or a session at claude.ai/code.

### Report

- [ ] The table in `site/` has sixteen rows and two columns. Every cell links its proof.
- [ ] The report ends with the conditional: rows Cloud Sessions cover today, rows the factory owner must build under either choice, rows not documented and their probe result. Then one ladder rung per arm.
- [ ] GitHub Pages serves `site/` from `main`, and the URL is in `README.md`.
- [ ] The platform collector and the throwaway hostname are torn down. The Share scope of the Cloud delivery session is set back to Private. The teardown commit is cited here.

## Settled design

Decided in a grilling session on 2026-10-24. Each line is a decision, with its reason.

- **Purpose.** Settle the direction of `dotnet-software-factory` v2: keep its own sandbox on a runner, or start its runs as Cloud Sessions from GitHub. The controls decide, because both arms run the same agent on the same model. A blog post is downstream.
- **Shape.** A controls comparison, with one end-to-end delivery per arm as the path proof. A delivery-rate benchmark measures harness noise, because both arms run Claude Code on one model.
- **Platform arm.** The .NET port on a self-hosted runner in a lab VM on the Sandbox VLAN, routed through the lab gateway, secrets pulled from Infisical, egress by the VLAN's allowlist. The .NET port on a GitHub-hosted runner is not a stand-in: it passes the key into the container and has open egress, so it loses the four rows the argument is about.
- **Public assets on both sides.** A platform cell with only a private proof is marked unproven. The runner's runs show in the public target repo's Actions log, and the runner's config is published here.
- **One target repo, one issue, two pull requests.** Holds the target constant, and puts the two results in one place a reader opens.
- **Cloud start.** The fire endpoint on a label is the probe, `claude --cloud` the fallback. The Claude Code GitHub Action is named in the report as the trap: it is the platform's shape with the key in the job.
- **Collector.** Grafana Cloud first, because its auth header tests the documented "credentials cannot go in environment variables" rule. A throwaway lab collector second.
- **Conclusion.** A row-by-row conditional closed with a ladder rung per arm. A verdict hides the rows that are the same under either choice. A conditional is checked cell by cell.
- **Scoring the delivery.** Gates, review verdict, wall time, spend. No blind judge: the run proves the path and does not rank the arms.
- **Cut row.** "Gates read the tree, not the agent's report" is a property of the factory code, and both arms can hold it equally.

## Names

| name | value |
|---|---|
| target repo | `sbiondolillo/platform-eval-sample`, from the starter at `v1.1.0` |
| cloud environment | to be filled when created |
| throwaway hostname | to be filled when created |
| model, both arms | `claude-sonnet-5-5`, hard-coded in the factory and pinned in the target's `.claude/settings.json`. The pin did not apply to the Cloud session picker: see [the finding](../probes/cloud-environment/finding.md). |
| credit expiry | 2026-11-05 |

## Sources

- The eight building blocks of a factory, as the `homelab-factory` README and the post lay them out: gateway, tool and model policy, run history, sandbox, egress proxy, branch protection, network-free gates, and the issue-writing skill. They give rows 1 to 8.
- The post [Beginning with the End in Mind](https://sambiondolillo.com/posts/beginning-with-the-end-in-mind), for the three qualities and the experiment form.
- `homelab-factory` ADR-0002 and ADR-0007, for credential custody and the container decision.
- Claude Code docs: https://code.claude.com/docs/en/claude-code-on-the-web, https://code.claude.com/docs/en/cloud-environments, https://code.claude.com/docs/en/security, https://code.claude.com/docs/en/monitoring-usage, https://code.claude.com/docs/en/routines.
