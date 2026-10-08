---
workstream: name-no-consumer-says-both
status: review
branch: claude/name-no-consumer-says-both
pr: none
plan: name-no-consumer-says-both
issue: 273
session: https://claude.ai/code/session_01NYQXKf9UKWPPaKuCTpEdbY
agent: sonnet
updated: 2026-10-08
next: ci pass, verify's one docker-networking fail is pre-existing and not
  gated for a docs-only diff, finish green, verifier clean. Retire this
  file and the plan file in the last commit, then open the PR flagging
  the direction (not covered) to the human for ratification, then merge.
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

- r1: (verifier) full check against the plan's Scope/Acceptance/Traps:
  both acceptance greps re-run and matched exactly (1 hit at line 218 for
  `pull request number`, 3 hits at 208/210/218 for the opaque/resolves/say
  what pattern, all inside `## Name no consumer`); `git diff` confirmed
  the "Requester's rule" paragraph is unchanged context, byte-identical;
  no repository, plan, or item name added; no glossary row added; new
  reasoning checked against the plan's own descriptive-vs-opaque argument
  and found consistent. (clean — no change needed)

## Blockers

None.

## Where to look

- `.agents/docs/consumer-repos.md:192` — `## Name no consumer`, the section
  to edit.
- `docs/plans/name-no-consumer-says-both.md` — full plan, scope, acceptance,
  traps.
