---
workstream: catchup-bound-first-parent
status: in-progress
branch: claude/keen-brahmagupta-egur6h
pr: none
plan: catchup-bound-first-parent
issue: none
session: https://claude.ai/code/session_01J1YMK5n638k2v3Vcg17JxV
agent: opus
updated: 2026-11-14
next: Run the verifier, record its findings, then ci, verify, finish and open the PR
---

## Goal

Stop green heads looping through full `finish` runs until STARVED on a fast
base (chrsctl/gx #1696). Asked by the owner: "Fix directly in joharness".

## Decisions

- Bound unit = first-parent commits of the base, not all commits: one per
  merged pull request; equals the old count where nothing merges with a
  merge commit. Default 10 (about one gx peak pass plus a retest lap).
- `IN REACH` is a new refusal token, deliberately without the substring
  `OUTRUN`, so a manager's count skips it.
- Plan written and built on one branch: the owner asked for the fix
  directly, and a separate plan pull request would sit in the queue while
  gx keeps starving.

## Rejected

- Counting first-parent merges only: a squash/rebase consumer has none and
  the bound would never bite.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:checks_in_reach` — the new reach test.
