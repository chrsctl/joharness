---
workstream: guard-fires-on-an-empty-branch
status: in-progress
branch: manage/guard-fires-on-an-empty-branch
pr: none
plan: guard-fires-on-an-empty-branch
issue: 296
session: https://claude.ai/code/session_01QFGN1dp5sjk2H9WFFaLyE4
agent: opus
updated: 2026-10-10
next: Wait for selftest (real + two reverted copies), then ci, verifier, PR
---

## Goal

Settle `docs/research/guard-fires-on-an-empty-branch.md` (issue #296): the
handover guard's "branch has no upstream" fact fires on a branch with zero
commits and a clean tree. Graduate the answer into
`.agents/harness/handover-guard.sh` with selftest cases, delete the node.

## Decisions

- The guard fix itself already landed on main (2c300a0b, #296): count
  against `origin/<base>`, fire when the count is unreadable. This branch
  settles the two open decisions in writing and adds the missing case.
- Ref = `origin/<base>`: shared view; stale it is older than the fork point,
  so the count only grows — false fire, never a missed one.
- Unreadable base = FIRE. Not the header's "unexpected exits 0": that is the
  guard breaking, this is an ordinary git state, and silence drops the very
  commits the fact exists for.
- Selftest: new case deletes `refs/remotes/origin/main` on a branch with an
  unpushed commit and expects the fact; empty-branch case tightened from a
  one-phrase refute to whole silence.

## Rejected

- The issue's `|| echo 0` patch: fails open when `origin/<base>` is absent
  (measured in the research file).

## Review

## Blockers

None.

## Where to look

- `.agents/harness/handover-guard.sh` — the `elif` under the upstream check.
- `.agents/harness/selftest/handover-guard.sh:396` — existing never-pushed case.
