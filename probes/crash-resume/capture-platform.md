# Capture: crash-resume probe, platform side

Probe [crash-resume](../../docs/plan.md). Read from the factory source at `dotnet-software-factory` tag `v1.2.1`. Nothing was run. Taken 2026-10-25.

## The container

`src/Core/Sandbox.cs:46-65` starts the container on the runner host `sandbox-01`:

```
docker run --detach --init --user <uid>:<gid> <volumes> --workdir /work --env HOME=/tmp/sandbox-home --env ANTHROPIC_API_KEY --env ANTHROPIC_BASE_URL <tag> sh -c "mkdir -p /tmp/sandbox-home/.config && exec sleep infinity"
```

Each phase runs `docker exec` into it. `DisposeAsync` removes it with `docker rm --force <id>` when the run ends (`src/Core/Sandbox.cs:112-114`).

## The work tree

Each run makes a new run id and a new temporary work tree (`src/Core/ConsoleCommands.cs:186-187`). A `finally` block deletes the work tree when the run ends (`src/Core/ConsoleCommands.cs:197-200`).

## Resume code

There is none. A grep of `src/` for "resume" finds nothing. Each phase calls `claude -p` with no session flag (`src/Core/ClaudeCodeAgent.cs:36-44`). A retry is a new run on a new branch `factory/<runId>` (`src/Core/Deliver.cs:24`).

## What remains after a job

- The pushed branch and the pull request, on GitHub.
- The job log, for 90 days ([`../cloud-logging/capture-platform.md`](../cloud-logging/capture-platform.md)).
- The transcripts. The container's home is a bind mount from `.factory/sandbox-home/<guid>/` on the runner host. The v1.2.1 starter pushes them to a private store repo in a step with `if: always()` (`templates/starter/.github/workflows/factory.yml:40-42`). See [`../run-history/finding.md`](../run-history/finding.md).

## Not tested

The source registers no signal handler. A cancelled job may kill the factory before `DisposeAsync` and the `finally` block run. Then the `sleep infinity` container could keep running on `sandbox-01`. No cancel was run for this probe.
