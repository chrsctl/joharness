# Harness layer

Agent working protocol. Runs in every repo that copies the harness, whatever
environment sits under [`.agents/env/`](../env/README.md).

| Path | Is |
| --- | --- |
| `.agents/harness/README.md` | This table — harness-owned vs not. |
| `.agents/harness/AGENTS.md` | Loop, decide-alone, handover rules. Imported by root `AGENTS.md`. |
| `.agents/harness/handover-context.sh` | SessionStart: prints handover state into context. |
| `.agents/harness/queue-context.sh` | SessionStart: prints plan queue + wanted agent tier. |
| `.agents/harness/selftest.sh` | Regression tests for these scripts. Run by `joharness.sh ci` when the branch changes anything outside `docs/` and `README.md`; `JOHARNESS_SELFTEST=always` runs it regardless. Canonical only. |
| `joharness.sh` | Entrypoint. Runs this layer, plus the selected environment. |
| `.agents/scripts/sync-to-consumer.sh` | Sync tool: brings a consumer's harness copy current. |
| `.claude/commands/` | `/handover`, `/who`. |
| `.claude/settings.json` | SessionStart hook wiring. Consumer-own settings go in `.claude/settings.local.json`, never here — this file syncs whole. |
| `.gitattributes` | LF pins. `selftest.sh` asserts them — the two ship as a pair. |
| `.agents/LICENSE` | MIT grant, byte-identical to root `LICENSE` (`selftest.sh` asserts it). Ships beside the files it covers; a consumer's root `LICENSE` is its own. |
| `.agents/NOTICE` | What that grant covers in a consumer, and the third-party material distilled into `.agents/docs/`. |
| `.agents/env/` | All layers, whole. Consumer selects via its own `joharness.conf`. |
| `CLAUDE.md` | Harness protocol. No Part 2 marker — synced whole. |
| `.agents/docs/handover/README.md` | Protocol + reasoning. |
| `.agents/docs/handover/TEMPLATE.md` | Workstream file shape. |
| `.agents/docs/plans/README.md` | Plan queue protocol. |
| `.agents/docs/plans/TEMPLATE.md` | Plan shape. |
| `.agents/docs/agent-selection.md` | Agent tiers, selection rules. |
| `.agents/docs/graph.md` | Node + edge types, one-substrate rules. |
| `.agents/docs/product/README.md` | Requirements tier, branch flow, reconciliation. |
| `.agents/docs/product/TEMPLATE.md` | Requirement shape. |
| `.agents/docs/caveman.md` | House style. |
| `.agents/docs/consumer-repos.md` | Creating and updating a consumer (child) repo. Entry point for both. |

Harness-owned. Sync with `.agents/scripts/sync-to-consumer.sh`, joharness to
consumer only — consumer-born fixes land in joharness first
(reconciliation: `.agents/docs/product/README.md`). NOT harness-owned:
root `AGENTS.md` below its `# Part 2 — project` marker (that repo's
project; above the marker is harness, sync splices), `README.md`,
`joharness.conf` (each repo picks its own environment), `.gitignore`,
`.github/workflows/ci.yml` (consumer CI wiring; harness checks stay
reachable as `./joharness.sh ci`), `.github/workflows/update.yml`
(consumer's own sync cadence and canonical), and ALL of `docs/` — the
work dirs `docs/handover/` (live work), `docs/plans/` (each repo's own
queue) and `docs/product/` (each repo's own product) hold only that
repo's files; the harness ships nothing there. One sentence for a
consumer: `.agents/` + `.claude/` + the root instruction files +
`joharness.sh` = harness, `docs/` = yours.

Nothing here names a specific environment, and `selftest.sh` fails the run
when something does. Two exemptions, both by definition: `none`, the harness's
word for having no layer, and one carve-out for a security regression test
that needs a real layer's `setup.sh` — spelled once, in the check. That
coupling belongs in
`joharness.conf` and nowhere else.
