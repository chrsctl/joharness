---
workstream: retest-renamed-branch-path
status: in-progress
branch: manager/retest-renamed-branch-path
pr: none
plan: retest-renamed-branch-path
issue: none
session: https://claude.ai/code/session_01J1YMK4JQsfWEwkVQ7pADKT
agent: opus
updated: 2026-11-12
next: verifier round 2 on r12/r13, then retire and finish
---

## Goal

A branch that renumbers its own file after merging the base pays a RETEST,
not the full finish run (plan `docs/plans/retest-renamed-branch-path.md`).

## Decisions

- A1: confirmed — `joharness.sh:checks_paths` lists `--no-renames`.
- A2: confirmed — replayed by the plan-checker in a scratch repo, git 2.43.0: `R100 docs/0390-branch.md docs/0391-branch.md`.
- Each rename case runs on its own branch (`kr_rn`): certify after the add, base adds its own record, merge, then the case's edit. Cases share no certificate state.
- Digit rule: both basenames, digits deleted, equal; same directory; source in `known`. Helper `checks_renumbered`.
- Fails without the fix: detached worktree at the merge base with only this branch's `checks.sh`: `4400 passed, 3 failed` — case (i) both lines and (ii)'s named line FAIL (2026-11-12).

## Review

- r1: (plan-checker) case (i) does not say to certify after the add, nor branch per case (no change: build certifies per case on its own branch, Decisions)
- r2: (plan-checker) digit rule reads two ways (no change: built as both basenames digit-free equal, the example's reading)
- r3: (plan-checker) doc edit names `resolved` against the Scope's `--no-renames` (no change: edit went to the stray test's known set)
- r4: (plan-checker) consumer-repos.md has 64 bytes of budget (no change: edit is net shorter; ci reading budget passes)
- r5: (plan-checker) SHIPS not runnable here (wontfix: it is a consumer's later observation, nothing in this checkout measures it)
- r6: (plan-checker) acceptance items name no failure form (wontfix: each names its expected output; anything else is red)
- r7: (plan-checker) case (i) label undefined (no change: labels are `retest: rename i.` and the fail run names them)
- r8: (plan-checker) case (iii) underspecified (no change: base moves and merges first via `kr_rn`)
- r9: (plan-checker) mixed-tree selftest count unverified (no change: counts here are from runs after the edits)
- r10: (plan-checker) anchor `kr_main` is a helper, not the block (no change: resolves)
- r11: build edits landed while the plan-checker still ran, against the hold-still rule (no change: its findings were checked against HEAD, the plan only; no rerun needed)
- r12: (verifier) same-directory rule untested: replacing it with `:` left the selftest green (fixed: case v, a renumber into `.agents/harness/`, must be the full run; with the rule replaced by `:` it FAILs, 4403 passed 2 failed, 2026-11-12)
- r13: (verifier) step 3 line in consumer-repos.md not re-wrapped (fixed)

## Blockers

None.

## Where to look

- `joharness.sh:checks_catch_up` — the stray test.
- `.agents/harness/selftest/checks.sh:kr_main` — RETEST fixture.
