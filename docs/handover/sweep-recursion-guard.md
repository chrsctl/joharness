---
workstream: sweep-recursion-guard
status: done
branch: claude/sweep-recursion-guard
pr: none
plan: none
issue: 165
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Retire this file, merge, THEN flip the mode on its own branch.
---

## Goal

`ci` recursed into itself and burned a GitHub runner for 42 minutes. Fix it
supervised, and land it before the mode is flipped.

## The recursion

Run 33414519009, job 99561939017 — the requester aborted it and asked why it
was slow. It was not slow, it was looping:

```
16:32:50   queue-context   197   350   ok (0s)
17:15:03   ##[error]The operation was canceled.
```

42 minutes on the `drain` row, which never printed, then hundreds of orphan
`bash` processes in repeating triples with pids climbing ~63,000 each time.

```
ci -> perf measures the drain row
   -> drain, unsupervised with an empty free queue, defers to the sweep
   -> sources runs ci
   -> perf measures drain ...
```

Every link correct on its own. The cycle closes only when the mode is
unsupervised AND the free queue is empty, so it sat latent on a supervised
main and fired the moment the mode was committed for the endurance run —
with my own pushed claim being what emptied the queue and completed it.

## Decisions

- **Guarded in `cmd_sources`, not in `drain`.** That is the link that costs,
  and any future caller reaching the sweep from inside a run of `ci` closes
  the same cycle by another path. A guard at the cheap end catches all of
  them.
- **It counts NOTHING when it fires.** A guard that stopped the recursion and
  still ran the detectors would have kept most of the cost.
- **`perf_count` sets the marker too**, so the `drain` row measures DRAIN. It
  was measuring a whole nested `ci` — a number describing the suite rather
  than the entrypoint, on the runs where it terminated at all.
- **THIS BRANCH DOES NOT FLIP THE MODE**, and that is the point. See r1.

## Review

Round 1, opus, self, with `mutate`.

- r1: **the boundary caught me, and it was an ORDERING error.** The first
  version of this work carried the recursion fix AND the committed mode flip
  on one branch. `joharness.sh` and `.agents/harness/selftest/` are protocol
  text (`joharness.sh:protocol_paths`), so once the flip was committed the
  branch was an unsupervised session editing the protocol that governs it —
  exactly what `docs/product/unsupervised-mode.md` forbids, and the handover
  guard said so.

  The content was never the problem; the ORDER was. A protocol fix has to be
  made supervised and merged BEFORE the flip, not alongside it. Split: this
  branch is the fix, made supervised, and the flip is a separate branch
  touching only `joharness.conf`, which is not protocol text. It also happens
  to be the right operational order — flipping before the guard existed is
  what produced the 42-minute run. (fixed)
- r2: I nearly reported the CI slowness as "the suite got bigger" — 1133
  cases makes that a plausible story. The log refutes it in one line: the
  hang is on a row that never printed, and an orphan-process list in
  repeating triples is the shape of a loop. (recorded)
- r3: SC2016 for the third time today — backticks inside a single-quoted
  `printf`, in the guard's own message. The message text wants them and the
  quoting forbids them, and I keep writing the former. (fixed)
- r4: verifier round owed and NOT run — standing instruction, twenty-seventh
  consecutive edge. (wontfix on this branch — issue #168)

## Verification

- `mutate joharness.sh` on the guard → reds **3**
- Before: 42 minutes, killed. After: `drain` row **483/700 in 3s**, `ci`
  complete in **156s**
- selftest **1133 passed, 0 failed** (up 5)

## Blockers

None.
