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
next: Settle ref + unreadable-base direction, patch handover-guard.sh, add selftest cases
---

## Goal

Settle `docs/research/guard-fires-on-an-empty-branch.md` (issue #296): the
handover guard's "branch has no upstream" fact fires on a branch with zero
commits and a clean tree. Graduate the answer into
`.agents/harness/handover-guard.sh` with selftest cases, delete the node.

## Decisions

- Pending.

## Rejected

- The issue's `|| echo 0` patch: fails open when `origin/<base>` is absent
  (measured in the research file).

## Review

## Blockers

None.

## Where to look

- `.agents/harness/handover-guard.sh` — the `elif` under the upstream check.
- `.agents/harness/selftest/handover-guard.sh:396` — existing never-pushed case.
