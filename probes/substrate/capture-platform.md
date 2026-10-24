# Capture: substrate probe, platform arm

Probe [substrate](../../docs/plan.md). Taken 2026-10-24 at about 22:40 UTC on the self-hosted runner sandbox-01 (Sandbox VLAN, 10.25.0.10), over SSH as the operator account `sam`. The commands are the eleven lines of [`prompt.md`](prompt.md). Each output below is trimmed to the lines that answer the question. Line 11 prints variable names only.

The factory is `sbiondolillo/dotnet-software-factory` at tag `v1.2.1`. The factory process runs on the runner host. Each agent call runs inside a Docker container that the factory starts. The reading thus has two layers: the host VM and the container.

## The docker invocation, from source at v1.2.1

`src/Core/Sandbox.cs`, lines 29 to 65:

```csharp
        string user = string.Create(CultureInfo.InvariantCulture, $"{GetUid()}:{GetGid()}");
        ...
        List<string> volumes = ["--volume", $"{workTree}:/work", "--volume", $"{home}:{Home}"];
        string gitDirectory = Path.Combine(workTree, ".git");
        if (Directory.Exists(gitDirectory))
        {
            ...
            volumes.AddRange(["--volume", $"{gitDirectory}:/work/.git:ro", "--volume", $"{worktrees}:/work/.git/worktrees"]);
        }

        CommandResult run = await runner.RunAsync(
            new CommandSpec
            {
                Command = "docker",
                Arguments =
                [
                    "run",
                    "--detach",
                    "--init",
                    "--user", user,
                    .. volumes,
                    "--workdir", "/work",
                    "--env", $"HOME={Home}",
                    "--env", "ANTHROPIC_API_KEY",
                    "--env", "ANTHROPIC_BASE_URL",
                    tag,
                    "sh", "-c", $"mkdir -p {Home}/.config && exec sleep infinity",
                ],
            },
            cancellationToken).ConfigureAwait(false);
```

- `Home` is `/tmp/sandbox-home` (`src/Core/Sandbox.cs` line 9).
- `tag` is `dotnet-software-factory-sandbox` (`src/Core/ConsoleCommands.cs` line 18).
- `user` is the uid and gid of the factory process, from `getuid` and `getgid` (lines 29, 116 to 120). On sandbox-01 that is the runner user, `997:998`.
- Each command then runs as `docker exec [--workdir D] [--env NAME ...] <id> <program> <args>` (lines 90 to 108). The `--env` names are the run's `--pass-env` list. The target's `factory.yml` passes `ANTHROPIC_BASE_URL`.
- The image is `sandbox/Dockerfile`: `FROM node:22-bookworm-slim` (line 1), git, curl, the .NET SDK and Claude Code, `USER node` (line 27). The `--user` flag overrides `USER node`.

The invocation has no `--cap-drop`, no `--cap-add`, no `--security-opt`, no `--network`, no `--privileged`, no `--memory`, no `--cpus` and no `--read-only`. The container gets Docker's defaults for all of them. No Docker socket is mounted.

One input comes from outside the source. The runner user's Docker client config, `/home/github-runner/.docker/config.json`, sets `proxies.default` (written by `homelab-ansible` `roles/dsf_runner_host/tasks/main.yml`, lines 58 to 64). The Docker client then sets `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY` and their lowercase forms in each container it starts. The proxy is the Sandbox VLAN's Squid allowlist at `10.26.0.10:3128`.

## Layer 1: the host VM

### 1. `uname -a`
```
Linux sandbox-01 5.15.0-185-generic #195-Ubuntu SMP Fri Jun 19 17:11:50 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux
```

### 2. `cat /etc/os-release`
```
PRETTY_NAME="Ubuntu 22.04.5 LTS"
```

### 3. `id`, and the runner user

The probe ran as `sam`:
```
uid=1000(sam) gid=1000(sam) groups=1000(sam),4(adm),20(dialout),24(cdrom),25(floppy),27(sudo),29(audio),30(dip),44(video),46(plugdev),118(netdev),119(lxd),997(docker)
```

The runner process and its user (`ps -eo user,pid,comm`, then `id`, then `systemctl show` on the runner unit):
```
github-runner                    44349 Runner.Listener
uid=997(github-runner) gid=998(github-runner) groups=998(github-runner),997(docker)
github-runner:/home/github-runner:/usr/sbin/nologin
User=github-runner
NoNewPrivileges=no
ProtectSystem=no
```

The unit is `github-runner-sbiondolillo-platform-eval-sample.service`. The runner user is in the `docker` group.

### 4. `nproc; free -m; df -h / /home`
```
4
               total        used        free      shared  buff/cache   available
Mem:            7937         349        1787          24        5800        7256
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda1        78G   11G   68G  14% /
```

### 5. `systemd-detect-virt`
```
kvm
```

### 6. `grep -c hypervisor /proc/cpuinfo; grep -m1 'model name' /proc/cpuinfo`
```
4
model name	: QEMU Virtual CPU version 2.5+
```

### 7. `capsh --print`, whole output, as `sam`
```
Current: =
Bounding set =cap_chown,cap_dac_override,cap_dac_read_search,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_linux_immutable,cap_net_bind_service,cap_net_broadcast,cap_net_admin,cap_net_raw,cap_ipc_lock,cap_ipc_owner,cap_sys_module,cap_sys_rawio,cap_sys_chroot,cap_sys_ptrace,cap_sys_pacct,cap_sys_admin,cap_sys_boot,cap_sys_nice,cap_sys_resource,cap_sys_time,cap_sys_tty_config,cap_mknod,cap_lease,cap_audit_write,cap_audit_control,cap_setfcap,cap_mac_override,cap_mac_admin,cap_syslog,cap_wake_alarm,cap_block_suspend,cap_audit_read,cap_perfmon,cap_bpf,cap_checkpoint_restore
Ambient set =
Current IAB: 
Securebits: 00/0x0/1'b0
 secure-noroot: no (unlocked)
 secure-no-suid-fixup: no (unlocked)
 secure-keep-caps: no (unlocked)
 secure-no-ambient-raise: no (unlocked)
uid=1000(sam) euid=1000(sam)
gid=1000(sam)
groups=4(adm),20(dialout),24(cdrom),25(floppy),27(sudo),29(audio),30(dip),44(video),46(plugdev),118(netdev),119(lxd),997(docker),1000(sam)
Guessed mode: UNCERTAIN (0)
```

The runner unit's `CapabilityBoundingSet` is the full set, the same as above.

### 8. `cat /proc/1/comm; cat /proc/1/cgroup; ls -la /.dockerenv`
```
systemd
0::/init.scope
ls: cannot access '/.dockerenv': No such file or directory
```

### 9. `ps -eo pid,user,comm --sort=pid | head -40`, PID 1 only
```
    PID USER     COMMAND
      1 root     systemd
```

### 10. `ip addr`, trimmed
```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536
    inet 127.0.0.1/8 scope host lo
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
    inet 10.25.0.10/24 brd 10.25.0.255 scope global eth0
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
```

`ip route`: default via 10.25.0.1 on eth0. `docker info`: security options `apparmor`, `seccomp` (builtin profile), `cgroupns`. cgroup v2. Docker 29.9.2.

### 11. `env | cut -d= -f1 | sort`

This is the SSH session of `sam`, not the runner's environment. The runner's environment was not read.
```
DBUS_SESSION_BUS_ADDRESS
HOME
HTTPS_PROXY
HTTP_PROXY
LANG
LOGNAME
MOTD_SHOWN
NO_PROXY
PATH
PWD
SHELL
SHLVL
SSH_CLIENT
SSH_CONNECTION
USER
XDG_RUNTIME_DIR
XDG_SESSION_CLASS
XDG_SESSION_ID
XDG_SESSION_TYPE
_
http_proxy
https_proxy
no_proxy
```

The runner's own `.env` file, `/opt/actions-runner/sbiondolillo-platform-eval-sample/.env`, holds these names: `https_proxy`, `http_proxy`, `no_proxy`, `HTTPS_PROXY`, `HTTP_PROXY`, `NO_PROXY`.

## Layer 2: the container

A throwaway container with the flags of the source, the probe as its command, and no mounts. It ran as `sam`, who is in the `docker` group. No grant was needed.

```
docker run --rm -i --init --user 997:998 --workdir /work --env HOME=/tmp/sandbox-home --env ANTHROPIC_API_KEY --env ANTHROPIC_BASE_URL dotnet-software-factory-sandbox sh -s < probe.sh
```

Two differences from a real run. The two `ANTHROPIC_*` names were not set in the shell of `sam`, so Docker left them out. The Docker client of `sam` has no proxy config, so the six proxy names are absent. In a real run, all eight names are present. `docker ps -a` was empty after the run.

### 1. `uname -a`
```
Linux 6eb533116a42 5.15.0-185-generic #195-Ubuntu SMP Fri Jun 19 17:11:50 UTC 2026 x86_64 GNU/Linux
```

### 2. `cat /etc/os-release`
```
PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"
```

### 3. `id`
```
uid=997 gid=998 groups=998
```

### 4. `nproc; free -m; df -h / /home`
```
4
sh: 1: free: not found
Filesystem      Size  Used Avail Use% Mounted on
overlay          78G   11G   68G  14% /
```

A second throwaway container with the same flags read the limits: `MemTotal: 8127788 kB`, `memory.max max`, `cpu.max max 100000`, `pids.max 9475`.

### 5. `systemd-detect-virt`, then the fallback
```
sh: 1: systemd-detect-virt: not found
QEMU
Standard PC (i440FX + PIIX, 1996)
```

### 6. `grep -c hypervisor /proc/cpuinfo; grep -m1 'model name' /proc/cpuinfo`
```
4
model name	: QEMU Virtual CPU version 2.5+
```

### 7. `capsh --print`, then the fallback, whole output
```
sh: 1: capsh: not found
CapInh:	0000000000000000
CapPrm:	0000000000000000
CapEff:	0000000000000000
CapBnd:	00000000a80425fb
CapAmb:	0000000000000000
```

`capsh --decode=00000000a80425fb` on the host:
```
0x00000000a80425fb=cap_chown,cap_dac_override,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_net_bind_service,cap_net_raw,cap_sys_chroot,cap_mknod,cap_audit_write,cap_setfcap
```

The second container read the confinement:
```
NoNewPrivs:	0
Seccomp:	2
docker-default (enforce)
```

Setuid binaries in the image: `newgrp`, `su`, `umount`, `chfn`, `gpasswd`, `chsh`, `mount`, `passwd`. No `sudo`.

### 8. `cat /proc/1/comm; cat /proc/1/cgroup; ls -la /.dockerenv`
```
docker-init
0::/
-rwxr-xr-x 1 root root 0 Oct 24 22:40 /.dockerenv
```

### 9. `ps -eo pid,user,comm --sort=pid | head -40`
```
sh: 1: ps: not found
```

### 10. `ip addr`, then the fallback, trimmed to the `Main:` table
```
sh: 1: ip: not found
Main:
  +-- 0.0.0.0/0 3 0 5
     |-- 0.0.0.0
        /0 universe UNICAST
     +-- 127.0.0.0/8 2 0 2
        +-- 127.0.0.0/31 1 0 0
           |-- 127.0.0.0
              /8 host LOCAL
           |-- 127.0.0.1
              /32 host LOCAL
        |-- 127.255.255.255
           /32 link BROADCAST
     +-- 172.17.0.0/16 2 0 2
        +-- 172.17.0.0/30 2 0 2
           |-- 172.17.0.0
              /16 link UNICAST
           |-- 172.17.0.2
              /32 host LOCAL
        |-- 172.17.255.255
           /32 link BROADCAST
```

### 11. `env | cut -d= -f1 | sort`
```
DOTNET_CLI_TELEMETRY_OPTOUT
DOTNET_NOLOGO
HOME
HOSTNAME
NODE_VERSION
PATH
PWD
YARN_VERSION
```

In a real run, the container also holds `ANTHROPIC_API_KEY` and `ANTHROPIC_BASE_URL` from `docker run`, and `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY`, `http_proxy`, `https_proxy`, `no_proxy` from the runner user's Docker client config. Each `docker exec` adds the `--pass-env` names.
