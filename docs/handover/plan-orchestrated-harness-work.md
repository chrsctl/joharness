---
workstream: plan-orchestrated-harness-work
status: in-progress
branch: claude/plan-orchestrated-harness-work
pr: none
plan: none
issue: 311
session: https://claude.ai/code/session_013Bg636JRhWFWgWW26RWefB
agent: opus
updated: 2026-10-08
next: Record verifier findings in ## Review, fix, retire workstream file, PR, merge
---

## Goal

Requester, 2026-10-08: "Joharness should be able to be developed in
orchestrator mode which is forbidden, we need roles which convert issues to
docs/plans etc". Decompose into plans; this branch writes plans only.

## Decisions

- Session ran attended (`JOHARNESS_MODE=supervised` exported): a human gave
  the ask in this session. Plans are not protocol paths either way.
- Two plans, not one: unlocking protocol work and the issue role are
  separable, and the second is only orchestrable once the first merges.

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:protocol_paths`, `joharness.sh:unattended` — the bound.
- `.claude/commands/curate.md` — the shape a cadence role copies.
