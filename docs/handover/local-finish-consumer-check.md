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
next: Second verifier pass on the r1-r6 fixes, then retire and open the PR
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
  `num_knob` still honours a conf line for it, as for every numeric knob.
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

- r1: (verifier) a branch deleting `local-check` passed with no CHECK CHANGED (fixed: diff stat taken before the absence check; selftest `kclcgone`)
- r2: (verifier) Ctrl-C on finish left the check's own process group and the watcher running (fixed: INT/TERM/HUP trap in `checks_bounded` kills the group and watcher, removes temp files)
- r3: (verifier) the KILL step never ran when the leader died on TERM, so a TERM-ignoring child outlived finish (fixed: watcher polls the group 5 s then KILLs; main waits it when the bound fired)
- r4: (verifier) the timeout selftest passed without the group kill; non-executable assertion read only the header (fixed: TERM-ignoring child's pid asserted dead; asserts `local-check: pass` with the bit checked)
- r5: (verifier) help, github-mode text, session-start banner and the pass line still said ci and verify only (fixed: all four name the declared check; pass line adds `local-check too` when one ran, keeping step 7's prefix)
- r6: (verifier) eol advice pointed at the synced root `.gitattributes`, which marks it AHEAD (fixed: doc names the CRLF break and a per-clone `.git/info/attributes` pin)
- r7: (verifier) N1-N3: conf line honoured for a session-scope knob, millisecond race at the bound, assume-unchanged hole shared with ci (no change: N1 recorded under Decisions; N2 not reproducible below the bound; N3 is ci's hole too)

## Blockers

None.

## Where to look

- `joharness.sh:checks_gate` — the local-mode gate this extends.
