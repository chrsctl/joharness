---
workstream: role-fetch-before-authority
status: in-progress
branch: claude/brave-fermi-ojiuzy
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01J1YMK7C7gGMPF2Vwvhy3ks
agent: sonnet
updated: 2026-11-16
next: Run ci and verify, then the verifier at haiku, then open the PR and merge
---

## Goal

The human, after gx's clerk of 2026-11-16 14:39 stopped: fix it on the
fast path and merge. Three gx role sessions that day (clerk 04:06, retro
06:49, clerk 14:39) stopped `STOP: authority NOT VERIFIABLE` on clean
checkouts. Their checkout was current main, but the container's
`origin/main` ref was from an older clone, and `./joharness.sh role` ran
authority before its fetch: every rule merged since read as drift.

## Decisions

- `cmd_role` fetches `origin/<base>` into its remote ref before
  authority. The fetch moves the remote ref only, never the checkout, so a
  rule edited in the checkout still stops the prelude (selftest case). A
  failed fetch is ignored: authority then reads the ref as before.
- `./joharness.sh authority` run alone is unchanged: it reports and gates
  nothing; only the role prelude stops on it.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_role` — step (1).
- `.agents/harness/selftest/role.sh` — the stale-ref block.
