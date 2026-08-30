---
workstream: perf-ceiling-resample
status: in-progress
branch: claude/perf-ceiling-resample
pr: none
plan: perf-ceiling-resample
issue: none
session: https://claude.ai/code/session_01TX1g3uTiU2k5ttr7WcQypK
agent: sonnet
updated: 2026-08-30
next: Sample perf feedback/review on >=5 detached origin/main worktrees (#141-#145), record in perf_rows comment, set new ceilings above the band + ~5 branch overhead.
---

## Goal

`docs/plans/perf-ceiling-resample.md`: #138 raised `feedback`/`review` ceilings
to 300 as a stopgap because 265 sat inside the measurement's own noise band.
#141 then cut per-edge cost from ~10.8 to ~8.8 commands. Several merges
(#141-#144) have landed since; sample the band the same way the earlier six
commits were sampled, and lower the ceiling to something that can detect a
regression again.

## Decisions

(none yet — recording as work proceeds)

## Rejected

(none yet)

## Review

(none yet — findings land here before their fix, same commit)

## Blockers

None.

## Where to look

- `joharness.sh:perf_rows` — the ceilings and the measurement comment (~line 1071).
- `joharness.sh:PERF_EDGES` (line 891) — vary this in the file, not via
  `JOHARNESS_FEEDBACK_EDGES` env (perf_count overrides the env var with this).
- Sampling loop pattern already in the comment above `perf_rows`, e.g.:
  `for c in $(git log --merges --format=%h origin/main -6 | tac); do git worktree add -q --detach "$W" "$c"; (cd "$W" && JOHARNESS_PERF=always ./joharness.sh perf review); done`
