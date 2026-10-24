# Capture: toolchain probe, platform arm

Probe [toolchain](../../docs/plan.md). Taken 2026-10-24 at about 23:55 UTC. Read-only. The factory is `sbiondolillo/dotnet-software-factory` at tag `v1.2.1`. The runner is sandbox-01 (Sandbox VLAN, 10.25.0.10). The target repo is `sbiondolillo/platform-eval-sample`.

The toolchain has two parts. The host SDK runs the factory process itself. The sandbox image holds the SDK and Claude Code for each agent call. The image is the part that matches the Cloud setup script.

## The image on sandbox-01

Over SSH as `sam`, who is in the `docker` group:

```
$ docker images --format '{{.Repository}}:{{.Tag}} {{.ID}} {{.Size}} {{.CreatedAt}}' | grep -i factory
dotnet-software-factory-sandbox:latest a00078c34038 2.11GB 2026-10-24 16:51:55 +0000 UTC
```

`docker history --no-trunc --format '{{.CreatedSince}} | {{.Size}} | {{.CreatedBy}}' dotnet-software-factory-sandbox`, trimmed to the layers the factory's Dockerfile adds. The layers below them are the `node:22-bookworm-slim` base.

```
7 hours ago | 4.1kB | WORKDIR /home/node
7 hours ago | 16.4kB | RUN |1 DOTNET_SDK_VERSION=10.0.401 /bin/sh -c mkdir -p /home/node/.config # buildkit
7 hours ago | 0B | USER node
7 hours ago | 512kB | RUN |1 DOTNET_SDK_VERSION=10.0.401 /bin/sh -c cd /tmp/api-printer     && dotnet publish -c Release -o /opt/api-printer ...
7 hours ago | 24.6kB | COPY sandbox/ApiPrinter /tmp/api-printer # buildkit
7 hours ago | 0B | ENV DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1
7 hours ago | 432MB | RUN |1 DOTNET_SDK_VERSION=10.0.401 /bin/sh -c npm install -g @anthropic-ai/claude-code # buildkit
7 hours ago | 654MB | RUN |1 DOTNET_SDK_VERSION=10.0.401 /bin/sh -c curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh     && bash /tmp/dotnet-install.sh --version "${DOTNET_SDK_VERSION}" --install-dir /usr/share/dotnet     && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet     && rm /tmp/dotnet-install.sh # buildkit
7 hours ago | 140MB | RUN |1 DOTNET_SDK_VERSION=10.0.401 /bin/sh -c apt-get update     && apt-get install --no-install-recommends -y git curl ca-certificates libicu72     && rm -rf /var/lib/apt/lists/* # buildkit
7 hours ago | 0B | ARG DOTNET_SDK_VERSION=10.0.401
```

- The image is 2.11 GB. The SDK layer is 654 MB. The Claude Code layer is 432 MB.
- The image has SDK 10.0.401. The Cloud setup script and the runner host install 10.0.402. The factory's `global.json` and the target's `global.json` both pin `10.0.401` with `rollForward: latestPatch`.
- The image is local to sandbox-01. No registry holds it.

## The Dockerfile, `sandbox/Dockerfile` at v1.2.1

```
     1	FROM node:22-bookworm-slim
     3	ARG DOTNET_SDK_VERSION
     9	RUN curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
    10	    && bash /tmp/dotnet-install.sh --version "${DOTNET_SDK_VERSION}" --install-dir /usr/share/dotnet \
    11	    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
    12	    && rm /tmp/dotnet-install.sh
    14	RUN npm install -g @anthropic-ai/claude-code
```

Lines 9 to 12 install the SDK. Line 14 installs Claude Code at whatever version npm serves at build time.

## Where the image is built

The factory builds the image itself. `homelab-ansible` does not build it: a grep of the repo for `dotnet-software-factory-sandbox` and `docker build` finds only two comments in `roles/factory_manager_toolchain/defaults/main.yml` (lines 23 and 28) that refer to the Dockerfile.

`src/Core/Sandbox.cs` line 27, at the start of every run:

```csharp
        await new SandboxImage(runner).EnsureAsync(tag, rootDirectory, cancellationToken).ConfigureAwait(false);
```

`src/Core/SandboxImage.cs` lines 12 to 37:

```csharp
        CommandResult inspect = await runner.RunAsync(
            new CommandSpec { Command = "docker", Arguments = ["image", "inspect", tag] },
            cancellationToken).ConfigureAwait(false);
        if (inspect.ExitCode is 0)
        {
            return;
        }

        string globalJson = await File.ReadAllTextAsync(
            Path.Combine(rootDirectory, "global.json"), cancellationToken).ConfigureAwait(false);
        ...
                    "build",
                    "--tag", tag,
                    "--file", Path.Combine(rootDirectory, "sandbox", "Dockerfile"),
                    "--build-arg", $"DOTNET_SDK_VERSION={version}",
                    rootDirectory,
```

- `tag` is `dotnet-software-factory-sandbox` (`src/Core/ConsoleCommands.cs` line 18). It has no version in it.
- `rootDirectory` is the factory checkout. The SDK version is the factory's `global.json` `sdk.version`, not the target's.
- The build runs only when `docker image inspect` fails. A new Dockerfile, a new SDK pin or a new Claude Code release does not trigger a build. The image changes only after someone deletes the tag on the host, and the next run then builds it.

The build runs as the runner user `github-runner` through its Docker client. `homelab-ansible` `roles/dsf_runner_host/tasks/main.yml` lines 46 to 64 write that client's proxy config, so the build fetches the SDK and Claude Code through the Squid allowlist. The comment at lines 46 to 48 says so: "the factory's sandbox image build fetches the SDK and Claude Code".

## The host SDK

The factory process runs on the host with the host SDK. `homelab-ansible` `roles/dsf_runner_host/tasks/main.yml`:

- line 66, "Fetch dotnet-install.sh", and line 75, "Install the .NET SDK {{ dsf_runner_host_dotnet_sdk_version }}", with `creates:` set to the SDK directory, so the task runs once per version.
- line 85, "Let the runner user add SDK patches": `actions/setup-dotnet` can add a newer patch beside the pre-installed SDK.
- `roles/dsf_runner_host/defaults/main.yml` line 24: `dsf_runner_host_dotnet_sdk_version: "10.0.402"`.
- The playbook is `playbooks/dsf_runner.yml`. Last change to the role: commit `3ee4df0`.

A host SDK change is a playbook run by the runner host's operator. A sandbox image change is a factory release plus a delete of the image on the host.

## The first build: run 40113445853

The first factory run that reached the sandbox was run 40113445853 (created 16:51:00Z, failed later at the plan gate). Four earlier runs failed in `actions/setup-dotnet` before the factory started. The image's `CreatedAt` is 16:51:55Z, inside this run. The factory does not log the `docker build` output. The log brackets it:

```
$ gh run view 40113445853 --repo sbiondolillo/platform-eval-sample --log | grep -A1 'sandbox: start'
2026-10-24T16:51:23.5228371Z sandbox: start
2026-10-24T16:52:29.2868939Z plan: start
```

The image build, the base image pull and the container start took about 66 s together.

## The per-job cost

Job steps of run 40115249577 (the smoke run), 40117342098 (delivery attempt 1) and 40118345316 (delivery attempt 2, PR 6), from `gh run view <id> --repo sbiondolillo/platform-eval-sample --json jobs --jq '.jobs[].steps[] | {name, startedAt, completedAt}'`. The API gives whole seconds.

| Step | 40115249577 | 40117342098 | 40118345316 |
|---|---|---|---|
| Set up job | 17:15:00 to 17:15:01, 1 s | 17:42:34 to 17:42:35, 1 s | 17:55:41 to 17:55:42, 1 s |
| Run actions/checkout@v7 | 17:15:01 to 17:15:01, 0 s | 17:42:35 to 17:42:35, 0 s | 17:55:42 to 17:55:43, 1 s |
| Run actions/setup-dotnet@v6 | 17:15:01 to 17:15:02, 1 s | 17:42:35 to 17:42:36, 1 s | 17:55:43 to 17:55:44, 1 s |
| Run the factory | 17:15:02 to 17:18:13 | 17:42:36 to 17:47:51 | 17:55:44 to 18:02:20 |

The job log of run 40118345316 splits the start of "Run the factory":

```
2026-10-24T17:55:41.3306776Z Runner name: 'sandbox-01'
2026-10-24T17:55:42.4760074Z ##[group]Run actions/checkout@v7
2026-10-24T17:55:43.1784773Z ##[group]Run actions/setup-dotnet@v6
2026-10-24T17:55:44.0380954Z ##[group]Run set -euo pipefail
2026-10-24T17:55:57.2843640Z sandbox: start
2026-10-24T17:55:57.6369523Z plan: start
```

- Set up job: about 1.1 s. Checkout of the factory: about 0.7 s. `setup-dotnet` with the SDK already on the host: about 0.9 s.
- Infisical login, `dotnet run` restore and compile of the factory: about 13.2 s.
- `docker image inspect` on the cached image and the container start: about 0.35 s.

The toolchain part of each job is thus about 16 s, and the image costs 0.35 s once it exists. Each agent container restores NuGet packages for the target in its own work tree. That restore is part of the gates, not of the toolchain, and the probe did not time it.
