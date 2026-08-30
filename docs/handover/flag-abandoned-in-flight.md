---
workstream: flag-abandoned-in-flight
status: in-progress
branch: claude/flag-abandoned-in-flight
pr: none
plan: flag-abandoned-in-flight
issue: none
session: https://claude.ai/code/session_01HLUEzTRWX9SahJwiMrhDS4
agent: sonnet
updated: 2026-08-30
next: Implement the STALE demotion in handover-context.sh:rank_of's sort, add a selftest topic, update the rank table doc, then verify.
---

## Goal

The in-flight block ranks by closeness to merging (#129) but has no notion of
a branch that has stopped moving, so a genuinely abandoned edge entry can lead
the block ahead of live work. Confirmed on this checkout after a full
unshallow (2026-08-30): `origin/claude/multi-agent-orchestration-pr-jyli0w`
(workstream `pm-dispatch`, `pr: 10`) sits pushed 9 days ago, 662 commits
behind `main` — matching the plan's own measurement almost exactly. Four more
branches carrying a workstream file (`unsupervised-goal`, `upkeep-off-session`,
`defects-from-consumer-run`, `guard-docs-only-branch`) sit pushed 5 days ago,
374-432 behind.

## Decisions

- Demote via sort key, not a new rank tier: add a `stale` boolean as a new
  row field (inserted right after `fresh`), sorted between rank and push-time
  (`-k1,1n -k12,12n -k2,2n -k3,3`). A stale entry never leaves its rank, it
  just sorts after non-stale entries of the same rank — this makes "still
  prints when nothing else is in flight" and "still leads when it's the only
  entry at its rank" fall out for free, no special-casing needed.
- Behind-count git call gated on the age check already being true (age comes
  free from `pushed_at`, already computed for `fresh`). Keeps the added cost
  bounded to genuinely-old branches, not one extra fork per ref. Measured
  baseline before this change: `JOHARNESS_PERF=always ./joharness.sh perf
  session-start` -> 478 against a 700 budget.
- Defaults: `HANDOVER_STALE_SECONDS=518400` (6 days — the plan's own language,
  "silent 6 days or longer") and `HANDOVER_STALE_BEHIND=50` (comfortably below
  every measured stale case above, 374-662, while nowhere near what a
  same-day freshly-cut branch accumulates).

## Rejected

- (none yet)

## Review

(pending)

## Blockers

None.

## Where to look

- `.agents/harness/handover-context.sh:rank_of` and the pass-1/pass-2 loops —
  row shape, sort key, and the printed entry.
- `.agents/harness/selftest/handover-context-rank.sh` — fixture style to
  extend for the new `handover-context-stale` topic.
- `.agents/docs/handover/README.md`, In-flight order — table + prose to sync.
