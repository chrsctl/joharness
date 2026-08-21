---
plan: harness-sync
urgency: normal
agent: sonnet
effort: high
needs: none
---

<!-- Seeded from dead branch claude/harness-sync (deleted unmerged); its
workstream file's decisions and blockers carried over. -->

## Goal

joharness is canonical; consumer repos carry copies. Sync is manual cp.
Build the minimal mechanism: script that brings a consumer current and
shows what changed. Performing a sync gets NO handover file (protocol:
"When NOT to write one") — this plan builds the tool.

## Scope

- `scripts/sync-to-consumer.sh` — copy harness-owned paths (list:
  `harness/README.md` table), print diff summary. One-way: joharness to
  consumer. Reconciliation rule (docs/product/README.md): consumer-born
  fixes land here first, then sync out — script warns when consumer copy
  is AHEAD of canonical, never overwrites silently.
- Solve the root `AGENTS.md` problem first: file is part harness import,
  part per-repo Part 2. Blind copy clobbers consumer's Part 2. Split into
  two files, or sync only above the `# Part 2 — project` marker. Decide,
  record in the script header.

## Out of scope

- git submodule — `.claude/` and hooks must sit at repo-root paths Claude
  Code loads from; submodule indirection breaks that. (Rejected on dead
  branch.)
- git subtree — merge machinery for a copy of ~15 files; plain copy is
  inspectable in review. (Rejected on dead branch.)
- Performing an actual sync to a consumer.

## Acceptance

- Dry run against a scratch dir: harness-owned files copied, `README.md`,
  `joharness.conf`, root `AGENTS.md` Part 2, live workstream files NOT
  copied.
- `./joharness.sh ci` = `ci: pass`.

## Where to look

- `harness/README.md` — harness-owned vs NOT harness-owned table.
- `AGENTS.md` — the `# Part 2 — project` marker line.

## Traps

- `harness/` must never name a specific environment; the sync script is
  harness tooling — same rule.
