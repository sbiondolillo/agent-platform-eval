# Capture: vault-secret probe, Cloud session

Probe [vault-secret](../../docs/plan.md). Session "Vault secret probe" on sbiondolillo/platform-eval-sample, model Sonnet 5.5, environment agent-platform-eval. Taken 2026-10-24 at 23:07 UTC. The webhook.site clock showed 7:07:25 PM, local time, and the response `Date` header reads 23:07:25 GMT. Prompt: [`prompt.md`](prompt.md). The secret value is a throwaway string of the form `probe-20261024-xxxxxxxx`. It was made with `openssl rand` on the workstation and used only for this probe.

## The environment dialog

The environment's "Add secret" dialog has these fields:

- Add to: the environment.
- Secret type: Bearer, Basic, Body parameter, AWS SigV4, GCP access token (with Service Account Key), GCP IAP (with Service Account Key), OAuth 2.0 JWT bearer, OAuth 2.0 client credentials, MCP Connector.
- Allowed websites, with the note "Claude will only send this app's keys to these websites. To allow all subdomains, use * at the start (*.example.com)."
- Path prefixes (optional), with the note "Narrow the auto-created allow rule to requests under these paths. Leave empty to allow the whole host."
- Custom headers: rows of Header name, Prefix, Value, with the note "Added to every request Claude sends to the allowed websites."
- A "See resolved curl example" expander.

The operator set Secret type Bearer, Allowed websites `webhook.site`, and one custom header `X-Probe-Secret` with no prefix and the throwaway value.

## The session's reply, unedited

I ran the four commands as written, with no file changes, commits, pushes or branches. Every output is below.

### 1. `env | cut -d= -f1 | grep -i -E 'probe|webhook'; echo "exit=$?"`
```
exit=1
```

### 2. `grep -rIl 'X-Probe-Secret' / --exclude-dir=proc --exclude-dir=sys --exclude-dir=dev 2>/dev/null | head`
```
/root/.claude/projects/-home-user-platform-eval-sample/8bfde5bb-00c7-51e8-b4ed-8f6014a3c2c2.jsonl
```

### 3. `curl -sS -D - -o /dev/null -w 'status=%{http_code}\n' "https://webhook.site/80a5562a-8c52-4065-ba51-a1ae4a47bbd8?arm=cloud"`
```
HTTP/1.1 200 Connection Established

HTTP/1.1 200 OK
Connection: close
Transfer-Encoding: chunked
Cache-Control: no-cache, private
Content-Security-Policy: signup-to-remove-csp-header 'webhook.site/register'; base-uri 'self'; form-action 'none'; script-src 'none'; worker-src 'none'; frame-src 'none';
Content-Type: text/html; charset=UTF-8
Date: Sat, 24 Oct 2026 23:07:25 GMT
Server: nginx
X-Request-Id: 5a8313b6-80f1-430e-8cdc-f849f0ce38cc
X-Token-Id: 80a5562a-8c52-4065-ba51-a1ae4a47bbd8

status=200
```

### 4. `curl -sS -v -o /dev/null "https://webhook.site/80a5562a-8c52-4065-ba51-a1ae4a47bbd8?arm=cloud-verbose" 2>&1 | grep -E '^(> |< HTTP|\* (Proxy|Connected|Establish))'`
```
* Connected to 127.0.0.1 (127.0.0.1) port 46827
* Establish HTTP proxy tunnel to webhook.site:443
> CONNECT webhook.site:443 HTTP/1.1
> Host: webhook.site:443
> User-Agent: curl/8.5.0
> Proxy-Connection: Keep-Alive
> 
< HTTP/1.1 200 Connection Established
> GET /80a5562a-8c52-4065-ba51-a1ae4a47bbd8?arm=cloud-verbose HTTP/1.1
> Host: webhook.site
> User-Agent: curl/8.5.0
> Accept: */*
> 
< HTTP/1.1 200 OK
```

The secret value is not visible anywhere in the sandbox: no matching env var names, and the only file containing `X-Probe-Secret` is this session's own transcript, which holds your command text. The request did reach webhook.site (HTTP 200, `X-Token-Id` echoed), but the outgoing request I can see carries no `X-Probe-Secret` header. So I can't confirm from inside the sandbox that the header was added on the way out. The webhook.site request log for the `arm=cloud` and `arm=cloud-verbose` hits will show whether it was.

## What webhook.site showed

The inbox listed two GET requests at 10/24/2026 7:07:25 PM from 160.79.106.129 (San Francisco, a vendor egress address). The request with query string `arm=cloud`, id 5a8313b6-80f1-430e-8cdc-f849f0ce38cc, carried these headers:

| Header | Value |
|---|---|
| x-probe-secret | the throwaway value, in full |
| accept | `*/*` |
| user-agent | `curl/8.5.0` |
| host | `webhook.site` |

The request id matches the `X-Request-Id` in the session's step 3 output. The header the VM never sent arrived at the endpoint. The local proxy at 127.0.0.1 terminated TLS with its own CA and added it.
