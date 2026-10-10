---
workstream: plan-on-an-unmerged-branch
status: in-progress
branch: claude/plan-on-an-unmerged-branch
pr: none
plan: plan-on-an-unmerged-branch
issue: 297
session: https://claude.ai/code/session_01JZpYjgSiiDozz5VU1FWpm8
agent: opus
updated: 2026-10-10
next: Verifier pass on the graduation diff, record findings, retire this file, open PR
---

## Goal

Settle `docs/research/plan-on-an-unmerged-branch.md` (issue #297): how the
queue reaches a plan file that exists only on an unmerged branch. Graduate the
answer to `.agents/docs/orchestrated.md`, delete the node.

## Decisions

- Reader already built on main (c3073980, `dispatch_branch_plans`, plan
  plan-on-a-branch-visible). Node left to settle = record the answer + why
  in orchestrated.md, not build. Diff = graduation target + node delete only.
- Answer: base branch stays the only queue; three shapes, three answers
  (filer merges plan-only PR / informational row / abandoned dropped).
- Count, 2026-10-10 origin/main 9abf04f: 112 plans added via merges, 36 rode
  a mixed PR — filer-merges alone is a half-fix.
- Human-ordered spawn on a branch plan: carry the plan on own branch, never
  push to the owner's. Resurrection hazard measured in scratch repo: owner's
  later merge re-adds retired plan, no conflict. Named accepted gap.

## Rejected

- Spawn via `source_revision` onto the owner's branch: pushes to another
  session's pull request.
- Editing orchestrate.md/manage.md here: research diff touches only itself
  and its graduation target.

## Review

## Blockers

None.

## Where to look

- `docs/research/plan-on-an-unmerged-branch.md` — the question and its findings.
- `.agents/harness/queue-context.sh` — item scan ref, branch walk.
- `joharness.sh` — `dispatch_rescope_branches`, `dispatch_retired_edges`.
