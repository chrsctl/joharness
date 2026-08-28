---
workstream: tree-vs-diff-rule
status: in-progress
branch: claude/base-review-adaptions-yle8r9
pr: none
plan: tree-vs-diff-rule
session: https://claude.ai/code/session_01JWpBo9HoR5Mn1KgqBL6vqt
agent: opus
updated: 2026-08-28
next: Verify the four cited edges against feedback output, then write the rule
---

## Goal

Plan `docs/plans/tree-vs-diff-rule.md`: one defect class cost four merged
edges and five sessions, each fixing its own caller, none writing the rule
down. Question every one got wrong: does this branch OWN a file, or did it
inherit it from the base branch? Tree presence answers neither. Ownership
is a diff against the merge base. Write the rule where the next author
meets it.

## Decisions

- Claimed in parallel with `process-scorecard`, which
  `claude/backpass-usage-review-sbew6t` holds live. Queue proved this pair
  as wave 1 and the scopes are disjoint: that plan takes `joharness.sh`,
  `.agents/docs/graph.md`, `.agents/harness/selftest.sh`; this one takes
  `.agents/docs/feedback.md`, `.agents/harness/AGENTS.md`. Earlier in this
  session the pair was NOT safe — that branch then carried an unmerged
  16-file glossary pass over `AGENTS.md`. It merged as PR #99, so the
  overlap is gone and the wave is real again.

## Rejected

- Nothing yet.

## Review

Pending.

## Blockers

None.

## Where to look

- `joharness.sh:fin_adds_at` — newest instance, carries the reasoning to graduate.
- `joharness.sh:cl_inflight` — same fix in `cleanup`.
