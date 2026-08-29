---
workstream: finding-id-lint
status: in-progress
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: finding-id-lint
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Read every anchor the plan names before writing the stage.
---

## Goal

A third of recorded findings reach nothing: the fix map keys on
`^\+- r[0-9]+:`, so a bullet without an id-then-colon is invisible to the
loop that serves findings back. A `ci` stage names the malformed bullets on
this branch's diff. WARN, never red.

## Decisions

- Reading every anchor the plan names, in full, before writing a line. Last
  plan the anchor was read for the section I wanted and not the eleven lines
  that mattered, and the fix reinstated a rule this repo had rejected three
  times. That cost a verifier round and a full revert.

## Rejected

- (nothing yet)

## Review

(no round yet)

## Blockers

None.

## Where to look

- `joharness.sh:fb_fix_map` — the `^\+- r[0-9]+:` match that decides
  attribution. This is the form the stage must check against.
- `joharness.sh:fb_collect` — the inline `${line%%:*}` id classifier.
- `joharness.sh:review_count` — a LOOSER rule (`^- `) on purpose. Two
  counters, two questions; the plan's first Trap is not to conflate them.
- `.agents/docs/feedback.md`, "What this cannot see" — the blind spot.
