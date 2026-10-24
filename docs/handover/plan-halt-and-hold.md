---
workstream: plan-halt-and-hold
status: in-progress
branch: claude/plan-halt-and-hold
pr: none
plan: halt-and-hold
issue: none
session: https://claude.ai/code/session_016VB32myigsC5a7gT5th1gL
agent: fable
updated: 2026-10-24
next: Research dispatch, janitor and requirement intake in joharness.sh; then decompose docs/product/halt-and-hold.md into plans
---

## Goal

Planning pass for `docs/product/halt-and-hold.md`: decompose the requirement
(halt a live claim on a human's order; hold an unplanned requirement behind
other work without a slot) into plans. Plans only, no implementation.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

One bullet per finding, written BEFORE its fix, committed WITH it, in exactly
the form `- rN: text (fixed|wontfix: why|no change)` — `ci` checks it. Tag the
verifier's findings `(verifier)`. Clean pass = one bullet saying so. Remove
this paragraph when you add the first bullet.

## Blockers

None.

## Where to look

- `docs/product/halt-and-hold.md` — the requirement.
- `joharness.sh:cmd_dispatch` — where held and halted items must read right.
- `joharness.sh:cmd_janitor` — the only writer of `status: abandoned` today.
