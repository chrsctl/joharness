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

- r1: an outcome holding `\|` was cut at the pipe, so its read count went unseen (fixed)
- r2: (verifier) SC2016 on the help lines' backticks reds `ci`'s shellcheck (fixed)
- r3: (verifier) a row with no leading pipe is never read (wontfix: `retro_logged` does not read it either, so the session stays unlogged and is sampled again)
- r4: (verifier) an empty or `-` session cell skipped the check (fixed)
- r5: (verifier) an earlier row edited on the branch was read as this branch's (fixed)
- r6: (verifier) a count wider than bash integers reddened (fixed)
- r7: (verifier) `(read 0, start)` reds (no change: an empty transcript is the `no transcript:` note)
- r8: (verifier) a new ledger file not yet staged is invisible to the diff (wontfix: `ci` gates the committed head; the file is committed before the pull request)
- r10: selftest `no sed uses \t or \| (BSD sed)` red on the stage's sed (fixed in ebfa564f)
- r9: (verifier) the gx 30-event figure has no command here (no change: read in this session with `list_events` on session_01J1YMK4JLtxU7ax7A1pWsfp, three calls at `limit` 30, each `has_more` true)

## Blockers

None.

## Where to look

- `joharness.sh:lint_retro_reads` — the stage.
- `.agents/harness/selftest/retro.sh` — its cases, last block.
