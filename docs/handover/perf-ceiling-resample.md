---
workstream: perf-ceiling-resample
status: review
branch: claude/perf-ceiling-resample
pr: none
plan: perf-ceiling-resample
issue: none
session: https://claude.ai/code/session_01TX1g3uTiU2k5ttr7WcQypK
agent: sonnet
updated: 2026-08-30
next: Open PR once ./joharness.sh ci is green; merge own PR once checks green and 0 behind origin/main.
---

## Goal

`docs/plans/perf-ceiling-resample.md`: #138 raised `feedback`/`review` ceilings
to 300 as a stopgap because 265 sat inside the measurement's own noise band.
#141 then cut per-edge cost from ~10.8 to ~8.8 commands. Several merges
(#141-#144) have landed since; sample the band the same way the earlier six
commits were sampled, and lower the ceiling to something that can detect a
regression again.

## Decisions

- Sampled 5 origin/main merge commits since the per-edge cut (#141-#145,
  hashes 1a648c8/84638a9/81d0391/b8c1cd7/f88cd94), each in a detached
  worktree, `JOHARNESS_PERF=always ./joharness.sh perf feedback`/`review`.
  Result: feedback 234/234/234/249/249, review 237/237/237/252/252.
- Measured the branch overhead directly instead of assuming the earlier
  `~+5`: this workstream's own branch (one commit ahead of #145) measures
  review 257 against #145's base 252 — confirms +5. feedback stayed flat
  (249 vs 249) because its walk is merged edges only, unaffected by an
  unmerged commit.
- New ceilings sit above (observed max + overhead) with a few counts of
  headroom, not maximal padding like the old 300: feedback 254->260,
  review 257->263.

## Rejected

(none)

## Review

- r1 (code-review, high, self): workstream file's `status`/`next`/`Decisions`
  were not updated in the same commit as the `joharness.sh` ceiling change,
  violating the same-commit handover rule. (fixed: this commit updates both
  together.)

## Blockers

None.

## Where to look

- `joharness.sh:perf_rows` — the ceilings and the measurement comment (~line 1071).
- `joharness.sh:PERF_EDGES` (line 891) — vary this in the file, not via
  `JOHARNESS_FEEDBACK_EDGES` env (perf_count overrides the env var with this).
- Sampling loop pattern already in the comment above `perf_rows`, e.g.:
  `for c in $(git log --merges --format=%h origin/main -6 | tac); do git worktree add -q --detach "$W" "$c"; (cd "$W" && JOHARNESS_PERF=always ./joharness.sh perf review); done`
