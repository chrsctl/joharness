---
workstream: unsupervised-sources
status: in-progress
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: unsupervised-sources
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Read cmd_cleanup, cmd_feedback and lint_shallow against the plan's claims before writing any code.
---

## Goal

`docs/plans/unsupervised-sources.md`. Unsupervised mode has a stated end —
the source sweep goes dry — and nothing computes it. Build
`./joharness.sh sources`: a read-only sweep over the sources an unsupervised
session may draw work from, one counted line each, one verdict.

## Decisions

- Claimed at opus though the plan says sonnet. Escalation is permitted,
  downgrade is not; the plan's own Traps name three files other in-flight
  plans touch, and the counts have to come out of `cmd_feedback`'s existing
  walk rather than a second one.
- Checked for a duplicate claim BEFORE cutting the branch, by walking every
  remote branch's `docs/handover/*` for `plan: unsupervised-sources`. Free.
  This is not ceremony: an hour ago this session duplicated issue #114
  against a session that had already fixed it, because the claim on an
  ISSUE is not representable in the queue (#119).

## Rejected

- Nothing yet.

## Review

Not yet run: no edge, no pull request open.

## Blockers

None.

## Where to look

- `joharness.sh:cmd_cleanup` — the shape to match: read-only, counts every
  class including zeroes, names the command that acts.
- `joharness.sh:cmd_feedback` — the disposition walk; the unmarked count
  comes from here, not from a second walk.
- `joharness.sh:lint_shallow` — the existing "cannot compute here" path.
- `docs/product/unsupervised-mode.md`, Constraints — the detector rule.
