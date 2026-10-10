---
workstream: plan-on-a-branch-visible
status: in-progress
branch: claude/plan-on-a-branch-visible-x7k2
pr: none
plan: plan-on-a-branch-visible
issue: 297
session: https://claude.ai/code/session_011826jrSc2fYHWmqxniAGSN
agent: opus
updated: 2026-10-10
next: Read verifier findings into ## Review, merge origin/main (18 behind, shared files), ci, retire, PR
---

## Goal

Issue #297: `dispatch` reads `docs/plans/` on the base branch only, so a plan
riding on an unmerged branch is invisible to the orchestrator. Print such
plans in a block (never free, never counted), tell the orchestrator to
report URGENT ones first, and tell the manager to drive its own plan-only
pull request to merged.

## Decisions

- No workers: the diff is one helper, one print block, two role-file
  sentences and one fixture section — splitting it costs more prompt than
  code, and every part is the judgement the plan's tier is for.
- Block printed after the rescope block, just before the verdict: "after the
  spawn list, before the verdict" with the CORE ONLY and rescope blocks kept
  next to the list they qualify.
- A plan whose path the base already carries is dropped (`cat-file -e`): the
  queue has its row; listing it twice is the duplicate the plan prevents.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_rescope_branches` — ref walk to copy.
