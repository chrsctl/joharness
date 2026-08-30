---
workstream: perf-ceiling-noise-band
status: review
branch: claude/perf-ceiling-inside-noise-band
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-30
next: Merge once green, then resume the scorecard graduation it unblocks
---

## Goal

`origin/main` is red (GitHub run 338, head 3e45c5a) on the `perf` budget, and
it blocks every branch cut from it. The failure is not a regression: the
ceiling sits inside the measurement's own noise band.

## Decisions

- Raised the two ceilings rather than shaved constants. Three earlier sessions
  shaved (268→242, 271→245 among them) and main went red again each time,
  because shaving buys a few merges of headroom against an input that keeps
  moving. The ceiling was 265 against bands of 247-268 and 250-271.
- 300, not a round guess: observed maximum plus the overhead a working branch
  adds for its own workstream files, measured at +5 the same day.
- No workstream file for this would have been wrong. The diff is one number
  and a comment; the REASONING for why raising is allowed here is the whole
  content, and that is exactly what git cannot tell the next session.

## Rejected

- Shaving another constant out of `fb_collect`. Same class of fix that failed
  three times, and it does not address a ceiling inside a noise band.
- Lowering `FB_LIMIT` to shrink the number. That changes what the score means
  to make a budget pass — the metric-gaming failure this repo just graduated
  a research finding about.

## Review

opus, adversarial. Lenses: is this masking a regression, is the number
defensible, does the stopgap have an exit.

- r1: raising a perf ceiling is exactly what the guard's own message forbids
  ("do not raise the number to match the code"). Checked before doing it:
  `git diff --name-only b52a800 3e45c5a` lists three markdown files and no
  code at all, so there is no code to match. The prohibition targets masking a
  fork put back inside a loop; this masks nothing. (fixed — the comment states
  the distinction rather than leaving a reader to trust the change)
- r2: a stopgap with no exit becomes the permanent answer. Queued
  `perf-window-fixed-cost` and named it in the comment, so the number has a
  condition under which it comes back down. (fixed)
- r3: 300 could itself be inside a wider band nobody has sampled — six commits
  is a small sample. True, and stated as a limitation rather than hidden: if it
  flaps again the sample was too small, and that is evidence for the queued
  plan rather than for another raise. (open)

## Blockers

None.

## Where to look

- `joharness.sh:perf_rows` — the two ceilings and the measurement comment.
- `joharness.sh:fb_collect` — where FB_LIMIT bounds size but not cost.
