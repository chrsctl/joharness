---
workstream: map-in-the-loop
status: in-progress
branch: claude/map-in-the-loop
pr: 673
plan: map-in-the-loop
issue: none
session: https://claude.ai/code/session_01W18Uk51vWUnKgHZiX9b4KR
agent: sonnet
updated: 2026-10-28
next: ci green, then prove cases fail without finish_map, verifier, verify when docker pulls work
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

- r1: three finish cases refuted `== map`, which verbose mode prints on a pass too; `ci -v` leaked verbose into the fixture and failed them — cases now pin `JOHARNESS_VERBOSE=''` and refute `run /map` (fixed)
- r2: (verifier) a branch that only moves files into a new folder (`git mv a/f n/f`) passed finish: `--diff-filter=AD` drops renames, so the new folder never counted; same for a mapped folder emptied by a move — diff now runs `--no-renames`, selftest case `mapmove` (fixed)
- r3: (verifier) Loop step 4 sentence differs from the plan's — the plan predates the incremental-adoption ask; plan text updated to the sentence in force (fixed)

## Blockers

None.

## Where to look

- `joharness.sh:map_scan` — the rows finish reads.
