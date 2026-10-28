---
plan: dispatch-claim-read-cost
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: shared:joharness.sh, .agents/harness/queue-context.sh, .agents/harness/handover-context.sh, shared:.agents/harness/selftest/dispatch.sh
---

## Goal

`joharness.sh dispatch` in a selftest fixture costs 0.15 s (`dsp`) to
0.42 s (`dfx`) per origin ref (linear fits), and the topics built on it
(`dispatch`, `dispatch-*`, `release`) are 53% of the selftest's serial time
(research `selftest-runtime`, F2). One call on this repository's checkout
execs 499 git and 617 other programs; 58 of 530 git lines are exact repeats
(a branch's `merge-base` twice, a handover file `show`n three times). Halve
the per-ref TIME of a call without changing what dispatch or release
decides or prints. Saving on the suite: at most half of 53%; not measured,
the build measures it.

## Scope

- `joharness.sh` — `cmd_dispatch`, `cmd_release` and the `dispatch_*`
  helpers they call per branch: read each branch's facts once (one
  `for-each-ref`, one `cat-file --batch` or a per-call cache keyed by ref)
  instead of per-helper git calls.
- `.agents/harness/queue-context.sh`, `.agents/harness/handover-context.sh`
  — only where a per-branch repeat lives there; profile first.

## Assumptions

- A1: per-branch git and helper-program execs, not one slow command, are the
  cost — evidence: research run 7 (git lines replay in 3.6 of 6.1 s;
  repeats listed) and run 5 (linear in branch count) — confidence: medium.
- A2: the dispatch family's selftest output is the full contract — every
  printed line has a case — confidence: low; check by diffing the real
  checkout's `dispatch` output before and after too.

## Out of scope

- The selftest's topic split and claim order: plan `selftest-split-heavy-topics`.
- Any other selftest edit than the cache case.
- Changing what dispatch prints, decides, or fetches.

## Acceptance

- First commit: a profile in the workstream file (git and non-git execs
  per claim branch, command named) before any code.
- `JOHARNESS_SELFTEST_JOBS=1 bash .agents/harness/selftest.sh`, sorted
  PASS/FAIL/SKIP lines identical before and after (bar measured-time lines).
- `DISPATCH_FETCH=0 DRAIN_FETCH=0 ./joharness.sh dispatch` on this checkout,
  old and new build run back to back on the same refs: identical output
  after masking clock-relative ages (the masking `sed` named in the
  workstream file; a line differing in anything but an age is a failure).
- Seconds per `dfx` call on the `dfwork` fixture at its 19-ref state, old
  against new, measured the same way: at most 0.5x; git exec count beside
  it. Numbers and command in the workstream file.
- A case in `.agents/harness/selftest/dispatch.sh` (or the file its fixture
  moved to): a ref moved between two calls in one shell is read fresh by
  the second; it fails if a cache outlives its call.
- SHIPS: in a consumer scratch clone, `./joharness.sh dispatch` before and
  after the sync, back to back on the same refs, ages masked as above:
  identical; recorded in the workstream file.
- `./joharness.sh ci` and `./joharness.sh verify` green.

## Where to look

- `joharness.sh:cmd_dispatch` — the per-branch walk.
- `joharness.sh:dispatch_branch_plans`, `joharness.sh:dispatch_tip_holds`,
  `joharness.sh:dispatch_done_evidence` — per-branch git.
- `.agents/harness/selftest/dispatch.sh:dsp` — a fixture call; plan
  `selftest-split-heavy-topics` may move the `dfx` fixture (8 s late calls)
  to `dispatch-park.sh`.

## Traps

- A cache must not outlive one call: dispatch reads refs that `release`
  in the same session moves.
- Never skip, disable or quarantine a case to get green.
