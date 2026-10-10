---
workstream: guard-before-a-harness-push
status: in-progress
branch: manage/guard-before-a-harness-push
pr: none
plan: guard-before-a-harness-push
issue: 398
session: https://claude.ai/code/session_018Vxqi4MSVT8L68UTbCoig4
agent: opus
updated: 2026-10-10
next: Mutation-test each guard check, run ci and verify, then verifier review
---

## Goal

One shared check (`./joharness.sh guard <verb> <branch> [--expect <sha>]`)
run right before every harness push onto a branch the session does not own,
so "re-read live state before writing" is a property of the write path
(#397, #398).

## Decisions

- Exit codes: 0 pass, 2 = `live` found the branch gone (released already),
  1 = every other refusal. janitor_apply needs the split: gone stays rc 0 and
  drops the stale local ref (PR411 r3); unreachable stays a failure.
- janitor_apply calls guard after building the commit, right before the
  leased push, and prints its `release` lines only once guard passes: a
  not-a-candidate branch keeps its old skip line, and a gone branch prints no
  `release` it never made.
- `claim` reads workstream files the branch wrote since its merge base (as
  `cl_inflight`), both sides; head refusal stays the refusal.
- orchestrate.md: one GUARD paragraph, referenced from KILL, LOOP, the
  relayed human answer and the respawn-limit hand-off.

## Rejected

- None yet.

## Review

- r1: shellcheck SC2183, the fixture claim's printf took five arguments for four placeholders. (fixed)
- r2: mutation, 2026-10-10: each guard check disabled in turn (base-name protected, live gone, live unreachable, head, pr: protected) and the guard topic alone run through a scratch runner sourcing `.agents/harness/selftest/guard.sh`: 8, 2, 1, 9, 4 failures; unmutated 44 passed, 0 failed. (no change)

## Blockers

None.

## Where to look

- `joharness.sh:janitor_apply` — the push path guard replaces the inline check in.
