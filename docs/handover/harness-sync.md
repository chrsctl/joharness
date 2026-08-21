---
workstream: harness-sync
status: in-progress
branch: claude/harness-loop-queue-check-cgwj76
pr: none
plan: harness-sync
session: https://claude.ai/code/session_01TMhPHHGbEUUVfF9kUfZBcu
agent: sonnet
updated: 2026-08-21
next: Build scripts/sync-to-consumer.sh per plan; then human-authorized scope extension: perform sync to chrsctl/redoct
---

## Goal

Plan `harness-sync`: build one-way sync tool, joharness to consumer.
Human extended scope this session: ALSO perform sync to `chrsctl/redoct` —
its `docs/agent-selection.md` misses review-churn rule (learned IN redoct),
its `docs/product/README.md` misses conflict-at-finish rules. Loop with
review each round until reconciled.

## Decisions

- Branch name differs from plan (pre-assigned by session, not cut as
  `claude/harness-sync`). Claim edge = this file's `plan:` field, still
  holds.
- Plan's out-of-scope "performing actual sync" overridden by human this
  session — recorded here, not silently.

## Rejected

- (From plan, dead branch): git submodule — `.claude/` must sit at
  repo-root paths. git subtree — merge machinery for ~15 files.

## Blockers

None.

## Where to look

- `harness/README.md` — harness-owned table (salvage note: drafted
  pre-split, redo against env/-split paths).
- `AGENTS.md` — `# Part 2 — project` marker.
- `/home/user/redoct` — consumer clone, drift measured this session.
