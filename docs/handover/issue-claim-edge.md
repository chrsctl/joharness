---
workstream: issue-claim-edge
status: in-progress
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: issue-claim-edge
issue: 119
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Implement — handover-context.sh reader and both print sites first, then the lint, then docs and fixtures.
---

## Goal

Issue #119, which this session caused: two sessions solved #114 in parallel
because a claim on an issue cannot be represented. Give the issue the same
stable frontmatter edge a plan already has.

## Decisions

- This file carries `issue: 119` from its first commit — the field claiming
  the issue that asks for the field. If the implementation is right, the hook
  will print that claim on the next session start, which is the acceptance
  criterion running against itself.
- Field, not derived grep. Chosen by the requester 2026-08-29 after I argued
  the opposite in #119 on rot grounds. I was wrong: `status:` rots because
  its value changes over time; an issue number never does, and `plan:` is an
  accepted stable edge of exactly this shape. A derived grep fails toward
  "free", which is the direction that caused the duplicate.
- The hook stays offline. It reads git refs and nothing else, and it ships to
  every consumer; a hook needing a token to say what is claimed fails closed
  in the repos that most need it.

## Rejected

- Nothing yet.

## Review

Not yet run: no edge, no pull request open.

## Blockers

None.

## Where to look

- `.agents/harness/handover-context.sh` — the `fields` reader and the two
  print sites.
- `joharness.sh:lint_graph` — where the field gets validated.
