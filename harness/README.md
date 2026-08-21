# Harness layer

Agent working protocol. Runs in every repo that copies the harness, whatever
environment sits under [`../env/`](../env/README.md).

| Path | Is |
| --- | --- |
| `harness/AGENTS.md` | Loop, decide-alone, handover rules. Imported by root `AGENTS.md`. |
| `harness/handover-context.sh` | SessionStart: prints handover state into context. |
| `harness/queue-context.sh` | SessionStart: prints plan queue + wanted agent tier. |
| `harness/selftest.sh` | Regression tests for these scripts. Run by `joharness.sh ci`. |
| `../joharness.sh` | Entrypoint. Runs this layer, plus the selected environment. |
| `../.claude/commands/` | `/handover`, `/who`. |
| `../docs/handover/README.md` | Protocol + reasoning. |
| `../docs/handover/TEMPLATE.md` | Workstream file shape. |
| `../docs/plans/README.md` | Plan queue protocol. |
| `../docs/plans/TEMPLATE.md` | Plan shape. |
| `../docs/agent-selection.md` | Agent tiers, selection rules. |
| `../docs/graph.md` | Node + edge types, one-substrate rules. |
| `../docs/caveman.md` | House style. |

Harness-owned, copy whole when syncing to a consumer repo. NOT harness-owned:
root `AGENTS.md` (its Part 2 is that repo's project), `README.md`,
`joharness.conf` (each repo picks its own environment),
`docs/handover/<workstream>.md` (live work), and `docs/plans/<plan>.md`
(each repo's own queue).

Nothing here names a specific environment. That coupling belongs in
`joharness.conf` and nowhere else.
