# Capture: egress probe, platform arm

Probe [egress](../../docs/plan.md), platform arm. The ten requests of [`capture.md`](capture.md), run from a throwaway container on the self-hosted runner sandbox-01 (Sandbox VLAN, 10.25.0.10). Taken 2026-10-24 at about 23:16 UTC, over SSH as the operator account `sam`. All requests are read-only. The container exited with `--rm`. webhook.site was not called.

## The command

The container image is the factory's sandbox image, with the flags of the substrate capture ([`../substrate/capture-platform.md`](../substrate/capture-platform.md)): same image, `--user 997:998`, `--rm`, no mounts. The Docker client of `sam` has no proxy config, so the container did not inherit the proxy. The two proxy variables were set explicitly with `--env`. The proxy URL has no credentials. The ten requests ran as one script on stdin (`bash -s`). The image has curl and bash, so no request ran from the host shell.

```
docker run --rm -i --init --user 997:998 --workdir /work --env HOME=/tmp/sandbox-home --env https_proxy=http://10.26.0.10:3128 --env http_proxy=http://10.26.0.10:3128 dotnet-software-factory-sandbox bash -s < probe.sh
```

Every curl used `-m 20` and `-sS`; stderr was merged into stdout. Requests 1, 2, 4, 5, 7 and 8 add `-o /dev/null -w 'http=%{http_code}\n'`. Outputs are trimmed to the lines that answer the question: request 3 and 6 show the headers and the first lines of the proxy's HTML body, request 10 shows the first lines and the error text.

## 1. `curl -sS -m 20 'https://geocoding-api.open-meteo.com/v1/search?name=Boston&count=1'`
```
http=200
exit=0
```

## 2. `curl -sS -m 20 https://open-meteo.com/`
```
curl: (56) CONNECT tunnel failed, response 403
http=000
exit=56
```

## 3. `curl -sS -m 20 -D - https://example.com/`
```
HTTP/1.1 403 Forbidden
Server: squid/5.9
Mime-Version: 1.0
Date: Sat, 24 Oct 2026 23:16:17 GMT
Content-Type: text/html;charset=utf-8
Content-Length: 3067
X-Squid-Error: ERR_ACCESS_DENIED 0
Vary: Accept-Language
Content-Language: en
X-Cache: MISS from egress-01
X-Cache-Lookup: NONE from egress-01:3128
Via: 1.1 egress-01 (squid/5.9)
Connection: keep-alive

curl: (56) CONNECT tunnel failed, response 403
exit=56
```

## 4. `curl -sS -m 20 https://1.1.1.1/`
```
curl: (56) CONNECT tunnel failed, response 403
http=000
exit=56
```

## 5. `curl -sS -m 20 https://geocoding-api.open-meteo.com:8443/`
```
curl: (56) CONNECT tunnel failed, response 403
http=000
exit=56
```

## 6. `curl -sS -m 20 -D - http://example.com/`
```
HTTP/1.1 403 Forbidden
Server: squid/5.9
Mime-Version: 1.0
Date: Sat, 24 Oct 2026 23:16:17 GMT
Content-Type: text/html;charset=utf-8
Content-Length: 3063
X-Squid-Error: ERR_ACCESS_DENIED 0
Vary: Accept-Language
Content-Language: en
X-Cache: MISS from egress-01
X-Cache-Lookup: NONE from egress-01:3128
Via: 1.1 egress-01 (squid/5.9)
Connection: keep-alive

<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html><head>
<meta type="copyright" content="Copyright (C) 1996-2020 The Squid Software Foundation and contributors">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>ERROR: The requested URL could not be retrieved</title>
<style type="text/css"><!--
```

## 7. `curl -sS -m 20 https://registry.npmjs.org/left-pad/latest`
```
http=200
exit=0
```

The shared allowlist holds `.npmjs.org` (line 27 below).

## 8. `curl -sS -m 20 --noproxy '*' https://example.com/`
```
curl: (28) Connection timed out after 20001 milliseconds
http=000
exit=28
```

## 9. `getent hosts example.com; echo "dns exit=$?"; timeout 10 bash -c 'cat < /dev/null > /dev/tcp/93.184.215.14/443'; echo exit=$?`
```
2606:4700:10::ac42:93f3 example.com
2606:4700:10::6814:179a example.com
dns exit=0
exit=124
```

Exit 124 is the `timeout` kill: the TCP handshake did not complete in 10 seconds. The resolver answered with IPv6 addresses only. The IPv4 address `93.184.215.14` is the one the Cloud arm used. It is not known whether it is still `example.com`.

## 10. `curl -sS -m 20 http://10.26.0.10:3128/`
```
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html><head>
<meta type="copyright" content="Copyright (C) 1996-2020 The Squid Software Foundation and contributors">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>ERROR: The requested URL could not be retrieved</title>
<style type="text/css"><!--
...
</head><body id=ERR_ACCESS_DENIED>
<p>The following error was encountered while trying to retrieve the URL: <a href="http://10.26.0.10:3128/">http://10.26.0.10:3128/</a></p>
<p><b>Access Denied.</b></p>
<!-- ERR_ACCESS_DENIED -->
exit=0
```

Note on requests 6 and 10: curl's own exit code is 0 here, because the proxy's reply is a complete HTTP response (403) and `-f` was not set.

## Summary

| Request | Result | Where the block came from |
|---|---|---|
| 1. Allowed host (`geocoding-api.open-meteo.com`) | 200 | No block. Allowed by the `sandbox01` list (line 93) |
| 2. Apex of allowed host (`open-meteo.com`) | 403, curl exit 56 | Proxy response (Squid refused CONNECT) |
| 3. `example.com` over HTTPS | 403, curl exit 56 | Proxy response (`ERR_ACCESS_DENIED`, `squid/5.9`, `egress-01`) |
| 4. Raw IP (`1.1.1.1`) | 403, curl exit 56 | Proxy response (Squid refused CONNECT) |
| 5. Allowed host on port 8443 | 403, curl exit 56 | Proxy response (Squid refused CONNECT; no reset) |
| 6. Plain HTTP to `example.com` | 403 with Squid error page, curl exit 0 | Proxy response (`ERR_ACCESS_DENIED`) |
| 7. Package manager (`registry.npmjs.org`) | 200 | No block. Allowed by `.npmjs.org` (line 27) |
| 8. `--noproxy '*'` to `example.com` | Timed out after 20 s, curl exit 28 | Firewall (no direct path; a drop, not a refusal) |
| 9a. `getent hosts example.com` | Answered (two IPv6 addresses), exit 0 | No block. DNS works from the VLAN |
| 9b. Direct TCP to `93.184.215.14:443` | Timed out, exit 124 | Firewall (no direct path) |
| 10. Plain HTTP to the proxy port | 403 `ERR_ACCESS_DENIED` page | Proxy response |

The firewall attribution for 8 and 9b is an inference from the timeout and the rule below. The probe saw no firewall log.

## The firewall rule

`homelab-network/firewall_sandbox.tf`, rule `sandbox01_to_egress01_proxy` (lines 191 to 205): pass, TCP, source `10.25.0.10/32`, destination `10.26.0.10/32` on the `sandbox_egress_ports` alias, which is port `3128` (lines 154 to 159). The same file removes the old WAN rule: lines 253 to 256, "sandbox_to_wan (sequence 11999, Sandbox -> any) removed here (homelab#64): Sandbox's only path out is now sandbox_to_egress01_proxy above."

`homelab/docs/network.md`:
- Line 284: "Egress is closed as of 2026-08-27 (`#64`)."
- Line 257: "`sandbox-01` → `egress-01:3128` (`sandbox_egress_ports`) | Squid, the VM's only path to the WAN."
- Line 437: `sandbox-01` → `egress-01` :3128 is a permit.
- Line 438: "Sandbox → WAN | **Deny** | Closed 2026-08-27 ... The two rows above are now the only paths out."

VLAN 25 may not reach the internet except through `10.26.0.10:3128`.

## Squid allowlist for sandbox01

`homelab-ansible/roles/squid_proxy/defaults/main.yml`, `squid_proxy_source_allowlists`, entry `sandbox01`, `src: 10.25.0.10` (lines 77 to 97). These hosts apply to that source only, on top of the shared list (lines 26 to 62).

```
 77  squid_proxy_source_allowlists:
 78    - name: sandbox01
 79      src: 10.25.0.10
 80      hosts:
 81        - .github.com
 82        - .githubusercontent.com
 83        - .blob.core.windows.net
 84        - artifacts-cli.infisical.com
 89        - aka.ms
 93        - geocoding-api.open-meteo.com
 97        - webhook.site
```

Lines 85 to 88, 90 to 92 and 94 to 96 are comments. Line 93 is the host of request 1. Line 97 is the webhook.site host: this entry is temporary and the teardown commit of the experiment removes it (comment lines 94 to 96). The shared list holds `.npmjs.org` at line 27.
