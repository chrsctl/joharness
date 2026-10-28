---
plan: selftest-split-heavy-topics
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: shared:.agents/harness/selftest.sh, .agents/harness/selftest/dispatch.sh, .agents/harness/selftest/dispatch-park.sh, .agents/harness/selftest/release.sh, .agents/harness/selftest/release-halt.sh, .agents/harness/selftest/ci-selftest-scope.sh
---

## Goal

`.agents/harness/selftest.sh` runs ~406 s on 4 CPUs because one topic,
`dispatch` (362 s), is the critical path while three workers idle. Research
`selftest-runtime` measured that cutting `dispatch` and `release` at their
fixture seams, and letting workers claim the longest units first, runs the
same 3736 cases in 327 s (-19.5%), at the floor (topic sum / 4). Build that.

## Scope

- `.agents/harness/selftest/dispatch.sh` — keep lines 1 to the line before
  `# --- a defect: block is PARKED, and RESUMEd once its fix retires`.
- `.agents/harness/selftest/dispatch-park.sh` — new topic: the topic header
  (same shape as the others), `step "joharness.sh dispatch: parked claims"`,
  then everything from that `# --- a defect:` line to the end, unchanged.
- `.agents/harness/selftest/release.sh` — keep lines 1 to the line before
  `# --- release --human (alias halt): a human's order`.
- `.agents/harness/selftest/release-halt.sh` — new topic: header,
  `step "joharness.sh release --human"`, then that section to the end,
  unchanged.
- `.agents/harness/selftest.sh` — list `dispatch-park` right after
  `dispatch` and `release-halt` right after `release` in `SELFTEST_TOPICS`.
  Add `SELFTEST_FIRST=( dispatch-park dispatch release scout release-halt
  dispatch-branch-plans bootstrap-consumer )`: `selftest_worker` claims the
  units whose first topic is named there first, in that order, then the
  rest in list order. Output still prints in list order (it already does:
  `selftest_shards` reads per topic). A `SELFTEST_FIRST` name that is not
  listed, or is not a unit's first topic, is FATAL beside the chain checks.
  The header records why (research `selftest-runtime`, graduated there).
- `.agents/harness/selftest/ci-selftest-scope.sh` — replace the written
  "16s of a 22s ci run" with words that carry no number.

## Assumptions

- A1: no code after `# --- a defect:` in `dispatch.sh` reads `dsp*` state,
  and none before it reads `df*` — evidence: `grep -nE 'dspwork|dsp\b|dspplan|dsppush'`
  and `grep -nE 'dfwork|dfx'` split by line — confidence: high.
- A2: no code after `# --- release --human` in `release.sh` reads `j*`
  state — evidence: `grep -nE 'jwork|jan\b|jdsp|jqueue|jcommit|jplan|jgone|jclaim|jconf'` — confidence: high.
- A3: the runner's function-name duplicate check passes, since functions
  move and none is copied — evidence: research run 6 — confidence: high.

## Out of scope

- Making `joharness.sh dispatch` cheaper: plan `dispatch-claim-read-cost`.
- Any change to a case, an assertion or a fixture command. A moved line is
  byte-identical.
- A knob for the claim order: a plain array, like `SELFTEST_CHAINS`.

## Acceptance

- `bash .agents/harness/selftest.sh 2>&1 | tail -n1` — the same counts as
  `origin/main` before the change (3736 passed, 0 failed, 1 skipped at
  d8cc1328, plus any cases merged since).
- `bash .agents/harness/selftest.sh 2>&1 | grep -E '^  (PASS|FAIL|SKIP) ' | sort`
  against the same on the merge base: differs only in lines printing a
  measured time or a file count.
- `time bash .agents/harness/selftest.sh` on 4 CPUs, before and after, both
  recorded in the workstream file with the command and the CPU count.
- A `SELFTEST_FIRST` entry naming an unlisted topic exits 1 with a message
  (a case in the runner's own checks, failing without the check).
- `./joharness.sh ci` and `./joharness.sh verify` green.

## Where to look

- `.agents/harness/selftest.sh:selftest_worker` — the claim loop.
- `.agents/harness/selftest.sh:selftest_chain_problems` — the FATAL style.
- Research `selftest-runtime` (git history of `docs/research/selftest-runtime.md`)
  — F3, F4.

## Traps

- Never skip, disable or quarantine a case to save time.
- Unit file indexes (`u<n>`) are list positions: claim order changes which
  index a worker takes first, never the index a unit has.
