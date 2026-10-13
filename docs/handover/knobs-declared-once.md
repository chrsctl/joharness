---
workstream: knobs-declared-once
status: in-progress
branch: knobs-declared-once
pr: none
plan: knobs-declared-once
issue: none
session: https://claude.ai/code/session_01EJJz7ZFSfQFyfga4i4LXKK
agent: sonnet
updated: 2026-10-13
next: run ./joharness.sh ci (slow, background) and verify; if green retire plan+workstream in last commit, open PR, merge
---

## Goal

Give joharness.sh one KNOBS table, a `conf` command printing live values, and a selftest keeping table, doc and conf-keys.sh in agreement (plan docs/plans/knobs-declared-once.md).

## Decisions

- KNOBS is a variable fenced by KNOBS-BEGIN/END in joharness.sh; num_knob reads static default from it when called with one arg; cmd_conf prints rows. Selftest topic knobs-declared registered after num-knob. Doc table gained 3 clerk rows.

## Rejected

## Review

- r1: (verifier) unvalidated session keys print the raw env string; RECURRENCE_WINDOW=abc shows abc, reader uses 8 (fixed: window case; FEEDBACK_EDGES and PENDING_SPAWNS readers are raw, so raw is what they return: no change)
- r2: (verifier) JOHARNESS_CANONICAL shown as set from env, readers only grep the conf (fixed)
- r3: (verifier) base-conf row shows a normalized value under source env/base conf with no note (fixed: "value not accepted, read as X")
- r4: (verifier) SCOUT_REVIEWER default prints none, KNOBS default empty (wontfix: none is the reader's answer, which the plan says to print)
- r5: (verifier) table default column never compared with KNOBS (fixed, with a failing-case test)
- r6: (verifier) conf cases uncovered: conf non-number, too long, canonical env, rejected login, recurrence (fixed: five cases added)

## Blockers

None.

## Where to look

- `joharness.sh:num_knob`
