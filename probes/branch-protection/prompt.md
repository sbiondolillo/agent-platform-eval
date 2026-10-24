# Branch-protection probe prompt

Cloud session "Branch protection probe" on sbiondolillo/platform-eval-sample, model Sonnet 5.5 in the picker, environment agent-platform-eval. Pasted as the first message.

```
Check what the protection on main does to a push from this session. Do not create a branch and do not open a pull request. Run each numbered line as one shell call and paste its full output under a heading that shows the command.

1. gh api repos/sbiondolillo/platform-eval-sample/branches/main/protection 2>&1 | head -40; gh api repos/sbiondolillo/platform-eval-sample/rules/branches/main 2>&1 | head -40
2. cd /home/user/platform-eval-sample && git fetch origin main && git checkout -q origin/main && git commit --allow-empty -m "probe: branch-protection, empty commit from a Cloud session" && git push origin HEAD:main 2>&1; echo "exit=$?"
3. cd /home/user/platform-eval-sample && git ls-remote origin main && git log --oneline -1 HEAD
4. gh api repos/sbiondolillo/platform-eval-sample/commits/main/check-runs --jq '.check_runs | map({name, status, conclusion})' 2>&1 | head -20

End with one sentence: was the push to main refused, and by which rule, or did it land.
```
