---
workstream: ledger-fields-with-no-rebuild
status: in-progress
branch: claude/ledger-fields-with-no-rebuild
pr: none
plan: ledger-fields-with-no-rebuild
issue: 307
session: https://claude.ai/code/session_01EBbfrQriYghvs7sdAuqiio
agent: opus
updated: 2026-10-10
next: Run ci + verify, spawn verifier, record ## Review, retire node + this file, PR, merge
---

## Goal

Research node `docs/research/ledger-fields-with-no-rebuild.md` (issue #307):
which orchestrator ledger fields can be rebuilt from a read the role already
makes, and what each of the rest costs when a pass drops it. Findings are
written and verified in the node; the work is graduating them into
`.claude/commands/orchestrate.md` and deleting the node.

## Decisions

- `.claude/commands/` is NOT a protocol path today (`./joharness.sh
  protocol-paths` prints joharness.conf, .claude/settings.json, .github), so
  the node's "branch is a human's" note is stale; graduating here.
- Most of the answer already landed on main before this claim (step 0.2
  title rebuild of `@new`, per-field loss lines in §4). Residue graduated
  here: the `:637`/`:700` pair that described entry age two incompatible
  ways (rewritten to match the rows: age gates entry to the ladder, `seen=`
  the verdicts), the rebuild's partiality (existence and count, never age),
  and `respawns=`'s missing cross-check written down as "nowhere".

## Rejected

## Review

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` — §4 ledger grammar; step 0.2 list_sessions.
