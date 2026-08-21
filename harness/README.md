# Harness layer

Agent working protocol. Runs in every repo that copies the harness, whatever
environment sits under [`../env/`](../env/README.md).

| Path | Is |
| --- | --- |
| `harness/README.md` | This table — harness-owned vs not. |
| `harness/AGENTS.md` | Loop, decide-alone, handover rules. Imported by root `AGENTS.md`. |
| `harness/handover-context.sh` | SessionStart: prints handover state into context. |
| `harness/queue-context.sh` | SessionStart: prints plan queue + wanted agent tier. |
| `harness/selftest.sh` | Regression tests for these scripts. Run by `joharness.sh ci`. |
| `../joharness.sh` | Entrypoint. Runs this layer, plus the selected environment. |
| `../scripts/sync-to-consumer.sh` | Sync tool: brings a consumer's harness copy current. |
| `../.claude/commands/` | `/handover`, `/who`. |
| `../.claude/settings.json` | SessionStart hook wiring. |
| `../.gitattributes` | LF pins. `selftest.sh` asserts them — the two ship as a pair. |
| `../env/` | All layers, whole. Consumer selects via its own `joharness.conf`. |
| `../CLAUDE.md` | Harness protocol. No Part 2 marker — synced whole. |
| `../docs/handover/README.md` | Protocol + reasoning. |
| `../docs/handover/TEMPLATE.md` | Workstream file shape. |
| `../docs/plans/README.md` | Plan queue protocol. |
| `../docs/plans/TEMPLATE.md` | Plan shape. |
| `../docs/agent-selection.md` | Agent tiers, selection rules. |
| `../docs/graph.md` | Node + edge types, one-substrate rules. |
| `../docs/product/README.md` | Requirements tier, branch flow, reconciliation. |
| `../docs/product/TEMPLATE.md` | Requirement shape. |
| `../docs/caveman.md` | House style. |

Harness-owned. Sync with `scripts/sync-to-consumer.sh`, joharness to
consumer only — consumer-born fixes land in joharness first
(reconciliation: `docs/product/README.md`). NOT harness-owned:
root `AGENTS.md` below its `# Part 2 — project` marker (that repo's
project; above the marker is harness, sync splices), `README.md`,
`joharness.conf` (each repo picks its own environment), `.gitignore`,
`.github/workflows/ci.yml` (consumer CI wiring; harness checks stay
reachable as `./joharness.sh ci`),
`docs/handover/<workstream>.md` (live work), `docs/plans/<plan>.md`
(each repo's own queue), and `docs/product/<requirement>.md` (each
repo's own product).

Nothing here names a specific environment. That coupling belongs in
`joharness.conf` and nowhere else.
