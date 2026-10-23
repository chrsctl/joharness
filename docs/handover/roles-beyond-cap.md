---
workstream: roles-beyond-cap
status: in-progress
branch: claude/roles-beyond-cap
pr: none
plan: roles-beyond-cap
issue: none
session: https://claude.ai/code/session_018FNpTGRJapDHTuQhgkbGwR
agent: opus
updated: 2026-10-23
next: Change cmd_dispatch slot arithmetic so roles spawn beyond the cap, then the selftests and protocol text
---

## Goal

Repo owner (relayed from chrsctl/gx): `JOHARNESS_MAX_MANAGERS` caps managers
only; curator and clerk must still spawn while every manager slot is full.

## Decisions

- Surveyor and freer leave the cap too (owner's lean: neither builds a plan).
  Freer: at most one in flight, FREEABLE rows no longer count as free manager
  items. Surveyor: never subtracted in code; the OVERLAP-BOUND trigger keeps
  its idle-slot condition, since it detects plans held while slots idle.
- `JOHARNESS_MAX_MANAGERS=0` holds every role.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — slot arithmetic and role tail lines.
