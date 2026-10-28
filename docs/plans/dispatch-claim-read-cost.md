---
plan: dispatch-claim-read-cost
urgency: normal
agent: opus
effort: high
needs: selftest-split-heavy-topics
requirement: none
serves: all
issue: none
scope: shared:joharness.sh, .agents/harness/queue-context.sh, .agents/harness/handover-context.sh
---

## Goal

`joharness.sh dispatch` costs about 0.45 s per claim branch in a selftest
fixture (1.3 s with 4 origin branches, 8.7 s with 19), and the topics built
on it (`dispatch`, `dispatch-*`, `release`) are 53% of the selftest's serial
time (research `selftest-runtime`, F2). One call on the real checkout runs
499 git execs and 800 other programs, 58 git lines exact repeats (each
claim branch's `merge-base` twice, a handover file `show`n three times).
Halve the per-claim-branch cost without changing one line dispatch or
release prints. Estimated saving: up to ~26% of the suite's serial work;
NOT measured, the build measures it.

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
- Changing what dispatch prints, decides, or fetches.

## Acceptance

- First commit: a profile in the workstream file (git and non-git execs
  per claim branch, command named) before any code.
- `JOHARNESS_SELFTEST_JOBS=1 bash .agents/harness/selftest.sh`, sorted
  PASS/FAIL/SKIP lines identical before and after (bar measured-time lines).
- `DISPATCH_FETCH=0 DRAIN_FETCH=0 ./joharness.sh dispatch` on this checkout:
  byte-identical output before and after, at one commit.
- Git execs per `dfx` call on a 19-branch `dfwork` at most half of before;
  numbers and command in the workstream file.
- SHIPS: in a consumer checkout after the sync, `./joharness.sh dispatch`
  prints what it printed before the sync on the same refs (run by hand in a
  scratch clone, recorded in the workstream file).
- `./joharness.sh ci` and `./joharness.sh verify` green.

## Where to look

- `joharness.sh:cmd_dispatch` — the per-branch walk.
- `joharness.sh:dispatch_branch_plans`, `joharness.sh:dispatch_tip_holds`,
  `joharness.sh:dispatch_done_evidence` — per-branch git.
- `.agents/harness/selftest/dispatch.sh:dfx` — the fixture whose late calls
  cost 8 s.

## Traps

- A cache must not outlive one call: dispatch reads refs that `release`
  in the same session moves.
- Never skip, disable or quarantine a case to get green.
