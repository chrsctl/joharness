---
workstream: unsupervised-sources
status: in-progress
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: unsupervised-sources
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Record the verifier round, fix what it finds, then retire plan + workstream file and open the pull request.
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

- `ci` runs ONCE inside the sweep, not `ci` plus a separate `selftest.sh`.
  `ci` already runs the suite; two runs of a 60-second suite to answer one
  question is the waste the perf budget exists to notice. Both numbers plus
  the exit status come out of the single run.
- Blind beats dry in the verdict. A source that could not be read reports
  `INCOMPLETE`, never `dry`. This is the one property the command exists for:
  the mode's only stopping point rests on it, and blurring it stops a fleet
  because it failed to look rather than because nothing is left. Proven by
  mutation — remove the blind branch and an unreadable suite reports
  `sweep dry`.
- The unmarked count comes from `fb_collect`'s existing walk rather than a
  second one. Two walks over the same edges are two answers to one question,
  and they diverge the first time `fb_marker` changes.

## Rejected

- Building the known-gap detector on the plan's stated figure. The plan says
  the marker count here is 1; it is 0. Its single hit was a filename
  mentioned in prose inside a `.md` file, which the plan's own scope
  excludes. Claims in a plan are hypotheses (`.agents/docs/plans/README.md`)
  and this one did not survive contact.
- Counting SKIPs without first checking they can reach zero. Measured before
  building: 0 SKIPs in the suite on canonical, so the sweep can go dry here.
  Had structural skips existed, the detector would have been uncountable by
  construction — the thing the requirement forbids. A consumer with
  consumer-only skips is a live version of that question and is written down
  rather than assumed away.

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
