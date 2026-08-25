---
workstream: guard-docs-only-branch
status: in-progress
branch: claude/guard-docs-only-branch
pr: none
plan: guard-docs-only-branch
session: https://claude.ai/code/session_019c3kktaEvDBAnDv1K2i65p
agent: haiku
updated: 2026-08-25
next: Exclude root-level *.md from the guard's code filter and make the comment say so.
---

## Goal

The handover guard's comment says "a docs-only branch is its own record";
its filter counts root `AGENTS.md` as code. Plan:
`docs/plans/guard-docs-only-branch.md`, with the measurement.

## Decisions

- **Answer 1: root-level `*.md` is documentation, excluded.** The plan put
  two defensible readings and asked for a choice rather than an
  assumption. This one, because the guard fires at Stop — "asked of a
  session exactly when it is least attentive", its own words — so its cost
  of being wrong is a session learning to dismiss it. A branch whose whole
  diff is prose has its record in the diff, which is what the comment
  already promises.
- **Root level only, never nested.** `.agents/harness/AGENTS.md` and every
  other `.md` under `.agents/` stay code: rule work touches more than the
  root file, and that is the case the guard should still catch. What is
  excluded is `AGENTS.md`, `README.md`, `CLAUDE.md` and their neighbours
  at the top of the tree.
- **Flagged, not silent.** A branch that rewrites ONLY the root rules and
  nothing else now gets no nag. That is the accepted cost of answer 1 and
  it is stated here and in the guard, so answer 2 can be taken later
  without rediscovering why.

## Rejected

- **Answer 2 (root `AGENTS.md` is protocol, fix the comment instead).**
  Safer on paper. Rejected because it keeps a Stop-hook false positive on
  every documentation branch, and the churn measure shares this filter —
  which the comment ties together deliberately, so widening the split
  would need its own reasoning.

## Review

(none yet)

## Blockers

None.

## Where to look

- `.agents/harness/handover-guard.sh` — `code_changed` and its comment.
