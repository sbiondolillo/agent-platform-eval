# Substrate

Probe for [issue #2](../../docs/plan.md). Question: who runs the code, as what user, with which capabilities.

The answer sets the first rung of the isolation ladder for each arm in the DSF v2 decision.

## Cloud Sessions

The code runs in a Firecracker microVM. The evidence: kernel `6.18.44-fc`, a `virtio_vsock` kernel worker, a custom `process_api` as PID 1, no `/.dockerenv`, and the hypervisor flag on all 4 vCPUs. `systemd-detect-virt` says "docker", but the evidence says microVM. The VM has 4 vCPU, 16 GB RAM and a 252 GB disk. The code runs as root with the full bounding set minus `cap_sys_resource`, so `cap_sys_admin` is held, and no-new-privs is unset. The VM has one link, 192.0.2.2/24, and reaches the internet through the platform's proxy.

Capture: [`capture.md`](capture.md).

## Platform

The factory process runs on sandbox-01, a KVM VM on the Sandbox VLAN, as the runner user `github-runner` (uid 997), which is in the `docker` group. The agent runs in a Docker container that the factory starts from `dotnet-software-factory-sandbox` (Debian 12, Node 22, the .NET SDK, Claude Code). The container runs as uid 997 with no capability in its effective set, and Docker's default 14 in its bounding set, without `cap_sys_admin`. Seccomp and the `docker-default` AppArmor profile are on. No-new-privs is unset, and the image holds 8 setuid binaries, among them `su` and `mount`, but no `sudo`. The container shares the VM's kernel, `5.15.0-185-generic`, sits on the default bridge at 172.17.0.2/16, and gets the Squid allowlist proxy from the runner user's Docker client config. It has no memory or CPU limit, so it sees the VM's 4 vCPU, 8 GB RAM and 78 GB disk.

The factory's `docker run` sets `--user` and `--init` and nothing else that confines: no `--cap-drop`, no `--security-opt`, no `--network`, no resource limit. The confinement above is Docker's default.

Capture: [`capture-platform.md`](capture-platform.md).

## Comparison

| row | Cloud Sessions | Platform |
|---|---|---|
| isolation boundary | a Firecracker microVM per session | a Docker container per run, inside a long-lived KVM VM shared by all runs on the runner |
| kernel shared with host | no. The guest kernel `6.18.44-fc` is the VM's own. | yes, with the VM: `5.15.0-185-generic`. Not with the hypervisor host. |
| user inside | root, uid 0 | uid 997, with no name in the image's `/etc/passwd`, no capability in the effective set |
| `cap_sys_admin` | held, in the current and bounding sets | absent from the bounding set |
| network inside | one link, 192.0.2.2/24, egress through the platform's proxy | Docker bridge, 172.17.0.2/16, NAT through the VM on the Sandbox VLAN, `HTTPS_PROXY` set to the Squid allowlist at 10.26.0.10:3128 |
| resources (vCPU, RAM, disk) | 4 vCPU, 16 GB, 252 GB | no container limit: the VM's 4 vCPU, 8 GB, 78 GB, shared with the factory process |

The environment variable names from line 11 feed the model-credential and forge-credential probes: in the Cloud session `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `CLOUDSDK_AUTH_ACCESS_TOKEN`, `GH_TOKEN`, `GITHUB_TOKEN`, `CLAUDE_CODE_MESSAGING_TOKEN`, `ANTHROPIC_BASE_URL` and `HTTPS_PROXY` are present by name, and in the platform container `ANTHROPIC_API_KEY`, `ANTHROPIC_BASE_URL` and `HTTPS_PROXY` are present by name in a real run.

Cell for the report, Cloud Sessions: the agent runs as root with `cap_sys_admin` inside its own Firecracker microVM, so the VM boundary is the whole isolation.
Cell for the report, Platform: the agent runs as an unprivileged uid with Docker's default capabilities in a container that shares the runner VM's kernel, so the container and the VM are two boundaries, and the factory sets none of the container's confinement itself.
