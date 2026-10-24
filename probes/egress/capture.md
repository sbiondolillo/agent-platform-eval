# Capture: egress probe, Cloud session

Probe [egress](../../docs/plan.md). Session "Egress probe" on sbiondolillo/platform-eval-sample, model Sonnet 5.5, environment agent-platform-eval. Taken 2026-10-24 at about 23:25 UTC. Prompt: [`prompt.md`](prompt.md). The environment's Network access was "Limited" with "Allow package managers" on, and two allowed domains: `geocoding-api.open-meteo.com` and `webhook.site`. The session's reply is pasted below unedited.

## 1. `curl … 'https://geocoding-api.open-meteo.com/v1/search?name=Boston&count=1'`
```
allowed host: 200
```

## 2. `curl … https://open-meteo.com/ ; echo "exit=$?"`
```
curl: (56) CONNECT tunnel failed, response 403
apex of allowed host: 000
exit=56
```

## 3. `curl -sS -m 20 -D - https://example.com/ ; echo "exit=$?"`
```
HTTP/1.1 403 Forbidden
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Content-Length: 69
Connection: close

curl: (56) CONNECT tunnel failed, response 403
exit=56
```

## 4. `curl … https://1.1.1.1/ ; echo "exit=$?"`
```
curl: (56) CONNECT tunnel failed, response 403
raw ip: 000
exit=56
```

## 5. `curl … https://geocoding-api.open-meteo.com:8443/ ; echo "exit=$?"`
```
curl: (35) Recv failure: Connection reset by peer
port 8443: 000
exit=35
```

## 6. `curl … http://example.com/ ; echo "exit=$?"`
```
curl: (6) Could not resolve host: example.com
plain http: 000
exit=6
```

## 7. `curl … https://registry.npmjs.org/left-pad/latest`
```
package manager: 200
```

## 8. `curl … --noproxy '*' … https://example.com/ ; echo "exit=$?"`
```
curl: (6) Could not resolve host: example.com
bypass proxy: 000
exit=6
```

## 9. `getent hosts example.com; echo "dns exit=$?"; timeout 10 bash -c 'cat < /dev/null > /dev/tcp/93.184.215.14/443'; echo "direct tcp 443 exit=$?"`
```
dns exit=2
direct tcp 443 exit=0
```

## 10. `curl -sS -m 20 "http://127.0.0.1:${HTTPS_PROXY##*:}/" 2>&1 | head -20`
```
agent-proxy relay: this proxy only accepts HTTPS CONNECT tunnels. Plain-HTTP/absolute-form requests are not supported — common causes are axios releases before 1.16.1 (broken HTTPS proxy handling) or a tool configured with HTTP_PROXY pointing at this relay.
GET /__agentproxy/status on this proxy port shows proxy state and recent failures.
```

## Summary

| Request | Result | Where the block came from |
|---|---|---|
| 1. Allowed host (`geocoding-api.open-meteo.com`) | 200 | No block |
| 2. Apex of allowed host (`open-meteo.com`) | 403, curl exit 56 | Proxy response (CONNECT refused) |
| 3. `example.com` over HTTPS | 403, curl exit 56 | Proxy response (CONNECT refused) |
| 4. Raw IP (`1.1.1.1`) | 403, curl exit 56 | Proxy response (CONNECT refused) |
| 5. Allowed host on port 8443 | Connection reset, curl exit 35 | Proxy (it dropped the tunnel). I can't tell from the output whether the proxy or something upstream sent the reset. |
| 6. Plain HTTP to `example.com` | Could not resolve host, curl exit 6 | DNS (the sandbox has no resolver of its own) |
| 7. Package manager (`registry.npmjs.org`) | 200 | No block |
| 8. `--noproxy '*'` to `example.com` | Could not resolve host, curl exit 6 | DNS |
| 9a. `getent hosts example.com` | No answer, exit 2 | DNS |
| 9b. Direct TCP to `93.184.215.14:443` | Connected, exit 0 | No block. The sandbox let the TCP handshake through. |
| 10. Plain HTTP to the proxy port | Relay message: only HTTPS CONNECT tunnels accepted | Proxy response |

Result 9b is the odd one. It only shows that the TCP handshake completed, and I sent no data. I didn't check whether that address is still `example.com`, or whether anything beyond the handshake would get through.

The policy lets HTTPS CONNECT tunnels through the proxy to approved hostnames on port 443 only. The two hosts that passed were the exact Open-Meteo geocoding host and `registry.npmjs.org`. Everything else was refused: other hostnames (including the apex of an allowed host), raw IPs, non-standard ports, plain HTTP, and DNS outside the proxy.

## Follow-up on 9b, same session

The prompt's second message ([`prompt.md`](prompt.md), Message 2). The session's reply is pasted below unedited.

## 1. `cat /proc/net/route`
```
Iface	Destination	Gateway 	Flags	RefCnt	Use	Metric	Mask		MTU	Window	IRTT
eth0	00000000	010200C0	0003	0	0	0	00000000	0	0	0
eth0	000200C0	00000000	0001	0	0	0	00FFFFFF	0	0	0
```
The addresses are little-endian hex. The default route goes via `C0.00.02.01`, which is 192.0.2.1, on `eth0`. The only other route is the local 192.0.2.0/24 network.

## 2. `timeout 10 bash -c 'exec 3<>/dev/tcp/93.184.215.14/443; printf "GET / HTTP/1.0\r\n\r\n" >&3; head -c 300 <&3 | od -c | head -5'; echo "exit=$?"`
```
0000000   H   T   T   P   /   1   .   1       4   2   6       U   p   g
0000020   r   a   d   e       R   e   q   u   i   r   e   d  \r  \n   c
0000040   o   n   t   e   n   t   -   l   e   n   g   t   h   :       1
0000060   6  \r  \n   c   o   n   t   e   n   t   -   t   y   p   e   :
0000100       t   e   x   t   /   p   l   a   i   n  \r  \n   d   a   t
exit=0
```

## 3. `curl -sS -m 20 --noproxy '*' --resolve example.com:443:93.184.215.14 -o /dev/null -w 'direct tls: %{http_code}\n' https://example.com/; echo "exit=$?"`
```
direct tls: 403
exit=0
```

## 4. `timeout 10 bash -c 'cat < /dev/null > /dev/tcp/192.0.2.1/9'; echo "gateway port 9 exit=$?"; timeout 10 bash -c 'cat < /dev/null > /dev/tcp/8.8.8.8/53'; echo "8.8.8.8:53 exit=$?"`
```
bash: connect: Connection refused
bash: line 1: /dev/tcp/192.0.2.1/9: Connection refused
gateway port 9 exit=1
8.8.8.8:53 exit=124
```

## What these show

- **Port 443:** The reply to a plain `GET` was `HTTP/1.1 426 Upgrade Required` with a 16-byte `text/plain` body, and a real `example.com` server would not send that. Over TLS the same direct path returned a 403. The 403 body wasn't printed, and I didn't inspect the certificate.
- **Other ports:** 192.0.2.1:9 got an immediate refusal, and 8.8.8.8:53 timed out with no answer (exit 124), so it was dropped. This is consistent with only port 443 being intercepted, though I tested just these two other ports.

A direct connection to port 443 carries data only to the gateway, which accepts the handshake and answers itself (a 426 in plain text, a 403 over TLS), so nothing reaches the real destination. The 9b connect was that same gateway accepting the handshake.
