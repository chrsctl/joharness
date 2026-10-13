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
next: Read /tmp/claude-0/st.log (full selftest) for FAILs, fix, then ./joharness.sh ci and verify, verifier review, retire plan+workstream, PR
---

## Goal

Give joharness.sh one KNOBS table, a `conf` command printing live values, and a selftest keeping table, doc and conf-keys.sh in agreement (plan docs/plans/knobs-declared-once.md).

## Decisions

- KNOBS is a variable fenced by KNOBS-BEGIN/END in joharness.sh; num_knob reads static default from it when called with one arg; cmd_conf prints rows. Selftest topic knobs-declared registered after num-knob. Doc table gained 3 clerk rows.

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:num_knob`
