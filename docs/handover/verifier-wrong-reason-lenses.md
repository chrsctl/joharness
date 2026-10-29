---
workstream: verifier-wrong-reason-lenses
status: in-progress
branch: claude/verifier-wrong-reason-lenses
pr: none
plan: verifier-wrong-reason-lenses
issue: none
session: https://claude.ai/code/session_01J1YMK5LLj6K3wZbTENfC55
agent: opus
updated: 2026-10-29
next: Retire commit, open PR, finish, merge
---

## Goal

Teach the verifier four shapes of a test green for the wrong reason, within
the file's reading budget (docs/plans/verifier-wrong-reason-lenses.md).

## Decisions

- A1: confirmed — `grep -n 'wrong reason\|inject' .claude/agents/verifier.md` no hit (2026-10-29).
- A2: confirmed — `wc -c` = 6013; `reading-budget.sh:59` `rb_bound verifier.md 6211`, bound 6832, room 819.
- A3: unverified here — gx not reachable from this session (add_repo denied); the four shapes as the plan states them name no consumer, so they are generic on their face.
- Shapes go after the verdict list as kinds of STUB; hang/die maps to UNVERIFIED (plan Scope, made explicit after r4).

## Review

- r1: (plan-checker) grep acceptance `wrong side\|hang` matches "change", so 2 is reachable with no shape written; checks 2 of 4 shapes (fixed: four distinct phrases, count 4)
- r2: (plan-checker) consumer-side acceptance names no command (fixed: sync-to-consumer.sh then cmp, consumer ci)
- r3: (plan-checker) four acceptance items do not say what failure looks like (fixed)
- r4: (plan-checker) placement "beside STUB" reads as new verdicts or as STUB sub-cases (fixed: sub-list after the verdict list, kinds of STUB)
- r5: (plan-checker) gx counts and source headings unverified, no command (wontfix: gx outside this session's reach; recorded under A3)
- r6: (plan-checker) `serves: all` beside `requirement: none` is noise (wontfix: plans.md allows it, absent = all; not red)
- r7: (plan-checker) round 2: `<consumer-dir>` undefined, no consumer checked out (fixed: scratch consumer bootstrapped from the merge base, then synced from head)
- r8: (plan-checker) round 2: gx claims unverified (wontfix: same as r5)
- r9: (plan-checker) round 2: Scope maps three shapes to STUB, fourth placement ambiguous (fixed: all four in one sub-list, fourth says UNVERIFIED)
- r10: (plan-checker) round 2: selftest item lacks its failure form (fixed)
- r11: (verifier) lead sentence calls every shape STUB while the fourth line says UNVERIFIED; a timed-out suite fits both (fixed: lead says first three are STUB)
- r12: (verifier) STUB undersells a real fix behind a wrong-reason test, closer to UNVERIFIED (wontfix: plan Scope chose STUB; a test that cannot fail is a test asserting nothing, STUB's own example)
- r13: (verifier) one selftest run of three red on c2-run "a stem merged twice", file untouched by this diff (no change: not this branch's; reported as a lead)

## Blockers

None.

## Where to look

- `.claude/agents/verifier.md` — § Did the branch do what it was for.
