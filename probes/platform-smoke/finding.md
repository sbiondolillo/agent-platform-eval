# Platform smoke run

Run 40115249577 on `sbiondolillo/platform-eval-sample`, 2026-10-24, on the self-hosted runner `sandbox-01`, factory at `dotnet-software-factory` branch `sandbox-anthropic-base-url` (pull request 345). Every phase passed and the factory opened pull request 3 on issue #2.

| phase | seconds | turns | spend | result |
|---|---|---|---|---|
| plan | 17 | 8 | $0.0808 | passed |
| build 1 | 62 | 4 | $0.0681 | passed |
| test 1 | 13 | 0 | $0 | passed |
| review 1 | 14 | 4 | $0.0426 | approved |

The gateway's ledger for the same window: consumer `dsf`, 12 calls, 263118 tokens, $0.1915. The two figures agree.

Squid on `egress-01`, for the host 10.25.0.10 during the run: `TCP_TUNNEL` to the GitHub, NuGet and Microsoft hosts, `TCP_DENIED` for `api.anthropic.com:443` 23 times. The denied calls are Claude Code's side traffic. Inference went to the gateway.

Three runs failed before this one. Each cause and fix is a line in `homelab-ansible` commit `3ee4df0`: the runner user did not own the SDK tree, `dotnet-install.sh` needs `aka.ms`, and Node ignores a CIDR in `NO_PROXY`.

GitHub rendered no steps for any run that day, on any runner. See the live-steps item in `docs/plan.md`.
