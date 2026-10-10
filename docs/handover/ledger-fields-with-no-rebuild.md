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
next: Graduate the research answer into .claude/commands/orchestrate.md (step 0 rebuild + per-field loss lines in §4), delete the research file
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

## Rejected

## Review

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` — §4 ledger grammar; step 0.2 list_sessions.
