# Substrate probe prompt

Cloud session on sbiondolillo/platform-eval-sample, model Sonnet 5.5 in the picker, environment agent-platform-eval, issue #2. Pasted as the first message.

```
This is a read-only probe of the sandbox you run in. Do not change any file, do not commit, do not push, do not create a branch. Run each numbered line as one shell call. Paste the full output of each, unedited, under a heading that shows the command. If a command is missing, say so and run the fallback after the ||.

1. uname -a
2. cat /etc/os-release
3. id
4. nproc; free -m; df -h / /home
5. systemd-detect-virt 2>&1 || cat /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_name 2>&1
6. grep -c hypervisor /proc/cpuinfo; grep -m1 'model name' /proc/cpuinfo
7. capsh --print 2>&1 || grep Cap /proc/self/status
8. cat /proc/1/comm; cat /proc/1/cgroup; ls -la /.dockerenv 2>&1
9. ps -eo pid,user,comm --sort=pid | head -40
10. ip addr 2>&1 || cat /proc/net/fib_trie
11. env | cut -d= -f1 | sort

End with one sentence: what runs the code, as which user, with which capabilities.
```
