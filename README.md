# agent-platform-eval

A controls comparison of two ways to run Claude Code on an issue: a Hosted Agent Platform, which is Docker on a VM you own, and Claude Code Cloud Sessions, which is a VM that Anthropic manages. The experiment settles the direction of [dotnet-software-factory](https://github.com/sbiondolillo/dotnet-software-factory) v2: keep its own sandbox on a runner, or start its runs as Cloud Sessions from GitHub.

Every cell on the Cloud Sessions side is proven by a probe run in the real product, with the docs URL beside it. Every cell on the platform side is proven by a public asset. A cell with no proof says so.

| file | what it is |
|---|---|
| `docs/plan.md` | the to-do list, the settled design and the row list. Read it first |
| `probes/<row>/` | one directory per row: the prompt or script, and the captured output |
| `site/` | the report page, built by `sh site/src/build.sh` from `site/src/report.src.html` and the report cells of every finding. Never edit `site/index.html`. |

The report is published at https://sbiondolillo.github.io/agent-platform-eval/ .

The platform arm is the factory at `v1.1.0` on a self-hosted runner in a lab VM. The target repo for both arms is named in `docs/plan.md` once it exists. A third arm, Managed Agents, opened on 2026-10-27, and its to-do is in `docs/plan.md` under "Managed Agents arm".
