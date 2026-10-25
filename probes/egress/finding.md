# Egress

Probe for [issue #2](../../docs/plan.md). Question: what the proxy returns for each request. The answer sets which network control holds the agent in each arm of the DSF v2 decision. Both arms ran the same ten requests, and the Cloud arm ran four follow-up requests on its direct path.

## Cloud Sessions

The session's traffic goes through a relay at `127.0.0.1` that accepts only HTTPS CONNECT tunnels, and the relay allows a tunnel by exact hostname ([`capture.md`](capture.md)). The allowed host answered 200, but its apex `open-meteo.com`, `example.com` and the raw IP `1.1.1.1` got a 403 on CONNECT, and the allowed host on port 8443 got a connection reset. Plain HTTP and `--noproxy` failed with "Could not resolve host", because the VM has no DNS resolver, and `registry.npmjs.org` answered 200 because the package manager toggle allows it. A direct TCP connection to port 443 completes, but the default gateway at 192.0.2.1 intercepts it and answers itself: a 426 in plain text and a 403 over TLS. Direct connections to other ports were refused (192.0.2.1:9) or dropped (8.8.8.8:53). The control is the relay plus the gateway, and the VM has no DNS to find a path around them.

## Platform

The container's traffic goes to Squid on `egress-01`, which allows hosts per source address: a shared list plus the `sandbox01` list for the runner VM ([`capture-platform.md`](capture-platform.md)). The allowed host answered 200, and `registry.npmjs.org` answered 200 because the operator put `.npmjs.org` on the shared list by hand. Every refusal is a Squid 403 `ERR_ACCESS_DENIED` page: the apex, `example.com` over HTTPS and over plain HTTP, the raw IP, port 8443, and a request to the proxy port itself. DNS answers inside the VLAN, but a direct connection, by `--noproxy` or by raw TCP to port 443, times out. The firewall rule for the Sandbox VLAN drops all traffic to the WAN, and the timeouts agree with that rule, but the probe saw no firewall log. The control is Squid plus the firewall drop, and DNS is not part of it.

## Comparison

| Request | Cloud Sessions | Platform |
|---|---|---|
| 1. allowed host `geocoding-api.open-meteo.com` | 200 | 200 |
| 2. apex `open-meteo.com` | 403 on CONNECT, from the relay | 403 on CONNECT, from Squid |
| 3. `example.com` over HTTPS | 403 on CONNECT, 69-byte `text/plain` body | 403 on CONNECT, Squid `ERR_ACCESS_DENIED` page |
| 4. raw IP `1.1.1.1` | 403 on CONNECT | 403 on CONNECT |
| 5. allowed host on port 8443 | connection reset, curl exit 35 | 403 on CONNECT |
| 6. plain HTTP to `example.com` | "Could not resolve host", curl exit 6 | 403, Squid `ERR_ACCESS_DENIED` page |
| 7. package manager `registry.npmjs.org` | 200, allowed by the package manager toggle | 200, allowed by `.npmjs.org` on the shared list, added by hand |
| 8. `--noproxy '*'` to `example.com` | "Could not resolve host", curl exit 6 | timed out after 20 s, curl exit 28 |
| 9. DNS lookup, then direct TCP connect to `93.184.215.14:443` | no DNS answer (exit 2), connect completes (exit 0) | DNS answers with two IPv6 addresses, connect times out (exit 124) |
| 10. plain HTTP to the proxy port | relay text: only HTTPS CONNECT tunnels accepted | 403, Squid `ERR_ACCESS_DENIED` page |
| 11. direct port 443 with data (follow-up) | the gateway at 192.0.2.1 answers itself: 426 to a plain `GET`, 403 over TLS | not run. The connect of row 9 already times out. |
| 12. direct port other than 443 (follow-up) | 192.0.2.1:9 refused, 8.8.8.8:53 dropped (exit 124) | not run. The firewall rule drops Sandbox traffic to the WAN on every port. |

Two differences matter for DSF v2. First, the allow rule: Cloud Sessions allows an exact hostname set in the environment, with a toggle for package managers, while the platform allows hosts per source address on a Squid list that the operator edits by hand for each new host. Second, the direct path: Cloud Sessions intercepts direct port 443 at its gateway, which accepts the handshake and answers itself, while the platform drops the connection at the firewall. Both stop the data, but on Cloud Sessions a test that checks only the TCP handshake reports the path as open.

## Report cells

Cloud: a local relay tunnels HTTPS only to exact allowed hostnames on port 443, and the gateway intercepts every direct port 443 connection and answers it itself, so no request reaches the internet except through the relay.

Platform: Squid tunnels only to the hosts on the runner's per-source allowlist, which the operator edits by hand, and the firewall drops every direct connection, so Squid is the only path out.
