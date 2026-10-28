---
workstream: map-in-the-loop
status: in-progress
branch: claude/map-in-the-loop
pr: none
plan: map-in-the-loop
issue: none
session: https://claude.ai/code/session_01W18Uk51vWUnKgHZiX9b4KR
agent: sonnet
updated: 2026-10-28
next: Read verify result; prove new map finish cases fail without finish_map; spawn verifier
---

## Goal

User ask: the folder map is part of the harness and the harness knows how to
generate it, so `finish` asks for `/map` when a branch changes the product
folder set, and `/map` builds the map on that branch.

## Decisions

- Only drift the branch caused fails: adding or removing a folder. Edits
  never fail, and old drift never fails. A branch is not blocked by work it
  did not do.

## Rejected

- A dispatch item for the map: a whole session for one file the change's
  own session can write in its own pull request.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:map_scan` — the rows finish reads.
