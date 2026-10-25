---
workstream: release-claim-held-by-edge
status: in-progress
branch: release-claim-held-by-edge
pr: none
plan: release-claim-held-by-edge
issue: 626
session: https://claude.ai/code/session_012hikkNfLjLPU4pMwpU4VZG
agent: opus
updated: 2026-10-25
next: Research dispatch parked-claim row, cmd_halt and guard; check A1 and A2
---

## Goal

Issue #626 follow-up: a parked claim whose block the queue has since absorbed
through a `needs:` edge should release itself, without a human's `halt`.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `joharness.sh` dispatch parked-claim row near `BLOCKED: the human's`.
