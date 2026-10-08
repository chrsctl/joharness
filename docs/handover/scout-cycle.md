---
workstream: scout-cycle
status: in-progress
branch: claude/scout-cycle
pr: none
plan: scout-cycle
issue: none
session: https://claude.ai/code/session_01JXryjCKHhwkN7Xrv1qXz55
agent: opus
updated: 2026-10-08
next: Reverted-fix proofs, then edge review (opus: adversarial lenses + verifier)
---

## Goal

`docs/product/scout-role.md`, second bullet: the scout cycle's MACHINERY —
one reader `dispatch` and `drain` both ask, a `scout : DUE` tail line only
at DRAINED, a cadence dated from git (merged retires AND closed proposal
branches), at most one in flight, two conf keys. What a spawned scout does
is `scout-command`. Supervised session at the human's ask (protocol text).

## Decisions

- dispatch spawns a scout ONLY under `DRAINED — nothing free, nothing in
  flight` (the exit verdict). The other two DRAINED verdicts still have a
  manager in flight or a spawn pending — real work running — so a due scout
  there prints `suppressed`. drain has one DRAINED and gates on it.
- Branch half = ONE `git grep -l` over every unmerged ref, not
  janitor_branches' per-ref `ls-tree`: drain asks at every session start and
  a per-ref fork is what `perf` catches. A hit the base branch also carries
  is inherited and skipped (`cat-file -e`), standing in for the merge-base diff.
- Merged half = `cycle_age_h scout` (landing time, glob
  `scout-[0-9]*.md`); branch half = newest stamp's date at midnight UTC,
  by awk civil-from-days (no `date -d` on BSD). Newest of the two wins. The
  stamp reading overstates age by up to 24h — a scout dated today reads 0-23h.
- The walk runs only when the merged half alone says due: it can only turn
  due into not-due.
- drain budget 308 -> 320, counted: 292 -> 299, 302 -> 309 with
  JOHARNESS_CURATE_PLANS=1 (`./joharness.sh perf drain`, 2026-10-08).
- Selftest fixture names prefixed `scout_`: topics are sourced into one
  shell, and `swork` clobbered the perf topic's fixture of the same name.

## Rejected

- Per-ref walk copied from janitor_branches: drain read 301 / 311 on the
  shape, over the 308 budget — the regression in kind the budget exists for.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:janitor_due`, `janitor_branches`, `cmd_janitor` — mirrored.
- `joharness.sh:cycle_landed_sha` — the dating reader.
