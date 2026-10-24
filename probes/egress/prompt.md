# Egress probe prompt

Cloud session "Egress probe" on sbiondolillo/platform-eval-sample, model Sonnet 5.5 in the picker, environment agent-platform-eval with Network access Limited, package managers allowed, allowed domains geocoding-api.open-meteo.com and webhook.site. Two messages.

## Message 1

```
Check what the sandbox network policy returns for each kind of request. Do not change any file, do not commit, do not push, do not create a branch. Run each numbered line as one shell call and paste its full output under a heading that shows the command.

1. curl -sS -o /dev/null -m 20 -w 'allowed host: %{http_code}\n' 'https://geocoding-api.open-meteo.com/v1/search?name=Boston&count=1'
2. curl -sS -o /dev/null -m 20 -w 'apex of allowed host: %{http_code}\n' https://open-meteo.com/ ; echo "exit=$?"
3. curl -sS -m 20 -D - https://example.com/ ; echo "exit=$?"
4. curl -sS -o /dev/null -m 20 -w 'raw ip: %{http_code}\n' https://1.1.1.1/ ; echo "exit=$?"
5. curl -sS -o /dev/null -m 20 -w 'port 8443: %{http_code}\n' https://geocoding-api.open-meteo.com:8443/ ; echo "exit=$?"
6. curl -sS -o /dev/null -m 20 -w 'plain http: %{http_code}\n' http://example.com/ ; echo "exit=$?"
7. curl -sS -o /dev/null -m 20 -w 'package manager: %{http_code}\n' https://registry.npmjs.org/left-pad/latest
8. curl -sS -o /dev/null -m 20 --noproxy '*' -w 'bypass proxy: %{http_code}\n' https://example.com/ ; echo "exit=$?"
9. getent hosts example.com; echo "dns exit=$?"; timeout 10 bash -c 'cat < /dev/null > /dev/tcp/93.184.215.14/443'; echo "direct tcp 443 exit=$?"
10. curl -sS -m 20 "http://127.0.0.1:${HTTPS_PROXY##*:}/" 2>&1 | head -20

End with a table: request, result, and where the block came from (proxy response, DNS, or TCP). Then one sentence on what the policy allows.
```

## Message 2

```
Follow up on 9b. Run each line as one shell call and paste its full output.

1. cat /proc/net/route
2. timeout 10 bash -c 'exec 3<>/dev/tcp/93.184.215.14/443; printf "GET / HTTP/1.0\r\n\r\n" >&3; head -c 300 <&3 | od -c | head -5'; echo "exit=$?"
3. curl -sS -m 20 --noproxy '*' --resolve example.com:443:93.184.215.14 -o /dev/null -w 'direct tls: %{http_code}\n' https://example.com/; echo "exit=$?"
4. timeout 10 bash -c 'cat < /dev/null > /dev/tcp/192.0.2.1/9'; echo "gateway port 9 exit=$?"; timeout 10 bash -c 'cat < /dev/null > /dev/tcp/8.8.8.8/53'; echo "8.8.8.8:53 exit=$?"

End with one sentence: does a direct connection carry data, or does the gateway accept the handshake and drop the rest.
```
