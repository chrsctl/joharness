---
workstream: issue-remainder-closes
status: in-progress
branch: claude/clever-pascal-qz32iv
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01J1YMK5fH2288GR1soijKET
agent: haiku
updated: 2026-11-20
next: Re-run ci, verify and verifier on this head (first runs saw the pre-rewrap tree), then PR
---

## Goal

Report PR #789 (consumer gx): `Closes #N` is chosen from the plan's
`## Issue remainder` heading alone, so an issue closes as completed while its
PR body or the plan's `## Out of scope` names an undone part (5 of 134 gx
`Closes` PRs, #789's node, swept in gx 2026-11-20). Fix: decide `Closes`/`Refs` at PR open from every place an
undone part shows, and have the plan-checker red a deferral without the heading.
#789's later commit adds the opposite error: 13 gx clerk plan-only PRs closed
their issue at merge, before any fix, through a closing keyword in the body
(11 via a verifier line `fixed: #N`). Fix: clerk.md forbids one there.

## Decisions

- Report option 4 taken as prose in clerk.md, read before merge; no
  mechanical grep: harness commands never call the GitHub API.
- Report options 1 and 2 both taken: 1 covers the build-time route (4 of 5
  cases), 2 the clerk-wrote-wrong-heading route. Option 3 (mechanical check)
  skipped: no marker exists for "deferred to a human".
- #789's research node not carried: the fix answers its question; the human
  closes #789.

## Rejected

- None.

## Review

- r1: (verifier) Link comment never wired to name the undone parts; "files a new issue" had no step (fixed: § Link the issue adds `not done: <part>` lines; new-issue branch dropped)
- r2: (verifier) "body or Review names one" ambiguous against an unrelated `wontfix: PR body` finding (fixed: only a part of issue N itself; outside findings force nothing)
- r3: (verifier) plans/TEMPLATE.md:25 summary names only the heading (wontfix: a 4th path breaks the fast lane bound; routed to PR body)
- r4: (verifier) clerk.md dropped the no-section sentence (fixed: restored as a claim the plan-checker holds it to)
- r5: (verifier) no selftest pins the new prose (wontfix: plan-checker check is an agent prompt, the Closes/Refs choice reads GitHub text; no mechanical seam, report's option 3 says the same; routed to PR body)
- r6: (verifier) consumer figures carry no source (fixed: cites #789's node and its sweep date)
- r7: (verifier) change bigger than typo-sized for the fast lane (no change: prose only, inside lint_fast_lane's bound, lane ordered by the human)

## Blockers

None.

## Where to look

- `.agents/docs/manager-reference.md` § Plan issue — the Closes/Refs rule.
