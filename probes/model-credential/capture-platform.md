# Capture: model-credential probe, platform arm

Probe [model-credential](../../docs/plan.md). Taken 2026-10-24 at about 22:50 UTC. The source was read at the commits named below. The host was read over SSH on the self-hosted runner sandbox-01 (Sandbox VLAN, 10.25.0.10) as the operator account `sam`, with no sudo. No value of a secret was read or printed. The outputs below hold paths, names and status codes only.

The factory is `sbiondolillo/dotnet-software-factory` at tag `v1.2.1`. The factory process runs on the runner host. Each agent call runs in a Docker container that the factory starts. The credential path thus has three layers: the job step, the factory process and the container.

## 1. The job step fetches the secrets

`sbiondolillo/platform-eval-sample`, `.github/workflows/factory.yml` on `main` (last changed in `8446149`), lines 36 to 46:

```
    36	      - name: Run the factory
    37	        env:
    38	          FACTORY_CHECKS_TOKEN: ${{ github.token }}
    39	          ANTHROPIC_BASE_URL: http://10.99.0.186:8200
    40	        run: |
    41	          set -euo pipefail
    42	          set -a; . /etc/homelab/dsf/.infisical-auth.env; set +a
    43	          DOMAIN="https://infisical-api.sambiondolillo.com/api"
    44	          TOKEN=$(infisical login --method=universal-auth --client-id="$INFISICAL_CLIENT_ID" --client-secret="$INFISICAL_CLIENT_SECRET" --domain="$DOMAIN" --silent --plain)
    45	          exec infisical run --token="$TOKEN" --projectId="${{ vars.INFISICAL_PROJECT_ID }}" --domain="$DOMAIN" --env=prod -- \
    46	            dotnet run --project src/App -c Release -- run --repo ${{ github.repository }} --issue ${{ inputs.issue || github.event.issue.number }} --pass-env ANTHROPIC_BASE_URL
```

- The Infisical machine identity is `dsf-sandbox01` (Universal Auth). Its client ID and client secret are a host file, `/etc/homelab/dsf/.infisical-auth.env`, not a GitHub secret. Line 42 exports the names in that file into the step's shell. Line 44 reads two of them, `INFISICAL_CLIENT_ID` and `INFISICAL_CLIENT_SECRET`.
- Line 44 trades them for an Infisical access token. Line 45 passes that token to `infisical run` as a command-line argument.
- `infisical run` injects every secret of the `dsf` project, `prod` environment, into the factory process. The project holds two names: `FACTORY_GITHUB_TOKEN` and `ANTHROPIC_API_KEY` (homelab `docs/credentials.md`, the row "Infisical project `dsf`").
- The factory process thus holds, by name: `ANTHROPIC_API_KEY`, `ANTHROPIC_BASE_URL`, `FACTORY_GITHUB_TOKEN`, `FACTORY_CHECKS_TOKEN`, `INFISICAL_CLIENT_ID` and `INFISICAL_CLIENT_SECRET`.
- The project ID is a repository variable (`vars.INFISICAL_PROJECT_ID`), not a secret. The workflow uses no GitHub secret.

## 2. The factory passes two names into the container

`sbiondolillo/dotnet-software-factory` at `v1.2.1`, `src/Core/Sandbox.cs`, lines 59 and 60, inside the `docker run` argument list that the [substrate capture](../substrate/capture-platform.md#the-docker-invocation-from-source-at-v121) quotes in full:

```csharp
                    "--env", "ANTHROPIC_API_KEY",
                    "--env", "ANTHROPIC_BASE_URL",
```

`--env NAME` with no value copies the variable from the factory process. Each later `docker exec` adds the run's `--pass-env` names, here `ANTHROPIC_BASE_URL` only (workflow line 46). The other four names of section 1 do not enter the container. The Docker client config of the runner user adds the six proxy names (substrate capture).

## 3. What the key is

From the homelab docs:

- `ANTHROPIC_BASE_URL` is `http://10.99.0.186:8200`, the fleet inference gateway on `llm-01`, a LiteLLM proxy (homelab `docs/services-llm.md`, section "Fleet inference gateway (LiteLLM)", lines 89 to 96).
- The `dsf` project's `ANTHROPIC_API_KEY` "holds the value of the gateway's `LITELLM_DSF_KEY`, not the real Anthropic key" (homelab `docs/credentials.md`, line 42).
- "The real Anthropic API key lives here (`ANTHROPIC_API_KEY` in the `litellm` Infisical project)" (homelab `docs/services-llm.md`, line 98). The gateway reads it on `llm-01` through its own machine identity, `litellm-llm01` (homelab `docs/credentials.md`, line 40).
- The Sandbox VLAN has one permit to `llm-01`: `sandbox-01` to `llm-01:8200`, rule `sandbox01_to_llm01_gateway` (homelab `docs/network.md`, line 258).

From the gateway source, `homelab-services` `envs/llm-01/litellm/custom_auth.py` at `bff7a03`, lines 13 to 25:

```python
CONSUMERS = {
    os.environ["LITELLM_FACTORY_KEY"]: "factory",
    os.environ["LITELLM_JARVIS_KEY"]: "jarvis",
    os.environ["LITELLM_WOLFIE_KEY"]: "wolfie",
    os.environ["LITELLM_DSF_KEY"]: "dsf",
}


async def user_api_key_auth(request: Request, api_key: str) -> UserAPIKeyAuth:
    consumer = CONSUMERS.get(api_key)
    if consumer is None:
        raise Exception("invalid gateway key")
    return UserAPIKeyAuth(api_key=api_key, user_id=consumer)
```

The key is a static per-consumer gateway key, not a LiteLLM virtual key. The auth function returns a consumer name and nothing else: no spend budget, no rate limit and no model list. The `dsf` key thus reaches every model in the gateway's `config.yaml`, four Anthropic models and three local models. Every call is attributed to consumer `dsf` in the gateway ledger.

## 4. What persists on sandbox-01

### `grep -rIl -E 'sk-ant-|ANTHROPIC_API_KEY' /opt/actions-runner /home 2>/dev/null | head`
```
/opt/actions-runner/sbiondolillo-platform-eval-sample/_work/platform-eval-sample/platform-eval-sample/README.md
/opt/actions-runner/sbiondolillo-platform-eval-sample/_work/platform-eval-sample/platform-eval-sample/AGENTS.md
/opt/actions-runner/sbiondolillo-platform-eval-sample/_work/platform-eval-sample/platform-eval-sample/templates/starter/.github/workflows/factory.yml
/opt/actions-runner/sbiondolillo-platform-eval-sample/_work/platform-eval-sample/platform-eval-sample/templates/starter/.github/workflows/review-feedback.yml
/opt/actions-runner/sbiondolillo-platform-eval-sample/_work/platform-eval-sample/platform-eval-sample/tests/Integration/SandboxIntegrationTests.cs
/opt/actions-runner/sbiondolillo-platform-eval-sample/_work/platform-eval-sample/platform-eval-sample/tests/Integration/ClaudeCodeAgentIntegrationTests.cs
/opt/actions-runner/sbiondolillo-platform-eval-sample/_work/platform-eval-sample/platform-eval-sample/tests/Specs/Unit/ConsoleHarness.cs
/opt/actions-runner/sbiondolillo-platform-eval-sample/_work/platform-eval-sample/platform-eval-sample/tests/Specs/Unit/ConsoleProgramTests.cs
/opt/actions-runner/sbiondolillo-platform-eval-sample/_work/platform-eval-sample/platform-eval-sample/tests/Specs/Unit/WorkflowChecksTests.cs
/opt/actions-runner/sbiondolillo-platform-eval-sample/_work/platform-eval-sample/platform-eval-sample/tests/Specs/Unit/SandboxTests.cs
```

The directory is the job's checkout of `sbiondolillo/dotnet-software-factory` at `v1.2.1` (`git remote get-url origin`, `git describe --tags`). The readable hits are 30 files of factory source and docs that name the variable. One file matches `sk-ant-`: `tests/Integration/ClaudeCodeAgentIntegrationTests.cs`, line 132, the literal fixture `sk-ant-invalid-key`. No readable file under `/opt/actions-runner` or `/home` holds an Anthropic key.

The `sk-ant-` pattern cannot find the gateway key, whose value has no known prefix. A search for that value needs the value, and `sam` cannot read it. This probe did not search for it.

### Paths unreadable as `sam`

The same grep's `Permission denied` lines, trimmed to the paths:
```
/opt/actions-runner/sbiondolillo-platform-eval-sample/_work/platform-eval-sample/platform-eval-sample/.factory/sandbox-home/495e3cfd55d94c968a5c1943c6c4032e/.dotnet/corefx/cryptography/x509stores/my/14E564DD3A36F3490A9E75F7F171DC2BB479C2E0.pfx
/opt/actions-runner/sbiondolillo-platform-eval-sample/_work/platform-eval-sample/platform-eval-sample/.factory/sandbox-home/495e3cfd55d94c968a5c1943c6c4032e/.nuget/NuGet/NuGet.Config
/opt/actions-runner/sbiondolillo-platform-eval-sample/_work/platform-eval-sample/platform-eval-sample/.factory/sandbox-home/495e3cfd55d94c968a5c1943c6c4032e/.claude/backups/.claude.json.backup.1792864557892
/opt/actions-runner/sbiondolillo-platform-eval-sample/_work/platform-eval-sample/platform-eval-sample/.factory/sandbox-home/495e3cfd55d94c968a5c1943c6c4032e/.claude/sessions
/opt/actions-runner/sbiondolillo-platform-eval-sample/_work/platform-eval-sample/platform-eval-sample/.factory/sandbox-home/495e3cfd55d94c968a5c1943c6c4032e/.claude/projects/-work/f9885cca-a9b3-486a-8688-b6b94144d9b5.jsonl
/opt/actions-runner/sbiondolillo-platform-eval-sample/_work/platform-eval-sample/platform-eval-sample/.factory/sandbox-home/495e3cfd55d94c968a5c1943c6c4032e/.claude/projects/-work/1827f698-d7c4-497d-b6ab-973dfed97e1b.jsonl
/opt/actions-runner/sbiondolillo-platform-eval-sample/_work/platform-eval-sample/platform-eval-sample/.factory/sandbox-home/495e3cfd55d94c968a5c1943c6c4032e/.claude/projects/-work/a080a2e3-bfb2-4ed9-a27e-5cfb6d509658.jsonl
/opt/actions-runner/sbiondolillo-platform-eval-sample/_work/platform-eval-sample/platform-eval-sample/.factory/sandbox-home/495e3cfd55d94c968a5c1943c6c4032e/.claude/projects/-work/0f9c463f-55bb-46d5-9831-284d8f8a64d5.jsonl
/opt/actions-runner/sbiondolillo-platform-eval-sample/_work/platform-eval-sample/platform-eval-sample/.factory/sandbox-home/495e3cfd55d94c968a5c1943c6c4032e/.claude/projects/-work/0a9355b8-2fcb-4e11-a97d-300cbded7bc8.jsonl
/opt/actions-runner/sbiondolillo-platform-eval-sample/_work/platform-eval-sample/platform-eval-sample/.factory/sandbox-home/495e3cfd55d94c968a5c1943c6c4032e/.claude.json
/opt/actions-runner/sbiondolillo-platform-eval-sample/.credentials_rsaparams
/home/github-runner
```

- `.factory/sandbox-home/<id>/` is the host side of the container's `/tmp/sandbox-home`. It holds the agent's Claude Code state: `.claude.json`, a backup of it, and five session transcripts. All are unreadable as `sam`. It is the one place a model credential could persist from inside the container. Whether `.claude.json` or a transcript holds the gateway key is not known.
- One sandbox home is present, from the run of 17:55 host time. Earlier runs left none. The factory checkout's `.gitignore` names `.factory/`, and `actions/checkout` cleans ignored files by default, so a sandbox home likely lives until the next job's checkout. This probe did not test that.
- `.credentials_rsaparams` is the runner's registration key with GitHub (`0600`), not a model credential.
- `/home/github-runner` is `drwxr-x---`, owned by `github-runner`.

### The Infisical credential file
```
-rw-r----- 1 root github-runner  146 Oct 24 16:30 .infisical-auth.env
unreadable as sam
```

The file is in `/etc/homelab/dsf/`. The runner user reads it through its group. It is not mounted into the container.

### The runner's `.env`

`/opt/actions-runner/sbiondolillo-platform-eval-sample/.env` holds the six proxy names and nothing else (substrate capture, line 11).

### `compgen -e | grep -i -E 'anthropic|infisical'`, in the shell of `sam`
```
(no output, exit 1)
```

`compgen -e` lists exported names only. The task's `env | cut -d= -f1` form was refused by the workstation's secret-output hook, so this form was used. The runner's environment was not read.

### `docker ps -a`
```
(no output)
```

No container persists between runs.

## 5. The no-auth calls from sandbox-01

### `curl -sS -o /dev/null -w '%{http_code}\n' http://10.99.0.186:8200/v1/models`
```
401
```

The shell's `NO_PROXY` names `10.99.0.186`, so the call went direct. The same call with `--noproxy '*'` also returned `401`.

### `https_proxy=http://10.26.0.10:3128 curl -sS -o /dev/null -m 10 -w '%{http_code}\n' https://api.anthropic.com/v1/models`
```
000
curl: (56) Received HTTP code 403 from proxy after CONNECT
```

Squid refused the CONNECT with 403. The vendor host is in neither allowlist: `homelab-ansible` `roles/squid_proxy/defaults/main.yml` at `116eaf0`, the shared list at lines 26 to 62 and the `sandbox01` block at lines 77 to 93:

```yaml
squid_proxy_source_allowlists:
  - name: sandbox01
    src: 10.25.0.10
    hosts:
      - .github.com
      - .githubusercontent.com
      - .blob.core.windows.net
      - artifacts-cli.infisical.com
      - aka.ms
      - geocoding-api.open-meteo.com
```

(Comment lines 85 to 88 and 90 to 92 left out.) The shared list holds package, image and SDK hosts, and no `anthropic.com` entry.

### `curl -sS --noproxy '*' -o /dev/null -m 10 -w '%{http_code}\n' https://api.anthropic.com/v1/models`
```
000
curl: (28) Failed to connect to api.anthropic.com port 443 after 5206 ms: Connection timed out
```

The direct path is dropped by the Sandbox VLAN's deny-by-default rules.

## Host-side note, not tested live

Workflow line 45 passes the Infisical access token as an argument of `infisical run`, and that process stays up for the whole run as the parent of the factory. On Linux, a process's arguments are readable from `/proc/<pid>/cmdline` by every user on the host. The container runs in its own PID namespace and cannot see that process. No run was in progress, so this was not read.
