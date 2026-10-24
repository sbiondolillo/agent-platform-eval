# Capture: toolchain probe, Cloud Sessions

Probe [toolchain](../../docs/plan.md). The environment `agent-platform-eval` and its setup script are in [`../cloud-environment/finding.md`](../cloud-environment/finding.md) and [`../cloud-environment/setup.sh`](../cloud-environment/setup.sh). The script installs .NET SDK 10.0.402 with `dotnet-install.sh` to `/usr/share/dotnet`.

## Session "System environment check", about 17:35 UTC on 2026-10-24

The first session on the environment. Observed by the operator in the web UI. The "Initialized session" row expands to four rows:

1. Set up a cloud container
2. Cloned repository
3. Ran setup script. The row shows the script's output, which includes these lines:
   ```
   dotnet-install: Attempting to download using primary link https://builds.dotnet.microsoft.com/dotnet/Sdk/10.0.402/dotnet-sdk-10.0.402-linux-x64.tar.gz
   dotnet-install: Remote file ... size is 240279509 bytes
   dotnet-install: Extracting archive from ...
   ```
4. Started Claude Code

No row shows a duration. The download is 240279509 bytes, about 240 MB.

## Session "Tool and model policy probe", about 23:45 UTC on 2026-10-24

Observed by the operator in the web UI. The "Initialized session" row expands to three rows:

1. Set up a cloud container
2. Cloned repository
3. Started Claude Code

There is no "Ran setup script" row. Sessions on the same environment that day ran `dotnet` commands with the SDK present, for example the integration reruns in [`../cloud-delivery/finding.md`](../cloud-delivery/finding.md).

The probe did not open the sessions between these two. The probe thus does not show which session first skipped the script, or whether a session between them ran the script again.

## Public docs

Read on 2026-10-24. Quotes are exact.

### When the setup script runs

https://code.claude.com/docs/en/cloud-environments, section "Setup scripts":

> A setup script is a Bash script that runs when a new cloud session starts, before Claude Code launches.

Same page, section "Environment caching":

> The setup script runs the first time you start a session in an environment.

Same page, table "Setup scripts vs. SessionStart hooks", row "When they run":

> Before Claude Code launches, skipped when a [cached environment](#environment-caching) exists

https://code.claude.com/docs/en/claude-code-on-the-web:

> While the cloud container starts, the CLI shows a live checklist of setup steps, such as cloning the repository and running your [setup script](https://code.claude.com/docs/en/cloud-environments.md#setup-scripts).

### Whether the result is cached or snapshotted

https://code.claude.com/docs/en/cloud-environments, section "Environment caching":

> When setup completes within [roughly five minutes](#script-requirements), Anthropic snapshots the filesystem and reuses that snapshot as the starting point for later sessions. New sessions start with your dependencies, tools, and Docker images already on disk, and skip the setup script step. This keeps startup fast even when the script installs large toolchains or pulls container images. If setup takes longer than roughly five minutes, the environment isn't cached.

> The cache is a filesystem snapshot, so it keeps what the setup script writes to disk and loses anything that was only running.

> You don't need to enable caching or manage snapshots yourself.

Same page, section "Run tests, start services, and add packages", part "Add packages":

> The [environment cache](#environment-caching) keeps what the script installs, so packages you install there are available at the start of every session without reinstalling each time. You can also ask Claude to install packages mid-session, but those installs don't carry over to other sessions.

### When the cache expires or is rebuilt

https://code.claude.com/docs/en/cloud-environments, section "Environment caching":

> The setup script runs again to rebuild the cache when you change the environment's setup script or allowed network hosts, and when the cache reaches its expiry after roughly seven days. In an Anthropic-hosted environment, the setup script doesn't run when a session's VM is [restored after being idle](#set-environment-variables), so a change to the script reaches an existing session only when its VM was [reclaimed](https://code.claude.com/docs/en/claude-code-on-the-web.md#environment-expired) and is rebuilt.

The docs give no sentence on how a session shows that it started from a rebuilt cache. The docs give no sentence on whether a change to the environment variables or network secrets rebuilds the cache.

### Size and time limits

https://code.claude.com/docs/en/cloud-environments, section "Time limits":

> **Setup script**: a script that takes longer than roughly five minutes isn't cached.

Same page, section "Script requirements":

> **Finish within five minutes**: keep the script's total runtime under roughly five minutes so the [environment cache](#environment-caching) can build. When setup takes longer than that, the environment isn't cached.

> **Exit zero**: if the script exits non-zero, the session fails to start.

Same page, section "Add a setup script":

> Enter the script in the box that opens, or select **Choose file** to replace the box's contents with the text of a file up to 64 KB.

Same page, section "Resource limits":

> Cloud sessions in Anthropic-hosted environments run with approximate resource ceilings that may change over time:
>
> * 4 vCPUs
> * 16 GB of RAM
> * 30 GB of disk

Same page, section "Install dependencies with a SessionStart hook", last paragraph:

> Replacing the base image entirely isn't supported yet.

https://code.claude.com/docs/en/web-quickstart, section "New sessions hang or time out during setup":

> If new sessions stall on the setup script step or fail with a generic container error before the script finishes, the script is likely exceeding the roughly five-minute time budget for building the [environment cache](https://code.claude.com/docs/en/cloud-environments.md#environment-caching).

https://code.claude.com/docs/en/claude-code-on-the-web, section "Limitations":

> **Time limits**: commands Claude runs and SessionStart hooks have default timeouts you can change, and a setup script is cached only when it finishes in roughly five minutes.

No sentence on a size limit for the snapshot itself.
