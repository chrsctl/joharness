---
workstream: scoped-local-check-certificate
status: in-progress
branch: research/scoped-local-check-certificate
pr: none
plan: scoped-local-check-certificate
issue: none
session: https://claude.ai/code/session_01J1YMK6E2zwtx5Lt8Mtzzk1
agent: opus
updated: 2026-11-11
next: Retire, open the PR, finish, merge
---

## Goal

Settle docs/research/scoped-local-check-certificate.md: does local-mode
`finish` certify a scoped `local-check` green, and does a STARVED head need a
human. Graduate the answer to `.agents/docs/consumer-repos.md`, delete the file.

## Decisions

- Question (1) settled: defect. `checks_gate` writes the certificate on
  `rc=0 && catchup=0`; `checks_local_check` returns only the exit code.
- Question (2) settled: defect. `conflict:` is a plain human block in
  dispatch (`block_reason_ok`, `n_blocked` line); no STARVED exemption.
- Scoped-green contract: a git-dir marker path handed to `local-check` in
  `JOHARNESS_LOCAL_CHECK_SCOPED`, not a reserved exit code (a real failure
  exiting with it would pass). Interface: flagged for a human in the PR body.
- STARVED: resume unasked up to a bound, then ask with
  `starved-counts-green-runs`' human choices; both new plans `needs:` it
  (shared checks.sh, manager.md, manager-reference.md).
- gx figures stay WEAK: no second context here can re-take a consumer's
  history; they motivate, they do not settle — both settle criteria are
  canonical source.

## Rejected

- None yet.

## Review

- r1: (verifier) scoped green leaves no certificate, so starved-counts' NOT OUTRUN sends a green head to "fix the red" (fixed: scoped green writes a separate record OUTRUN reads, catch-up ignores; case 5)
- r2: (verifier) case 4 passes on origin/main, cannot fail without the fix (fixed: case 4 is a stale-marker guard, acceptance names 1 and 5 as the failing cases)
- r3: (verifier) resume bound read from the manager's own next: text, resettable; JOHARNESS_RESPAWN_LIMIT is per run (fixed: dispatch counts block commits in git, own knob)
- r4: (verifier) doc claimed a verifier re-read before one had (fixed: now cites this verifier's r4, which re-read checks_gate and checks_local_check)
- r5: (verifier) plan named dispatch-order.sh, the waiting-on cases are in dispatch-park.sh (fixed)
- r6: (verifier) 33 of 69 is not most (fixed: about half or more)
- r7: (verifier) consumer interface written as decided (fixed: doc says proposed, human may veto; PR body flags it)

## Blockers

None.

## Where to look

- `joharness.sh:checks_gate` — writes `joharness-finish-cert`.
- `.claude/commands/manager.md` §3/§4 — STARVED block.
