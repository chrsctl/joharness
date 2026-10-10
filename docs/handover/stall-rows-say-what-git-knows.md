---
workstream: stall-rows-say-what-git-knows
status: in-progress
branch: manage/stall-rows-say-what-git-knows
pr: none
plan: stall-rows-say-what-git-knows
issue: 283
session: https://claude.ai/code/session_015AjcweMJ4sZHA4LAqqMhrM
agent: opus
updated: 2026-10-10
next: ci + verify green, verifier review, retire, PR, merge
---

## Goal

Issue #283: `dispatch` says three things without evidence — `PR in flight`
(it never reads a PR), `respawn on the branch to FINISH it` on a STALL? edge
row (verdict belongs to orchestrate.md's health table), and nothing when the
whole fleet is silent and `main` frozen (a suspension, not N dead managers).

## Decisions

- Base age read through `dispatch_age_min <base>`: the one `git log -1
  --format=%ct` the plan allows, already `</dev/null`, already the unit
  the stall test uses.
- Stopped-fleet fixtures get their own repo: the condition is about EVERY
  row in flight and the base's own age, both decided elsewhere in the
  shared fixture. A third case (window 180m: row stalls, 24x does not)
  pins the multiple, not just the 1x test.
- Built without workers: three files, ~100 lines, and orchestrate.md must
  change in the same commit as dispatch's row text (plan Traps).

## Rejected

- Printing the line on 1x stall window: with one manager in flight the base
  only moves when it merges, so it fires on every ordinary stall (plan).

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — edge_rows text, verdict tail.
