# Harness layer

Agent working protocol. Runs in every repo that copies the harness, whatever
environment sits under [`../env/`](../env/README.md).

| Path | Is |
| --- | --- |
| `harness/AGENTS.md` | Loop, decide-alone, handover rules. Imported by root `AGENTS.md`. |
| `harness/handover-context.sh` | SessionStart: prints handover state into context. |
| `../joharness.sh` | Entrypoint. Runs this layer, plus the selected environment. |
| `../.claude/commands/` | `/handover`, `/who`. |
| `../docs/handover/README.md` | Protocol + reasoning. |
| `../docs/handover/TEMPLATE.md` | Workstream file shape. |
| `../docs/caveman.md` | House style. |

Harness-owned, copy whole when syncing to a consumer repo. NOT harness-owned:
root `AGENTS.md` (its Part 2 is that repo's project), `README.md`,
`joharness.conf` (each repo picks its own environment), and
`docs/handover/<workstream>.md` (live work).

Nothing here names a specific environment. That coupling belongs in
`joharness.conf` and nowhere else.
