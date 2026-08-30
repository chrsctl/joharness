---
workstream: perf-base-branch-unmeasured
status: review
branch: claude/perf-base-branch-unmeasured
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-30
next: Retire this file, open the pull request, merge.
---

## Goal

Decompose, not build. PR 149 found that the perf budget cannot see the base
branch it protects, and proved it with a breach that reached `main` unseen.
The finding is recorded in `joharness.sh`'s perf block; this turns it into a
queue node, because a finding recorded in a comment is not scheduled work.

## Decisions

- **Plan, not fix.** The obvious change — drop the `selftest_inert_diff`
  skip — makes every docs-only branch pay for a measurement the skip exists
  to spare them. A real trade-off, so it goes to a plan rather than into the
  diff that found it.
- **`sonnet`, `low`.** One decision and one guard; the measurement work is
  done and cited in the plan. `effort` is an enum — `low medium high xhigh`,
  and `small` reds `graph lint`, which is how this one was caught.
- **Acceptance names a CONSUMER check**, because the plan ships in
  `joharness.sh` and `ci`'s ship-scope stage says a bar met only here is met
  in the repo that was never the risk.
- **The loose ceiling is called out as out of scope.** PR 149 cut `feedback`
  255 to 202 and deliberately left 267/275 alone. A later session reading a
  65-command gap needs to know that is a choice, not neglect.

## Rejected

- **Folding this into PR 149.** Found at that branch's review round, but
  fixing it there would have widened a fix into a redesign of when `ci`
  measures.

## Review

Round 1, opus, self.

- r1: the plan first cited only the `selftest_inert_diff` skip, which alone
  lets a reader conclude a post-merge run fixes everything. The pinned window
  is the second half — a branch is measured before its own merge exists — and
  without it the `bfedce8` breach reads as an oversight rather than a
  structural gap. (fixed — both stated, with the measured 15-to-21 swing)
- r2: the plan had no Acceptance and no Traps, and `ci` said so twice: the
  ship-scope stage asked for a consumer-side check, and `graph lint` redded
  the `effort` value outright. Written from the drafted body without
  re-reading `.agents/docs/plans/README.md`. (fixed — both sections added,
  `effort: low`)
- r3: verifier round owed and NOT run, same standing instruction as the last
  several edges.

## Blockers

None.
