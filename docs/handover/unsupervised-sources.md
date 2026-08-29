---
workstream: unsupervised-sources
status: review
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: unsupervised-sources
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Retire plan + workstream file, open the pull request, merge on green checks.
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

Round 1, self-found by running the command against numbers measured before
the code existed. Recorded after their fixes, which is not the protocol's
order — said here rather than tidied away.

- r1: the marker detector counted its own definition and the comment above
  it. Two hits nothing could ever clear, so that source could never reach
  zero — an uncountable source, which is the one thing the requirement
  forbids, built into the command that enforces it. Pattern is now assembled
  from halves. (fixed)

Round 2, `.claude/agents/verifier.md` at opus, on a frozen SHA, told the
suite results up front and forbidden from re-running them. Twelve findings;
the severe three were all wrong zeros.

- r2 (verifier): `ci`'s exit status was printed and never read. The suite is
  one stage of nine — the linters, glossary, graph lint, churn, perf and the
  finish gate each turn `ci` red without moving "N passed, M failed" — so a
  red tree reported `sweep dry`. The one input the plan named that the first
  version dropped. (fixed)
- r3 (verifier): the feedback walk's cap was ignored. Measured: 60 edges
  against a default cap of 50, 83 unmarked capped against 86 uncapped. Three
  findings outside the window with no knob set, reported as a complete
  number. (fixed — the sweep now reads every edge)
- r4 (verifier): the blind path was unreachable. `base_ref` falls back to
  HEAD, so "cannot count" fired only in a repo with no commits; a shallow
  clone or fresh consumer reported `0 unmarked` toward dry. (fixed)
- r5 (verifier): `git grep` exit ≥2 is git failing to LOOK, swallowed into a
  zero — the one detector that could not say it was blind. (fixed)
- r6 (verifier): `ci`'s own skips are spelled SKIPPED and went uncounted by a
  grep for `SKIP ` with a trailing space. (fixed)
- r7 (verifier): a docs-only branch was permanently INCOMPLETE, which is the
  state of a session that has just committed a generated plan — the mode's
  stopping point was unreachable from its most common position. (fixed with
  JOHARNESS_SELFTEST=always)
- r8 (verifier): INCOMPLETE discarded what the sweep did find. (fixed)
- r9 (verifier): `sweep dry` reads as the stop signal but is one conjunct of
  four; the requirement also needs a second dry sweep, an empty queue and no
  open pull request, none of which this counts. Now says so in its own
  output. (fixed)
- r10 (verifier): the new `case` arm was inserted between `protocol-paths`'
  comment and its subject, so the comment documented the wrong thing and both
  its clauses were false of `sources`. (fixed)
- r11 (verifier): the findings detector was unpinned — the fixture had no
  merged edges, so `printf 0` would have passed the whole section. That
  absent test is what let r3 and r4 through. (fixed)
- r12 (verifier): `.agents/docs/plans/README.md` was in the plan's scope and
  had shipped as nothing, unrecorded. (fixed)
- r13 (verifier): the workstream file was not updated in the same commit as
  code and its `next:` was false. (fixed; the same-commit rule was broken
  again on later commits and is worth calling out rather than claiming clean)

Round 3, mine, fixing round 2.

- r14: reporting a capped walk as blind was the right diagnosis and the wrong
  remedy — 60 edges against a cap of 50 made the sweep permanently
  INCOMPLETE, so the mode could never stop. The same never-terminates failure
  from the other side. (fixed — read every edge)
- r15: blanket-blinding shallow checkouts repeated that a third time. This
  container's checkout IS shallow and carries 60 readable edges. Blind only
  where blindness is the honest answer: zero edges AND shallow. (fixed)
- r16: the case added for r2 was itself a vacuous pass — its `broken.sh`
  never made `ci` red, and `sweep NOT dry` passed off a leftover unacted
  finding. Only the assertion on the `ci-red(exit` token caught it. Third
  fixture this session to pass for the wrong reason. (fixed)

Churn, recorded rather than hidden: `src_unmarked` took four revisions, three
of them over-corrections of the previous one. The rule that ends it —
blind only where blindness is the honest answer — was reached by collision
and is now written into `.agents/docs/plans/README.md` so the next session
gets it without paying for it.

## Blockers

None.

## Where to look

- `joharness.sh:cmd_cleanup` — the shape to match: read-only, counts every
  class including zeroes, names the command that acts.
- `joharness.sh:cmd_feedback` — the disposition walk; the unmarked count
  comes from here, not from a second walk.
- `joharness.sh:lint_shallow` — the existing "cannot compute here" path.
- `docs/product/unsupervised-mode.md`, Constraints — the detector rule.
