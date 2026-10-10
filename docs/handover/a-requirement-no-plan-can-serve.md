---
workstream: a-requirement-no-plan-can-serve
status: in-progress
branch: claude/a-requirement-no-plan-can-serve
pr: none
plan: a-requirement-no-plan-can-serve
issue: none
session: https://claude.ai/code/session_013FHjxEdXBhx4U6yUnLfFtg
agent: opus
updated: 2026-10-10
next: Review (verifier at opus), record findings, retire workstream file, PR, merge
---

## Goal

Settle research node `a-requirement-no-plan-can-serve`: what stops dispatch
re-offering a requirement as UNPLANNED when no plan will ever name it.
Graduate the answer to `.agents/docs/product/README.md`, delete the node.

## Decisions

- UNPLANNED test stays; lifecycle gives: four exits for a planning pass
  (plans, verify plan via needs:, satisfied-measured, declined-recorded),
  else blocked. A recorded, citable requester decline = requester deciding.
- Claim gap (candidate 1) needs code: filed as plan requirement-row-claim,
  not built here (research file writes no code).

## Rejected

- planned-out marker on requirement: status field, product README forbids.
- clause-level decline vocabulary read by the test: largest change, exit 4
  already makes the decline legible in history.
- bound the spend: every pass ends normally, ceiling never fires.

## Review

## Blockers

None.

## Where to look

- `docs/research/a-requirement-no-plan-can-serve.md` — the node.
- `.agents/docs/product/README.md` — graduation target, lifecycle exits.
