---
workstream: guard-one-shot-self-kill
status: in-progress
branch: manage/guard-one-shot-self-kill
pr: none
plan: guard-one-shot-self-kill
issue: none
session: https://claude.ai/code/session_018CFG96U4CTEwdURbAw9ENb
agent: sonnet
updated: 2026-10-24
next: Build the unregistered hook and selftest topic, then open the human/ PR
---

## Goal

Deny one-shot `pkill -f` / `kill $(pgrep -f)` self-matches. Plan: docs/plans/guard-one-shot-self-kill.md.

## Decisions

## Review

- r1: `env X=1 pkill -f`, `sudo -u x pkill -f`, `time pkill -f` bypass the copied rpos prefix list (verifier) (wontfix: rpos is copied from pretool-bash-guard.sh by plan; widening one copy forks the two readers)
- r2: a second `-f` pattern after one bracketed pattern is excused (verifier) (wontfix: multi-pattern pkill is rare; the incident shape is denied)
- r3: `pgrep -f x | xargs kill` not covered (verifier) (wontfix: out of plan scope)
- r4: `echo 'pkill -f foo'` denied, quote counts as command position, same as the sibling guard (verifier) (wontfix: inherited rpos; bracket spelling avoids it)
- r5: edge review: fails open on bad stdin, 0 externals under empty PATH, ci pass, verify 6 passed 0 failed (no change)

## Blockers

None.

## Where to look

- `.agents/harness/pretool-bash-guard.sh:rpos`
