---
workstream: selftest-exec-budget
status: in-progress
branch: claude/selftest-exec-budget
pr: none
plan: selftest-exec-budget
issue: none
session: https://claude.ai/code/session_01DbKVTgyQe9eSSKFCEcgi1Z
agent: opus
updated: 2026-10-14
next: ci -v on the merged head is running; set the default to its count plus a tenth, verify, retire, PR, merge
---

## Goal

Bound the selftest's git execs with a counted budget in `ci_selftest`, and
remove invocations in dispatch/clerk/scout topics that re-run the same
command on the same fixture state.

## Decisions

- Re-runs on unchanged state, found by scanning every wrapper call pair with
  only assertions between (scratch script, not kept): two in dispatch.sh
  (the `dsp` after the PENDING_SPAWNS=1 case, the MAX_MANAGERS=20 run after
  `after`), none in clerk.sh, one in scout.sh (`out2="$(cdt)"`) that IS the
  assertion (a re-run picks the identical sample) and stays. The plan's
  premise of many removable re-runs did not hold; the budget is the main lever.
- The count line prints on red and under `ci -v`, NOT on a green quiet ci.
  The plan asked ci to print it; ci-output.sh pins "a green ci prints one
  verdict line and nothing else", an older settled rule (quiet ci exists
  because managers mis-read noise). Quiet wins; acceptance reads `ci -v`.
- Baseline 2026-10-14, origin/main fe6b55c, counting git first on PATH:
  `time bash .agents/harness/selftest.sh` = 897 s, 81130 git execs, 2764
  passed. Branch (before review fixes), `time ./joharness.sh ci`: 931 s,
  80435 execs.
- Invocation counts (direct ./joharness.sh plus wrapper calls, comments and
  wrapper definitions excluded, one grep pipeline per file): dispatch.sh
  213 -> 211, clerk.sh 34 -> 34, scout.sh 83 -> 83.

## Rejected

- Fixture cache: rejected in the plan (fixtures mutate in place; absolute origin URLs).

## Review

- r1: (verifier) exported git function makes command -v print git; wrapper execs itself forever (fixed)
- r2: (verifier) printf %q writes bash $'' quoting into a /bin/sh wrapper; dash miscounts a path with a tab (fixed)
- r3: (verifier) workstream file not updated in the commit that set the 89243 default (fixed)
- r4: (verifier) budget default names no command or date in the tree (fixed)
- r5: (verifier) plan acceptance open: invocation counts unquoted, final lowering commit missing (fixed)
- r6: (verifier) temp dir leaks when ci is interrupted mid-suite (wontfix: mktemp dir under TMPDIR, cleared with it; a trap in a function sourced by run_check costs more than a stray dir)
- r7: green quiet ci printed the selftest stage, red in ci-output.sh (fixed)

## Blockers

None.

## Where to look

- `joharness.sh:ci_selftest` — the stage the budget lands in.
