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
next: Plan-checker round 2, then add the four wrong-reason shapes to .claude/agents/verifier.md
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

## Blockers

None.

## Where to look

- `.claude/agents/verifier.md` — § Did the branch do what it was for.
