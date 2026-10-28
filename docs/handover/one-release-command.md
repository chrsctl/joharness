---
workstream: one-release-command
status: in-progress
branch: claude/one-release-command
pr: none
plan: one-release-command
issue: none
session: https://claude.ai/code/session_01J1YMK6KyCC596i2QaG6VSX
agent: opus
updated: 2026-10-28
next: Write release in joharness.sh (scratchpad parts A, B), then dispatch, then tests and docs
---

## Goal

Make janitor --apply, halt and release ONE command (`release`, with
`--human`; `halt` an alias), and remove `free` and the freer role. The user
asked to simplify the commands that unstick abandoned work.

## Decisions

- A1: confirmed — janitor_apply, cmd_halt and cmd_release each call release_rewrite, release_why, cmd_guard and push --force-with-lease.
- A2: confirmed — cmd_free merges onto the caller's own branch and never pushes.
- A3: confirmed — cmd_guard's only in-script callers pass janitor, halt and release; kill and loop appear only in orchestrate-reference.md GUARD.
- A4: confirmed — JOHARNESS_CLERK_STALE_HOURS row, default 24.
- The `done, no pull request` reason also waits HANDOVER_STALE_SECONDS, and needs a plan: named (not none): a `plan: none` done record is a role's (a surveyor's holds-genuine stays unmerged by design), which the freer also refused.
- A no-claim branch is one that never ADDED a workstream file since the base: an edge that retired its claim waits on its pull request and is not listed.
- Write order per branch: tip, guard, then the report check — as janitor --apply did, so a gone branch exits 0 whether listed or not.

## Rejected

## Review

- r1: (plan-checker) Behaviour lost 3 contradicts A4 and Out of scope on clerk branches with no claim (fixed: A4 and Out of scope now forbid writing only; the report may name the plans)
- r2: (plan-checker) the fixed interface lists two reasons, the plan adds a third, done no pull request (fixed: three reasons, plus the report-only no claim line)
- r3: (plan-checker) a report of releasable branches only cannot print the pr: exempt detail (fixed: non-qualifying stale claims stay listed, indented, with why)
- r4: (plan-checker) removing dispatch_freeable leaves no doc-only scan for no claim (fixed: the replacement scan is specified)
- r5: (plan-checker) five queued plans share files and are unnamed in needs: or Traps (fixed: Traps names them; needs: stays none, dispatch holds overlapping scope apart)
- r6: (plan-checker) acceptance items name no failure shape (wontfix: each line's expected value is the pass condition; anything else fails)
- r7: (plan-checker) prose acceptance bullets are not runnable here (wontfix: the new cases land as selftest assertions verify runs; the consumer line is a SHIPS note)
- r8: (plan-checker) the dispatch grep passes on unchanged code because live origin has no such branch (wontfix: the selftest fixtures pin the removed strings; the grep is a smoke check)
- r9: (plan-checker) the halt no-such-branch line passes unchanged (no change: it pins halt's output staying equal to release --human, which the previous line discriminates)
- r10: (plan-checker) A3's grep finds nothing; the orchestrator spells GUARD kill (fixed: evidence rewritten)
- r11: (plan-checker) cleanup already carries leftovers and merged branches: a duplicate, not a move (fixed: the janitor copies drop, cleanup's merged section gains the five names)
- r12: (plan-checker) the release DUE tail line already exists (fixed: worded as extending it)
- r13: (plan-checker) cmd_guard has five checks, the anchor names four (fixed)
- r14: (plan-checker) the Lineup has no freer row; it is orchestrated.md's Roles table (fixed)

## Blockers

None.

## Where to look

- `joharness.sh:release_rewrite` — the shared write.
