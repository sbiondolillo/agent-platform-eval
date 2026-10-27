# Vault-secret probe prompt

Cloud session on sbiondolillo/platform-eval-sample, model Sonnet 5.5 in the picker, environment agent-platform-eval with a Network secret for webhook.site, header X-Probe-Secret. Pasted as the first message. `<UUID>` is the webhook.site id.

```
Check that the network secret I configured for webhook.site works. Do not change any file, do not commit, do not push, do not create a branch. Print no secret value. Run each numbered line as one shell call and paste its full output under a heading that shows the command.

1. env | cut -d= -f1 | grep -i -E 'probe|webhook'; echo "exit=$?"
2. grep -rIl 'X-Probe-Secret' / --exclude-dir=proc --exclude-dir=sys --exclude-dir=dev 2>/dev/null | head
3. curl -sS -D - -o /dev/null -w 'status=%{http_code}\n' "https://webhook.site/<UUID>?arm=cloud"
4. curl -sS -v -o /dev/null "https://webhook.site/<UUID>?arm=cloud-verbose" 2>&1 | grep -E '^(> |< HTTP|\* (Proxy|Connected|Establish))'

End with one sentence: whether the secret value is visible anywhere inside the sandbox, and whether the request left the sandbox with the header.
```

## Managed Agents

Setup by `POST /v1/vaults`, then `POST /v1/vaults/{id}/credentials` with `auth.type: environment_variable`, `secret_name: PROBE_SECRET`, `networking.allowed_hosts: [webhook.site]` and `injection_location: {header: true}`, an environment with `allowed_hosts: [webhook.site]`, and a session with `vault_ids`. The message asked for the variable's presence and length, one `curl` to the inbox with the variable in a header, one to a host outside the credential's list, and the verbose request line. The model-side safeguard refused it before any command ran, so the message is not reproduced here; the session's events hold it.
