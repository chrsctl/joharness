---
workstream: guard-docs-only-branch
status: abandoned
branch: claude/guard-docs-only-branch
pr: none
plan: guard-docs-only-branch
session: https://claude.ai/code/session_019c3kktaEvDBAnDv1K2i65p
agent: haiku
updated: 2026-09-17
next: Abandoned claim, free to take — read this file whole, then exclude root-level *.md from the guard's code filter and make the comment say so
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

**Claim released by the janitor sweep of 2026-09-17.** The session that made
it is gone: `session_019c3kktaEvDBAnDv1K2i65p read SESSION_STATUS_ARCHIVED`. It was holding `docs/plans/guard-docs-only-branch.md`, which is
free from the moment the queue hook reads `status: abandoned` above.

Nothing on this branch was changed but this file, and nothing was deleted —
not the file, not the branch, not a line of what the claim already said. The
work below is exactly as its session left it.

**A session that picks this up sets `status:` back and carries on.** That is
not a formality: the status is what the queue reads, and this note is not an
instruction to anybody, it is the record of one reading taken on one date.

## Where to look

- `.agents/harness/handover-guard.sh` — `code_changed` and its comment.
