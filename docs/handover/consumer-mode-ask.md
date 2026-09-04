---
workstream: consumer-mode-ask
status: in-progress
branch: claude/drain-session-access-r80jpt
pr: none
plan: consumer-mode-ask
issue: none
session: https://claude.ai/code/session_01HkdcTFBBEsYFS3MKbxjZ3R
agent: sonnet
updated: 2026-09-04
next: Implement the --mode flag and the ask in bootstrap-consumer.sh, then the selftest cases.
---

## Goal

Requester asked for an automatic mode that drains the queue with no human turn
between items, then narrowed it: it must be a switch that is off by default,
and the copy into a child must ask for it. The mode exists; the ask does not.

## Decisions

- **The mode itself is not rebuilt.** `JOHARNESS_MODE=unsupervised` already
  does what was asked at the session level, and `run_mode` already fails
  closed. Only the child-side ask is missing.
- **Canonical stays supervised.** "Not enabled by default" is the requirement,
  and flipping this repo would be a separate operational act with the
  heartbeat's spend attached.
- **A single session looping over items was rejected** in favour of the
  existing fresh-session-per-item shape. The reason is measured, not
  stylistic: compaction preserves task state and drops the rules, violations
  move from 0% to 38% when the constraint is dropped from the summary, and the
  decay is 8.3x worse for soft organisational policy, which the Loop is
  (`.agents/docs/handover/README.md`, Compaction).
- **The whole-clone path forces the answer rather than inheriting it.**
  `JOHARNESS_ENV` is rewritten only when `--env` says so, because silently
  forcing `none` would strip a deliberate selection. The mode is the opposite
  case: inheriting canonical's autonomy is precisely the failure `run_mode`'s
  own comment names, a fleet working unattended in a repo that never asked.

## Rejected

- (to fill as the build finds them)

## Review

(to fill at step 5)

## Blockers

None.

## Where to look

- `.agents/scripts/bootstrap-consumer.sh` — first contact; seeds a fresh conf
  inline and rewrites a whole clone's.
- `joharness.sh:run_mode` — the fail-closed reader of that conf.
