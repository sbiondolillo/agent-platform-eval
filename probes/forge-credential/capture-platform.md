# Capture: forge-credential probe, platform arm

Probe [forge-credential](../../docs/plan.md). The source was read at the commits named below, from the local clones. The host side was settled by the substrate and model-credential platform captures, not re-run here. No host secret was read or printed. This arm asks which GitHub credential pushes the branch and opens the pull request, and how far it reaches.

The factory is `sbiondolillo/dotnet-software-factory` at tag `v1.2.1`. The factory process runs on the self-hosted runner `sandbox-01`. Each agent call runs in a Docker container the factory starts. The push and the pull request do not run in the container. They run in the factory process on the runner host.

## 1. The workflow carries two GitHub tokens, for two jobs

`sbiondolillo/platform-eval-sample`, `.github/workflows/factory.yml` on `main`, lines 20 to 46:

```yaml
# The job's own token reads the check runs of the pull request. A fine-grained token has no Checks permission on a private repo.
permissions:
  checks: read

jobs:
  factory:
    runs-on: [self-hosted, dsf]
    ...
      - name: Run the factory
        env:
          FACTORY_CHECKS_TOKEN: ${{ github.token }}
          ANTHROPIC_BASE_URL: http://10.99.0.186:8200
        run: |
          set -euo pipefail
          set -a; . /etc/homelab/dsf/.infisical-auth.env; set +a
          DOMAIN="https://infisical-api.sambiondolillo.com/api"
          TOKEN=$(infisical login --method=universal-auth --client-id="$INFISICAL_CLIENT_ID" --client-secret="$INFISICAL_CLIENT_SECRET" --domain="$DOMAIN" --silent --plain)
          exec infisical run --token="$TOKEN" --projectId="${{ vars.INFISICAL_PROJECT_ID }}" --domain="$DOMAIN" --env=prod -- \
            dotnet run --project src/App -c Release -- run --repo ${{ github.repository }} --issue ${{ inputs.issue || github.event.issue.number }} --pass-env ANTHROPIC_BASE_URL
```

- `FACTORY_CHECKS_TOKEN` is `github.token`, the Actions `GITHUB_TOKEN`. The workflow's `permissions:` block is `checks: read` and nothing else. This token reads the pull request's check runs, nothing more. It is job-scoped to this one repository and expires when the job ends (section 3).
- The push and the pull request use `FACTORY_GITHUB_TOKEN`, a secret of the Infisical `dsf` project, injected by `infisical run` (line 45) into the factory process. It is not an Actions token.
- Line 44's `TOKEN` is an Infisical access token, not a GitHub one.

## 2. Where push and pull request run, and which token carries

`sbiondolillo/dotnet-software-factory` at `v1.2.1`.

`src/Core/ConsoleCommands.cs` line 12 names the push and PR token, and lines 150 to 154 wire it:

```csharp
    private const string TokenName = "FACTORY_GITHUB_TOKEN";
    private const string ChecksTokenName = "FACTORY_CHECKS_TOKEN";
    ...
        string token = host.Environment(TokenName)!;
        var client = new GitHubClient(http, token);
        string checksToken = host.Environment(ChecksTokenName) is { Length: > 0 } own ? own : token;
        GitHubClient checksClient = checksToken == token ? client : new GitHubClient(http, checksToken);
```

`src/Core/Deliver.cs`, lines 21 to 31, pushes the branch then opens the pull request:

```csharp
    public async Task<PullRequest> RunAsync(string workTree, string runId, string owner, string repo, string baseBranch, int issueNumber, string issueTitle, string token, CancellationToken cancellationToken = default)
    {
        string branch = "factory/" + runId;
        await git.CheckoutBranchAsync(branch, workTree, cancellationToken).ConfigureAwait(false);
        await git.PushAsync(branch, workTree, token, cancellationToken).ConfigureAwait(false);
        ...
        PullRequest pullRequest = await pullRequests.OpenAsync(owner, repo, branch, baseBranch, issueTitle, body, cancellationToken).ConfigureAwait(false);
        await client.PostCommentAsync(owner, repo, issueNumber, $"Opened {pullRequest.HtmlUrl}", cancellationToken).ConfigureAwait(false);
```

- The push runs through `Git`, built as `new Git(host.Runner)` (`ConsoleCommands.cs` line 176). `host.Runner` is the host command runner, so `git push` runs on the runner host as the factory process, not with `docker exec`.
- `Git.PushAsync` (`src/Core/Git.cs` lines 75 to 85) runs `git push origin <branch>` with the environment from `CredentialEnvironment(token)`, lines 234 to 242:

```csharp
    private static Dictionary<string, string> CredentialEnvironment(string token) => new()
    {
        ["FACTORY_GITHUB_TOKEN"] = token,
        ["GIT_CONFIG_COUNT"] = "2",
        ["GIT_CONFIG_KEY_0"] = "credential.helper",
        ["GIT_CONFIG_VALUE_0"] = "",
        ["GIT_CONFIG_KEY_1"] = "credential.helper",
        ["GIT_CONFIG_VALUE_1"] = "!f() { echo username=x-access-token; echo \"password=$FACTORY_GITHUB_TOKEN\"; }; f",
    };
```

  Git authenticates over HTTPS with username `x-access-token` and the token as the password, through an inline credential helper set per command. No helper or askpass is on disk.
- The pull request is opened by `PullRequests.OpenAsync` (`src/Core/PullRequests.cs` lines 10 to 30), a REST `POST /repos/{owner}/{repo}/pulls` through the `GitHubClient` built with `FACTORY_GITHUB_TOKEN`. The commit author is `dotnet-software-factory <dotnet-software-factory@noreply.github.com>` (`ConsoleCommands.cs` lines 16 to 17), but the pull request is opened by the token's identity.
- The container receives only `ANTHROPIC_API_KEY` and `ANTHROPIC_BASE_URL` (`src/Core/Sandbox.cs` lines 59 to 60, quoted in full in the [substrate capture](../substrate/capture-platform.md#the-docker-invocation-from-source-at-v121)). Neither `FACTORY_GITHUB_TOKEN` nor `FACTORY_CHECKS_TOKEN` enters the container. No forge credential reaches the agent's sandbox.

## 3. What `FACTORY_GITHUB_TOKEN` is, and its reach

- It is a fine-grained personal access token on the GitHub account `sbiondolillo`, held in the Infisical `dsf` project (homelab `docs/credentials.md` line 42, the row "Infisical project `dsf`"). The machine identity `dsf-sandbox01` reads the project; its client secret is the host file `/etc/homelab/dsf/.infisical-auth.env`, `root:github-runner` `0640`. The token never reaches a GitHub secret store for this repo, and it never enters the container.
- The workflow comment (line 19) states the reason for the split: a fine-grained token has no Checks permission on a private repo, so check runs are read with the Actions `GITHUB_TOKEN` instead.
- The reach of the PAT is whatever repositories it is scoped to on the account. Its exact repository list is not recorded in source read here (see Unverified). The precedent token `GITHUB_FACTORY_TOKEN` of the Python factory is "a fine-grained PAT on GitHub account `sbiondolillo` ... scoped to selected repositories ... with Contents write, Pull requests write and Issues read" (homelab `docs/credentials.md` line 41), the shape the `dsf` token follows.

## 4. The job-scoped Actions token, for comparison

`FACTORY_CHECKS_TOKEN` is the Actions `GITHUB_TOKEN`. From the GitHub docs, [GITHUB_TOKEN](https://docs.github.com/en/actions/concepts/security/github_token) (the page the automatic-token-authentication guide links for this):

> "The token's permissions are limited to the repository that contains your workflow."

> "The `GITHUB_TOKEN` expires when the job finishes or after its effective maximum lifetime."

On a self-hosted runner the token "can only be refreshed for up to 24 hours" (same page). The token is a GitHub App installation access token. Its permissions are set by the workflow's `permissions:` key, here `checks: read` ([automatic token authentication](https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication): "Use the `permissions` key in your workflow file to modify permissions for the `GITHUB_TOKEN`"). So the Actions token on the runner reaches only `platform-eval-sample`, can only read check runs, and dies with the job.

## 5. Evidence: who opened pull request 6

`gh pr view 6 --repo sbiondolillo/platform-eval-sample --json author,headRefName`:

```
{"author":"sbiondolillo","head":"factory/45752200"}
```

Pull request 6, from the successful attempt 2 run on branch `factory/45752200`, was opened by `sbiondolillo`, the operator's own account. It is not `github-actions[bot]`. This confirms section 2: the pull request is opened by the `FACTORY_GITHUB_TOKEN` PAT, which carries the operator identity, not by the Actions `GITHUB_TOKEN`.

## Unverified

- The exact repository scope of the `dsf` project's `FACTORY_GITHUB_TOKEN` PAT. Source read here names it as a fine-grained PAT on `sbiondolillo` but does not list its selected repositories. It reaches `platform-eval-sample`, proven by pull request 6.
