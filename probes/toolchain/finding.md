# Toolchain

Probe for [issue #2](../../docs/plan.md). Question: what a non-default toolchain costs in each arm, at first use, per run, and when it must change. The .NET SDK is not in either arm's base image, so the answer sets how DSF v2 would carry its toolchain. The evidence is in [`capture.md`](capture.md) and [`capture-platform.md`](capture-platform.md). No separate session ran ([`prompt.md`](prompt.md)).

## Cloud Sessions

The setup script ran once, in the first session on the environment, and its output shows a 240 MB SDK download ([`capture.md`](capture.md)). The UI showed no duration for the script or for any other setup row. A session six hours later had no "Ran setup script" row and still had the SDK, so later sessions start from a snapshot taken after setup. The docs say that the snapshot is a filesystem snapshot, and that it is made only when the script finishes in roughly five minutes. The docs say: "The setup script runs again to rebuild the cache when you change the environment's setup script or allowed network hosts, and when the cache reaches its expiry after roughly seven days." The probe did not see a rebuild, although the allowlist changed during the day, because it did not open the sessions between the two observations.

## Platform

The factory builds the sandbox image itself on the runner host, from `sandbox/Dockerfile` in the factory repo, the first time a run finds no image ([`capture-platform.md`](capture-platform.md)). That build took about 66 s and made a 2.11 GB image with the SDK baked in. Ansible does not build the image. It installs only the host SDK that runs the factory process. Each job then pays about 16 s for its toolchain: 1 s for Set up job, 1 s for the checkout, 1 s for `setup-dotnet`, and about 13 s to log in to Infisical and compile the factory. The image has no expiry and no rebuild trigger: the factory checks only that the tag exists, so a new Dockerfile or SDK pin takes effect only after someone deletes the image on the host.

## Comparison

| Row | Cloud Sessions | Platform |
|---|---|---|
| Where the toolchain is defined | The environment's setup script, in the claude.ai/code dialog. It is not in a repo. | `sandbox/Dockerfile` in the factory repo, with the SDK version from the factory's `global.json`. The host SDK is in the `homelab-ansible` role `dsf_runner_host`. |
| First-time cost | One setup script run with a 240 MB SDK download. The UI shows no duration. | About 66 s for the image build, the base pull and the container start in run 40113445853. The image is 2.11 GB. |
| Per-session or per-job cost | No setup script step. The container start is not timed, because the UI shows no durations. | About 16 s: Set up job 1 s, checkout 1 s, `setup-dotnet` 1 s, Infisical login and factory compile 13 s. The image check and container start take 0.35 s. |
| Cache or snapshot | A filesystem snapshot after the setup script, managed by the product. | The image tag in the runner host's local Docker store. No registry. |
| Expiry or rebuild trigger | By the docs: a change to the setup script or to the allowed hosts, or expiry after roughly seven days. No cache if the script takes more than roughly five minutes. | None. The factory builds only when the tag is missing. A delete of the image on the host is the only trigger. |
| Who can change it | The person who owns the environment. Organization Owners edit shared environments. | The factory maintainer changes the Dockerfile in a release. The runner host's operator deletes the image and runs the playbook for the host SDK. |

Two differences matter for DSF v2. First, Cloud Sessions rebuilds the toolchain on its own, on a change or after about seven days, while the platform image stays as built until someone deletes it, so a new Claude Code release or SDK patch does not reach the platform by itself. Second, the Cloud toolchain lives in a web dialog outside version control, while the platform toolchain is a Dockerfile in the factory repo at a release tag.

## Managed Agents

Probed 2026-10-27 in the substrate session `sesn_01BdfqEvYjyeHEFzS61c1VgR` ([`../substrate/capture-ma.md`](../substrate/capture-ma.md)). Docs: https://platform.claude.com/docs/en/managed-agents/environments. The environment's `packages` field takes apt names from the Ubuntu archive only, and it needs `allow_package_managers: true`, which opens the Ubuntu, GitHub, PyPI, npm and other package hosts to the sandbox whatever `allowed_hosts` says. `apt: [dotnet-sdk-10.0]` installed SDK `10.0.113` at `/usr/lib/dotnet/sdk`, the Ubuntu feature band. The target's `global.json` pins `10.0.401` with `rollForward: latestPatch`, which accepts a `10.0.4xx` SDK only, so `dotnet build` in the mounted repo refuses `10.0.113`. The first session on a fresh environment took 53 active seconds end to end, SDK install included. Three ways to a `10.0.4xx` SDK, none proven: `dotnet-install.sh` in the session with `builds.dotnet.microsoft.com` and `dotnet.microsoft.com` in `allowed_hosts`, which runs on every session; a `pip` or `npm` package that carries the SDK, which the docs do not list; or a `global.json` edit in the reviewer's own clone, which changes the compiler the review builds with.

The repo-skills sub-row, in session `sesn_01A2Zcqk8hKbxgYC5UnACCrz` ([`../cloud-logging/capture-ma.md`](../cloud-logging/capture-ma.md)): with the target mounted, the agent reports no skill loaded at session start, although `.claude/skills/change/SKILL.md` is one level deep as the docs require. Whether `disable-model-invocation: true` in its frontmatter is the cause is not settled. The reviewer therefore reads `JUDGES.md` by path, which needs only the `read` tool. The mounted clone is shallow, 50 commits, and `dotnet --version` in it exits 155 with "A compatible .NET SDK was not found" for `10.0.401`.

## Report cells

Cloud: a setup script in the environment installs the SDK once, and later sessions start from a filesystem snapshot that the docs say is rebuilt on a script or allowlist change and after about seven days, but the UI shows no setup duration.

Platform: the factory builds a 2.11 GB image from its own Dockerfile on the runner host at first use in about 66 s, each job then pays about 16 s of toolchain setup, and the image never expires and changes only when someone deletes it.

Managed Agents: `packages` installs the Ubuntu archive's `dotnet-sdk-10.0`, which is `10.0.113`, in a first session of 53 active seconds, and the target's `10.0.4xx` band needs a route the docs do not give.
