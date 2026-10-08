---
workstream: name-no-consumer-says-both
status: in-progress
branch: claude/name-no-consumer-says-both
pr: none
plan: name-no-consumer-says-both
issue: 273
session: https://claude.ai/code/session_01NYQXKf9UKWPPaKuCTpEdbY
agent: sonnet
updated: 2026-10-08
next: Edit made (first paragraph, descriptive-vs-opaque split added, PR
  numbers dropped from covered list); acceptance greps pass. Waiting on
  background ./joharness.sh ci and the verifier subagent; fold verifier
  finding into ## Review below (before any fix commit), then run
  ./joharness.sh finish and open the PR, flagging the direction to the
  human per acceptance item 4.
---

## Goal

Issue #273. `.agents/docs/consumer-repos.md`, `## Name no consumer`, answers
the same question twice, differently: one paragraph says pull request
numbers ARE covered by the no-repo-name citation rule, the next says they
are NOT. Plan picks the second (not covered) on a descriptive-vs-opaque
argument and three re-runnable checks (tree already practices the
exemption; the counting requirement needs PR numbers; the leak this fears
needs a second, already-forbidden violation).

## Decisions

- Following the plan's direction as written: NOT covered. Not re-deciding
  it here — the plan already ran the checks and rejected the alternative.

## Rejected

(none yet — plan already did this work)

## Review

(filled at step 5, before fix, same commit)

## Blockers

None.

## Where to look

- `.agents/docs/consumer-repos.md:192` — `## Name no consumer`, the section
  to edit.
- `docs/plans/name-no-consumer-says-both.md` — full plan, scope, acceptance,
  traps.
