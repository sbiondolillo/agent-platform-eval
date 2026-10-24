# @claude side experiment

Side experiment for [issue #2](../../docs/plan.md). The operator posted this comment on [issue #2](https://github.com/sbiondolillo/platform-eval-sample/issues/2) of the sample repo, twice:

```text
@claude Read this issue and reply with a one-paragraph summary of what it asks for and which files you would touch. Do not change any file, do not open a pull request.
```

The operator did three steps on 2026-10-24:

1. Post the comment at 23:38:24Z. The Claude GitHub App was already installed, with the repo granted. Wait five minutes for an answer.
2. Run `/install-github-app` in the Claude Code CLI on the workstation. The command opens a pull request that adds a workflow, and sets a repository secret.
3. Merge that pull request, then post the same comment again at 23:45:02Z.
