# joharness

Canonical harness home. Consumer repos copy the harness
from here; sync = plain copy commit, no handover file. House style:
[`docs/caveman.md`](docs/caveman.md).

## Working in this repo

Agent guidance: [`AGENTS.md`](AGENTS.md). `CLAUDE.md` imports it — Claude Code
loads it every session.

Two things ready:

- **Docker + Kubernetes sandbox.** `SessionStart` hook runs
  `scripts/devenv.sh up`: `docker`, `kubectl`, `k3d`, `helm` work at session
  start; cluster on demand via `scripts/devenv.sh cluster-up`. What it
  provides, what it costs, four sandbox constraints the scripts work around:
  [`docs/environment.md`](docs/environment.md). Verify:
  `scripts/smoke-test.sh`.
- **Handover protocol between sessions.** One workstream file per work under
  `docs/handover/`, on that work's branch. Second `SessionStart` hook prints
  state — this branch's file, what is in flight elsewhere — before first
  prompt. `/handover` writes the file; `/who` reports genuinely running
  sessions. Protocol + reasoning:
  [`docs/handover/README.md`](docs/handover/README.md).
