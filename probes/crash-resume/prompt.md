# Crash-resume probe prompt

Cloud session "Crash resume probe" on sbiondolillo/platform-eval-sample, model Sonnet 5.5 in the picker, environment agent-platform-eval, issue #2. Four messages so far; the reclaim step follows.

## Message 1

```
Set up some state. I will then interrupt this session from the UI and ask what survived. Do not commit, do not push, do not create a branch. Run each numbered shell line as one shell call and paste its full output under a heading that shows the command.

1. date -u | tee /tmp/probe-start.txt; echo "untracked marker" > /home/user/platform-eval-sample/probe-crash-resume.txt; git -C /home/user/platform-eval-sample status --short
2. nohup sh -c 'while true; do date -u >> /tmp/probe-heartbeat.log; sleep 5; done' >/dev/null 2>&1 & echo "heartbeat pid $!"
3. Use your Agent tool to spawn one subagent with this task: "Run date -u and echo subagent marker, and report both lines." Paste the subagent's report.
4. ls -la /root/.claude/projects/*/ /root/.claude/projects/*/*/ 2>/dev/null; wc -l /root/.claude/projects/*/*.jsonl /root/.claude/projects/*/*/*.jsonl 2>/dev/null
5. sleep 600

Say nothing after starting step 5 until it ends.
```

## Message 2

```
Two things. First, run this listing as one shell call and paste the full output: ls -laR /root/.claude/projects/ | head -60; wc -l $(find /root/.claude/projects -name '*.jsonl'). Second, run sleep 180 as a plain foreground shell command, not as a background task, and say nothing until it returns.
```

## Message 3

```
Yes. First run this as one shell call and paste the full output: ls -la /root/.claude/projects/*/*/subagents/; wc -l /root/.claude/projects/*/*/subagents/*. Then run the until-loop that waits 180 seconds in the foreground, and say nothing until it returns.
```

## Message 4

```
Report what survived the interruption. Run each numbered line as one shell call and paste its full output under a heading that shows the command.

1. cat /tmp/probe-start.txt; tail -3 /tmp/probe-heartbeat.log; pgrep -af probe-heartbeat | head -3
2. ls -la /home/user/platform-eval-sample/probe-crash-resume.txt; git -C /home/user/platform-eval-sample status --short
3. pgrep -af 'sleep 600' | head -3
4. ls -la /root/.claude/projects/*/*/subagents/ | head -8

Then, without a shell: tell me the two lines the subagent reported in step 3 of my first message, exactly as it gave them.
```
