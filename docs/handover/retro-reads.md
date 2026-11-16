---
workstream: retro-reads
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

The human, after gx's retro of 2026-11-16: fix the retro reviewer's
shallow read on the fast path and merge. That reviewer read one page of
30 transcript events per session (the session's END), not the 200
(`JOHARNESS_RETRO_EVENTS`) `retro.md` §2 asks for, then logged all three
rows `nothing`. The ledgers here and in gx are almost entirely
`nothing`. Nothing measured the read.

## Decisions

- Mechanism, not a rule: `ci` stage `retro reads` reds a session row a
  branch ADDS to `docs/retro-log.md` unless its outcome cell ends
  `(read <n>)` with n >= `JOHARNESS_RETRO_EVENTS`, or `(read <n>, start)`,
  or notes `no transcript:`. CONCERN rows are exempt (transcript
  optional, §2). Earlier rows are never read.
- The count is the reviewer's own word; `joharness.sh` cannot call
  `list_events` (harness commands call no remote API). The stage turns a
  silent short read into a written claim the PR shows.
- Suffix in the outcome cell, not a fifth column: `retro_logged` finds the
  session column by name, but a new column would change the header every
  existing ledger carries.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:lint_retro_reads` — the stage.
- `.agents/harness/selftest/retro.sh` — its cases, last block.
