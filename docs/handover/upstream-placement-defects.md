---
workstream: upstream-placement-defects
status: in-progress
branch: claude/upstream-placement-defects
pr: none
plan: upstream-placement-defects
issue: none
session: https://claude.ai/code/session_0158ckFurR1bSxTGn9v4L8g4
agent: sonnet
updated: 2026-10-10
next: Wait for selftest + sweep (scratchpad sweep.out), recount feedback.md tables, run ci, verifier review, retire, PR.
---

## Goal

Plan `upstream-placement-defects`: `upstream` mislabels canonical-owned findings unplaceable.

## Decisions

- Plan Traps say joharness.sh is a protocol path, SUPERVISED ONLY. `./joharness.sh protocol-paths` prints only joharness.conf, .claude/settings.json, .github, and the comment above `protocol_paths` says joharness.sh is deliberately NOT core. `authority` is VERIFIABLE orchestrated. Proceeding unattended; plan text is stale on this.

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:upstream_harness_path`, `joharness.sh:cmd_upstream`
