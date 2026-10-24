# Cloud delivery review prompt

The review pass for the Cloud arm's pull request. It runs as a second Cloud session.

## Session settings

| setting | value |
|---|---|
| environment | `agent-platform-eval` |
| repository | `sbiondolillo/platform-eval-sample` |
| branch | the delivery pull request branch |
| model | Sonnet 5.5 |

## Source

The prompt is lifted from the review gate of the .NET software factory: `src/Core/ReviewPhase.cs`, method `BuildPrompt`, tag `v1.2.1`. The factory's own run reads the issue, the plan and the diff from its work tree. Three changes fit it to a Cloud session:

- The session reads the issue from `issue #1` and takes the base from `main`.
- The verdict goes in the final answer, not in `.factory/review.json`.
- The session writes `date -u` at start and at end.

## Prompt

Replace `<DELIVERY_BRANCH>` with the pull request branch before the paste.

```text
Run `date -u` first and write the output.

Review the build of issue #1 of this repository.

Read the issue with `gh issue view 1` if `gh` works. Otherwise read it from the pull request description.

Base: the `main` branch. The build is on the branch <DELIVERY_BRANCH>.
Read every change since the base with `git diff main...<DELIVERY_BRANCH>`.

Your job:
1. Read every feature file under specs/features/ and the plan, .factory/plan.md, if they exist.
2. Judge the build against every scenario, every result the plan states and every sentence of the issue, and judge whether the tests cover what each scenario names. An existing test is a scenario under specs/features/, or a [Fact] or [Theory] method under tests/Specs/Unit/ or tests/Integration/, at the base commit. Each row of the Examples of a Scenario Outline, and each [InlineData] row of a [Theory], is a test, and an edit to the row is an edit to that test. A step class, a helper and a stub are not tests. Block an edit to the text of an existing scenario or to the body of an existing test method, a rename or a removal, when the issue does not name that test. A wrapper around the body, such as a retry, is an edit. An edit to a step that an existing scenario uses keeps what the step does and what it asserts. New steps, state of a step class moved into a shared class, and new helpers pass.
3. Give the verdict in your final answer. The first line is exactly APPROVED or CHANGES REQUESTED. Approve only a build with no blocking item. After CHANGES REQUESTED, list the findings. Write each finding as one fault, in words that a builder can act on with the item alone.
4. Leave every file as it is. Do not commit, push or comment.

Run `date -u` last and write the output.
```
