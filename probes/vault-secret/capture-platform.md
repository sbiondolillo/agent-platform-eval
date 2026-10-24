# Capture: vault-secret probe, platform arm

Probe [vault-secret](../../docs/plan.md), platform side. GitHub Actions run 40141723638 in `sbiondolillo/platform-eval-sample`, on the self-hosted runner `sandbox-01`. Taken 2026-10-24 at 23:11 UTC. The Cloud side is in [`capture.md`](capture.md). The secret value is the same throwaway string as on the Cloud side, of the form `probe-20261024-xxxxxxxx`. No file in this repo holds it.

## Setup

The operator did four steps:

1. Added the secret `PROBE_SECRET` by hand in Infisical: project `dsf`, environment `prod`, root path. This is the project that holds the factory's own secrets.
2. Widened the Squid allowlist on `egress-01` for `webhook.site` (see below).
3. Merged [PR 7](https://github.com/sbiondolillo/platform-eval-sample/pull/7) (squash), which adds the workflow below.
4. Dispatched the workflow with input `url=https://webhook.site/80a5562a-8c52-4065-ba51-a1ae4a47bbd8`.

## Squid allowlist

The sandbox-01 source allowlist in `homelab-ansible` `roles/squid_proxy/defaults/main.yml` got one host, `webhook.site`, in commit `a17bb31`. The playbook recap showed `egress-01 ok=5 changed=2`. A request from `sandbox-01` through `10.26.0.10:3128` to `webhook.site` then returned 200. Without this step, Squid denies the probe's request.

## The workflow

`.github/workflows/probe-vault-secret.yml` on `main` after PR 7:

```yaml
# The vault-secret probe of agent-platform-eval, platform arm.
# The job reads PROBE_SECRET from the dsf Infisical project with the same login and `infisical run` call as factory.yml, and curl sends it as the X-Probe-Secret header.
# webhook.site shows the request headers, which is the proof. The job prints the presence and length of the value, never the value.
# The runner's .env gives the job https_proxy, as it does for factory.yml. The operator deletes this file at teardown.
name: "Probe: vault secret"

on:
  workflow_dispatch:
    inputs:
      url:
        description: webhook.site URL to call
        required: true
        type: string

permissions:
  contents: read

jobs:
  probe:
    runs-on: [self-hosted, dsf]
    steps:
      - name: Send the secret as a header
        env:
          PROBE_URL: ${{ inputs.url }}
        run: |
          set -euo pipefail
          set -a; . /etc/homelab/dsf/.infisical-auth.env; set +a
          DOMAIN="https://infisical-api.sambiondolillo.com/api"
          TOKEN=$(infisical login --method=universal-auth --client-id="$INFISICAL_CLIENT_ID" --client-secret="$INFISICAL_CLIENT_SECRET" --domain="$DOMAIN" --silent --plain)
          exec infisical run --token="$TOKEN" --projectId="${{ vars.INFISICAL_PROJECT_ID }}" --domain="$DOMAIN" --env=prod -- \
            sh -c 'echo "PROBE_SECRET present: $([ -n "$PROBE_SECRET" ] && echo yes || echo no), length ${#PROBE_SECRET}"; curl -sS -D - -o /dev/null -w "status=%{http_code}\n" -H "X-Probe-Secret: $PROBE_SECRET" "$PROBE_URL?arm=platform"'
```

The login and the `infisical run` call are the same as in the target's `factory.yml`.

## Run

`gh run view 40141723638 --repo sbiondolillo/platform-eval-sample --json conclusion,createdAt,updatedAt`:

| Field | Value |
|---|---|
| conclusion | `success` |
| event | `workflow_dispatch` |
| createdAt | 2026-10-24T23:11:44Z |
| updatedAt | 2026-10-24T23:11:50Z |
| runner | `sandbox-01`, behind proxy `http://10.26.0.10:3128` for HTTP and HTTPS |

## Log of the probe step

From `gh run view 40141723638 --repo sbiondolillo/platform-eval-sample --log`, step "Send the secret as a header", the lines after the echoed script. Timestamps are cut.

```
INF Injecting 3 Infisical secrets into your application process
PROBE_SECRET present: yes, length 23
HTTP/1.1 200 Connection established

HTTP/2 200 
server: nginx
content-type: text/html; charset=UTF-8
x-request-id: 9de6b92d-48f7-47fc-9ada-8a3593700a22
x-token-id: 80a5562a-8c52-4065-ba51-a1ae4a47bbd8
content-security-policy: signup-to-remove-csp-header 'webhook.site/register'; base-uri 'self'; form-action 'none'; script-src 'none'; worker-src 'none'; frame-src 'none';
cache-control: no-cache, private
date: Sat, 24 Oct 2026 23:11:48 GMT

status=200
```

`infisical run` put three secrets into the environment of the command, not only `PROBE_SECRET`. The length 23 matches the shape of the throwaway value. The first status line is Squid's answer to `CONNECT`. The second is from webhook.site, through the tunnel.

The full log has 41 lines. It holds no secret value, and no `***`, so nothing was masked. The job printed only the presence and the length of the value. This probe does not test whether a printed value would be masked.

## What webhook.site showed

The inbox listed one GET request with query string `arm=platform` at 10/24/2026 7:11:48 PM (23:11:48 UTC) from 163.252.201.8 (Manchester, New Hampshire, the lab's WAN address), over http/2.0. Request id 9de6b92d-48f7-47fc-9ada-8a3593700a22.

| Header | Value |
|---|---|
| x-probe-secret | the throwaway value, in full, the same as the Cloud request |
| accept | `*/*` |
| user-agent | `curl/7.81.0` |
| host | `webhook.site` |

The request id matches the `x-request-id` in the job log. The runner job set the header itself, from the value in its own environment.
