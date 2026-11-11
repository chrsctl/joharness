---
workstream: stranded-branch-plans
status: in-progress
branch: claude/stranded-branch-plans
pr: none
plan: stranded-branch-plans
issue: none
session: https://claude.ai/code/session_01J1YMK5JiVnb6MHweCHr34Q
agent: opus
updated: 2026-11-11
next: Re-run selftest and ci after verifier fixes, then finish
---

## Goal

A plan filed on a branch that never opened a pull request has no owner. Mark
such branches `STRANDED <n>d` in dispatch, count them in the verdict, and have
the orchestrator notify a human once. The human stays the only one who lets a
branch plan into the queue.

## Decisions

- A1: confirmed — `dispatch_branch_plans` computes `days` per row from the oldest add commit.
- A2: confirmed — `own` and `wfs` read the branch's workstream files in the same loop.
- A3: confirmed — `.agents/docs/orchestrated.md` "the scheduler cannot see a pull request".
- A4: confirmed — `knobs-declared.sh` reds a read with no KNOBS row and a dispatch key with no table row.
- "No workstream file" = none ADDED since the merge base, as `release_noclaim_rows` reads it: a requirement manager's plan-only pull request retires its claim before the PR opens, and that edge must not read STRANDED.
- The mark is a suffix on the row (`held 3d  STRANDED 3d`), so every existing row expect still reads its prefix.

## Rejected

## Review

- r1: (plan-checker) the tree moved during the review: selftest cases were written while it read (no change: the selftest is not the plan; findings were read against HEAD and hold)
- r2: (plan-checker) the plan never relates the mark to the existing `release ... no claim:` line (fixed: Goal names it and the two clocks)
- r3: (plan-checker) the report rule sits in orchestrator-reference.md, not orchestrator.md (fixed: plan names the orchestrator.md Report paragraph, in scope)
- r4: (plan-checker) a dispatch knob needs its orchestrated.md knob-table row (fixed: Scope names it)
- r5: (plan-checker) "carries no workstream file" has three readings (fixed: never added since the merge base, as release_noclaim_rows reads it)
- r6: (plan-checker) per-branch rows vs per-stem lines: which mark, what k counts (fixed: any stranded branch marks the line, max held; k counts rows)
- r7: (plan-checker) ledger `notified=bp:<branch>` has no entry to ride (fixed: an entry `bp:<branch> notified=bp:<branch>` added to the grammar)
- r8: (plan-checker) an open clerk pull request 2+ days old reads STRANDED (wontfix: the clerk merges its own pull request in its pass and JOHARNESS_CLERK_STALE_HOURS already reads one older than 24h as abandoned; a human told of it is the wanted outcome)
- r9: (plan-checker) acceptance lacks a command for the origin/main failure and a failure shape (fixed: both written; this repo's expected row named)
- r10: (plan-checker) Traps names a retired plan and misses shared files (fixed)
- r11: (plan-checker) "the clerk reads no other branch" is half wrong (fixed)
- r12: (verifier) a `bp:` ledger entry fits neither the in-flight-only ledger rule nor the health walk, so "once" fails on a prune (fixed: orchestrator.md keeps it while dispatch prints the branch STRANDED, and the health walk skips it)
- r13: (verifier) a stem on a code branch and a plan-only branch reads STRANDED with no word on which branch (fixed: the mark names its branches, `STRANDED <n>d on <branch>`; selftest case)
- r14: (verifier) the verdict counted (branch, plan) rows while the block prints one line per stem (fixed: it counts the marked lines; selftest case with one stem on two branches)
- r15: (verifier) `[ -z "$wfs" ]` is redundant with the grep and the claim-add check (no change: it is the plan's literal condition and skips two git calls on every claimed branch)
- r16: orchestrator.md went 74 bytes over its size bound with the r12 text (fixed: the STRANDED sentence and ledger line trimmed)

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_branch_plans` — the reader.
- `.agents/harness/selftest/dispatch-branch-plans.sh` — the cases.
