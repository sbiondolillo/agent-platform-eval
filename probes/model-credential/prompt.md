# Model-credential probe prompt

Cloud session on sbiondolillo/platform-eval-sample, model Sonnet 5.5 in the picker, environment agent-platform-eval, issue #2. Pasted as the first message.

```
This is a read-only probe of the sandbox you run in. Do not change any file, do not commit, do not push, do not create a branch. Never print the value of any variable, file or header that could be a secret. Print names, lengths, known prefixes and file paths only. Run each numbered line as one shell call and paste its full output under a heading that shows the command.

1. env | cut -d= -f1 | grep -i -E 'anthropic|claude|api_key|token|secret|aws|cloudsdk|proxy' | sort
2. for v in $(env | cut -d= -f1 | grep -E 'KEY|TOKEN|SECRET'); do val="${!v}"; p=""; case "$val" in sk-ant-*) p=sk-ant-;; AKIA*) p=AKIA;; ASIA*) p=ASIA;; ghp_*) p=ghp_;; ghs_*) p=ghs_;; ghu_*) p=ghu_;; github_pat_*) p=github_pat_;; ya29.*) p=ya29.;; esac; echo "$v len=${#val} prefix=${p:-none}"; done
3. echo "$ANTHROPIC_BASE_URL"; echo "$HTTPS_PROXY" | sed -E 's#//[^@/]*@#//***@#'; echo "$NO_PROXY"
4. grep -rIl -E 'sk-ant-|ANTHROPIC_API_KEY' / --exclude-dir=proc --exclude-dir=sys --exclude-dir=dev 2>/dev/null | head -20
5. ls -la ~ ~/.claude ~/.config 2>&1; test -f ~/.claude.json && python3 -c "import json;print(sorted(json.load(open('$HOME/.claude.json')).keys()))"
6. test -f "$CLAUDE_SESSION_INGRESS_TOKEN_FILE" && echo "ingress token file exists, $(wc -c < "$CLAUDE_SESSION_INGRESS_TOKEN_FILE") bytes" || echo "no ingress token file"
7. ps -eo pid,user,comm --sort=pid | tail -n +40 | head -40
8. getent hosts api.anthropic.com; curl -sS -o /dev/null -w 'no-auth-header: %{http_code}\n' https://api.anthropic.com/v1/models; curl -sS -o /dev/null -w 'base-url-no-auth: %{http_code}\n' "$ANTHROPIC_BASE_URL/v1/models"
9. awk 'NR>1 && $4=="0A" {split($2,a,":"); printf "listen port %d\n", strtonum("0x" a[2])}' /proc/net/tcp /proc/net/tcp6 2>/dev/null | sort -u

End with one sentence: where the model credential lives, by shape only, and whether the sandbox can call the model API without one.
```
