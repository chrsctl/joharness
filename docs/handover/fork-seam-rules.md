---
workstream: fork-seam-rules
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: fork-seam-rules
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: sonnet
updated: 2026-08-28
next: Write the three rule edits at their anchors, re-counting the plan's two stale figures
---

## Goal

Plan `docs/plans/fork-seam-rules.md`: the Loop's finish ritual assumes the
session that opens a pull request also merges it. A fork PR breaks that at
three points, all observed on PR #79. Three rule edits, one per observed
failure, at the anchors where sessions read.

## Decisions

- Plan wants `sonnet`; this session runs `opus`. Escalation of the
  implementer, allowed. Review depth follows the PLAN's tier, so `agent:`
  here records `sonnet` and the review is `/code-review` (high) on the full
  diff, not the opus multi-lens shape.

## Rejected

(nothing yet)

## Review

(pending)

## Blockers

None.

## Where to look

- `.agents/harness/AGENTS.md:124` — "LAST COMMIT BEFORE", edit 1's anchor.
- `.agents/harness/AGENTS.md:89` — "Own =", edit 2's anchor.
- `.agents/docs/handover/README.md:196-224` — push-time-not-liveness, edit 3.
