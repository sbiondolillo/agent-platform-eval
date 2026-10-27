# Model credential

Probe for [issue #2](../../docs/plan.md). Question: what the sandbox holds for the model API, by shape only. No value was captured in either arm.

The answer sets how far a stolen model credential reaches in each arm of the DSF v2 decision.

## Cloud Sessions

The VM has no `ANTHROPIC_API_KEY` variable. `ANTHROPIC_BASE_URL` is the vendor host, `https://api.anthropic.com`, and that host is on `NO_PROXY`, so model calls bypass the local proxy at `127.0.0.1:33511`. The credential is an OAuth token in a file, `/home/claude/.claude/remote/.oauth_token`, next to `.session_ingress_token`, and `CLAUDE_SESSION_INGRESS_TOKEN_FILE` points to an 898-byte token file. Both files matched the grep for `sk-ant-` or `ANTHROPIC_API_KEY`, so the agent, which runs as root, can read them. A call to the vendor API with no auth header returns 401, so the credential that makes model calls work is inside the VM, and the agent process can read it. `GH_TOKEN`, `GITHUB_TOKEN`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and `CLOUDSDK_AUTH_ACCESS_TOKEN` are each 14 characters with no known prefix, which is the shape of a placeholder. The forge-credential probe settles the GitHub one.

Capture: [`capture.md`](capture.md).

## Platform

The container holds `ANTHROPIC_API_KEY` in its environment, and its value is a gateway key for consumer `dsf`, not a vendor key. `ANTHROPIC_BASE_URL` is the lab's LiteLLM gateway at `http://10.99.0.186:8200`, which a firewall permit lets sandbox-01 reach directly. The key is a static per-consumer key. The gateway's auth maps it to the name `dsf` and sets no spend budget, no rate limit and no model list, so the key reaches all seven models the gateway serves. The key works only from a host with a route to port 8200, and sandbox-01 is the one Sandbox VLAN host with that route. The vendor key stays in the gateway's own Infisical project on `llm-01` and never enters the Sandbox VLAN. From sandbox-01, the gateway returns 401 with no key, and the vendor host is refused by Squid with 403 and dropped on the direct path.

The Infisical machine identity is not in a GitHub secret. Its client secret is a host file, `/etc/homelab/dsf/.infisical-auth.env`, readable by the runner user's group. The job step loads it into the factory process, and the factory passes only `ANTHROPIC_API_KEY` and `ANTHROPIC_BASE_URL` into the container. The container thus holds neither the Infisical credential nor the GitHub token. On disk, each run leaves the container's home, with Claude Code's state and session transcripts, under the factory checkout's `.factory/sandbox-home/`. It is unreadable as the operator account, so this probe could not say whether the gateway key persists there.

Capture: [`capture-platform.md`](capture-platform.md).

## Comparison

| row | Cloud Sessions | Platform |
|---|---|---|
| credential in the sandbox (shape) | an OAuth token file at `/home/claude/.claude/remote/.oauth_token` and an 898-byte session ingress token file. No key variable. | `ANTHROPIC_API_KEY` in the container's environment, holding a static gateway key for consumer `dsf` |
| who can read it inside | the agent, which runs as root | the agent, which runs as uid 997. The variable is in the environment of every process in the container. |
| blast radius if exfiltrated | the account's OAuth token, usable from anywhere the vendor API answers. This probe did not read its expiry or how to revoke it. | one gateway key, usable only from a host that reaches `llm-01:8200`, on all seven gateway models with no budget. Every call is logged under `dsf`. Revoked by a rotation of `LITELLM_DSF_KEY` in two Infisical projects. |
| where the vendor key lives | not visible. The VM holds an account OAuth token, not a vendor API key. | in the `litellm` Infisical project, read by the gateway on `llm-01`. Never on sandbox-01. |
| does the model path go through the egress proxy | no. `api.anthropic.com` is on `NO_PROXY`, so model calls skip the local proxy at `127.0.0.1:33511`. | no. `10.99.0.186` is on `NO_PROXY`, and the call goes direct to the gateway through one firewall permit. The vendor host is denied by Squid. |

## Managed Agents

Probed 2026-10-27 by name only, in the substrate session `sesn_01BdfqEvYjyeHEFzS61c1VgR` ([`../substrate/capture-ma.md`](../substrate/capture-ma.md)). Docs: https://platform.claude.com/docs/en/managed-agents/overview. The environment holds no `ANTHROPIC_API_KEY` and no `ANTHROPIC_BASE_URL`, and the harness is not Claude Code, so the model call is made by the service outside the sandbox, as the docs state. The environment does hold `ANTHROPIC_COMMIT_TOKEN`, 61 characters, prefix `ANTH`, with `ANTHROPIC_COMMIT_SIGN_URL` at `api.anthropic.com`: it is the credential of the commit signer in `/root/.gitconfig`, not a model key. A sweep of the filesystem for the key shape and a test of the commit token's reach were in the audit-record session, which the safeguard refused. The reach of that token is therefore not probed.

| row | Managed Agents |
|---|---|
| credential in the sandbox (shape) | no model key. `ANTHROPIC_COMMIT_TOKEN`, 61 characters, for commit signing. |
| who can read it inside | the agent, as root |
| blast radius if exfiltrated | not probed: the test was refused |
| where the vendor key lives | with the service. The caller's API key starts the session and never enters it. |
| does the model path go through the egress proxy | no. The sandbox makes no model call. |

## Report cells

Cloud: the VM holds the account's OAuth token in a file that the root agent can read, and model calls skip the egress proxy, so the credential that the agent can read has the reach of the whole account.

Platform: the container holds only a lab gateway key, usable from inside the lab and logged per call, and the vendor key never enters the Sandbox VLAN, but the gateway sets no budget or model list on that key.

Managed Agents: the sandbox holds no model key, because the service makes the model call, but it holds a 61-character commit-signing token whose reach was not probed.
