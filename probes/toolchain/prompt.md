# Toolchain probe

No separate session. The evidence came from the Initialized session row of two existing sessions, the public docs, and the factory image on sandbox-01.

- Cloud Sessions: the operator expanded the "Initialized session" row of two sessions on environment `agent-platform-eval` in the web UI on 2026-10-24 and took two screenshots. The docs were read with `curl -sL` from the Markdown form of each page, `https://code.claude.com/docs/en/<page>.md`, on 2026-10-24.
- Platform: read-only commands over SSH on sandbox-01 as `sam`, the factory source at tag `v1.2.1`, the `homelab-ansible` role for the runner host, and the GitHub jobs API and job logs of the target repo's factory runs. The commands are in [`capture-platform.md`](capture-platform.md).
