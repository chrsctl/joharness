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
next: Run ci, then verifier at review tier, then retire and open the PR
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

None yet.

## Blockers

None.

## Where to look

- `joharness.sh:checks_gate` — writes `joharness-finish-cert`.
- `.claude/commands/manager.md` §3/§4 — STARVED block.
