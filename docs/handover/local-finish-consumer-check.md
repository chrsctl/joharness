---
workstream: local-finish-consumer-check
status: in-progress
branch: claude/local-finish-consumer-check
pr: none
plan: local-finish-consumer-check
issue: none
session: https://claude.ai/code/session_01473SJGCfbPForWe43xj3sc
agent: opus
updated: 2026-10-23
next: Run ci and verify, then verifier review at opus
---

## Goal

Under `JOHARNESS_CHECKS=local`, let a consumer put ONE command
(`local-check` at its repository root) behind `finish: pass`, so its own
required checks gate the merge instead of prose (gx #785).

## Decisions

- Bound by a process-group watcher (`checks_bounded`, `set -m` + kill
  `-pgid`), not timeout(1): one code path on Linux and macOS, and the
  check's children die with it.
- `JOHARNESS_LOCAL_CHECK_MINUTES` is `session` scope in KNOBS: `conf` scope
  would need conf-keys.sh and the bootstrap heredoc, outside this plan.
  0 = one second (no zero bound: a timeout is never a skip); the selftest
  uses it.
- Declared = tracked in HEAD (`git cat-file -e HEAD:local-check`); an
  ignored worktree copy is named and not run. The clean-tree refusals make
  the worktree copy the head's, so `bash local-check` keeps `$0` useful.
- Research `local-checks-consumer-command` is not on the base branch:
  nothing to graduate. `sync-to-consumer.sh` needs no edit (FILES/DIRS
  never name the path).

## Rejected

- Running `git show HEAD:local-check` from a temp file: breaks a check that
  locates itself via `$0`.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:checks_gate` — the local-mode gate this extends.
