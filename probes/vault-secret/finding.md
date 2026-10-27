# Vault secret

Probe for [issue #2](../../docs/plan.md). Question: where the key is attached. The answer sets whether the agent can read a secret that its requests need, in each arm of the DSF v2 decision. The same throwaway value went to the same webhook.site inbox from both arms. No file in this repo holds it.

## Cloud Sessions

The operator added the secret in the environment's "Add secret" dialog. The dialog offers nine secret types, from Bearer to MCP Connector, and each secret creates an allow rule for its websites, with optional path prefixes ([`capture.md`](capture.md)). Inside the VM, no environment variable name matches, and the only file that names the header is the session's own transcript of the prompt. The verbose curl shows the request leave curl through the local proxy at `127.0.0.1` with no `X-Probe-Secret` header. The proxy terminated TLS with its own CA and added the header, and webhook.site received the header with the full value from 160.79.106.129, a vendor egress address. The value is attached on the proxy path, after the request leaves the agent's command, and no variable or file in the VM holds it, so the agent cannot read it.

## Platform

Infisical holds the secret as `PROBE_SECRET` in the `dsf` project, environment `prod`, next to the factory's own secrets ([`capture-platform.md`](capture-platform.md)). The probe job logs in with the runner host's machine identity, the same as `factory.yml`, and `infisical run` puts the secret into the environment of the job's command. The log shows "Injecting 3 Infisical secrets", so the command got every secret of that environment, not only the probe's. The factory process and any command under it can read the value: the probe printed its length, 23, and curl attached the header itself. The request left through Squid on `egress-01` and reached webhook.site from 163.252.201.8, the lab's WAN address, with the header. The agent's container sees only the names that DSF `src/Core/Sandbox.cs` lists and the run's `--pass-env` names ([`../substrate/capture-platform.md`](../substrate/capture-platform.md)), so a vault secret reaches the agent only if the factory passes it by name. The Squid allowlist had to be widened by hand for `webhook.site`, the same as both delivery runs needed for `geocoding-api.open-meteo.com`.

## Comparison

| row | Cloud Sessions | Platform |
|---|---|---|
| where the secret is stored | in the Cloud environment, entered in the "Add secret" dialog | in Infisical, project `dsf`, environment `prod`, root path |
| where the value is attached to the request | on the managed proxy path, after the request leaves curl. The VM's own request carries no header. | in the runner job. `infisical run` puts the value in the command's environment, and curl sets the header. |
| can the agent process read the value | no. No variable or file in the VM holds it. | the factory process and every command under `infisical run` can. The agent's container can only if the factory passes the name with `--pass-env`. |
| scope of the allow rule | per secret: the allowed websites, with optional path prefixes. The header goes only to those hosts. | per source address: the Squid allowlist for `sandbox-01`, by host only, because Squid tunnels TLS. The secret has no host binding: the script can send it to any allowed host. |
| credential types the vault can attach | nine: Bearer, Basic, Body parameter, AWS SigV4, GCP access token, GCP IAP, OAuth 2.0 JWT bearer, OAuth 2.0 client credentials, MCP Connector | any string. The vault attaches nothing: the script does, so a signing or token-exchange scheme is code the factory owner writes. |
| operator steps for this probe | 2, in one dialog: add the secret, with its allowed website and header | 4: add the secret in Infisical, widen the Squid allowlist, merge the workflow, dispatch it |

## Managed Agents

Probed 2026-10-27 in session `sesn_01C1A32W15PjyYNbwrrh9i1Q`. Docs: https://platform.claude.com/docs/en/managed-agents/vaults. The setup half is proven: vault `vlt_011CgSweaXP6wbjoudWr23MV` was created, credential `vcrd_01DAWx7tYLhraGohWcwQUgxD` of type `environment_variable` was accepted with its `allowed_hosts` and `injection_location`, the create response did not echo the value, environment `env_01D7JiCajKVLmAFKLAwSFLNm` allows `webhook.site`, and the session was created with `vault_ids` set. The attachment half is not: the model-side safeguard refused the message before any command ran, `stop_details.type: refusal`, `category: cyber`, 0 cents, and the inbox received no request. The message was the Cloud arm's probe, one `curl` with the variable in a header, and on the Cloud arm the same shape ran. The probe was not reworded, so the cell rests on the docs: the sandbox holds an opaque placeholder under `PROBE_SECRET`, and the value is substituted at egress for the credential's `allowed_hosts` only. A reworded probe is the operator's call, with the Cloud arm's forge-credential precedent, where a second framing was answered.

## Report cells

Cloud: the managed proxy attaches the secret on the way out and only to its allowed hosts, so the agent's VM never holds a value it can read.

Platform: `infisical run` puts the secret in the runner job's environment, so the factory process can read it and must attach it itself, and the agent's container gets it only when the factory passes it by name.

Managed Agents: the docs put the value on the egress path for the credential's listed hosts, with a placeholder in the sandbox; the vault and the binding were accepted, and the one-request test was refused by the model-side safeguard.
