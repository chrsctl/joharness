---
workstream: dispatch-claim-read-cost
status: in-progress
branch: manage/dispatch-claim-read-cost
pr: none
plan: dispatch-claim-read-cost
issue: none
session: https://claude.ai/code/session_01J1YMK4ss2KinjRSUaz7NWc
agent: opus
updated: 2026-10-28
next: Build the per-call reads (hooks first, then joharness.sh dispatch_* helpers), then measure old against new
---

## Goal

Halve the per-ref time of `joharness.sh dispatch` (and `release`) without
changing what it decides or prints: read each branch's facts once instead of
per-helper git calls. Plan `docs/plans/dispatch-claim-read-cost.md`.

## Profile (before any code)

Old build = `origin/main` at ca892f00. Per claim branch, from a fixture
modelled on `dfx` (`mk.sh <harness> <dir> <n>`: n claim branches, a quarter
each in-progress, `product:` blocked, `defect: #21` parked; plan files on
the base grow with n), counted with `strace -f -qq -e trace=execve` over one
`DISPATCH_FETCH=0 DRAIN_FETCH=0 ./joharness.sh dispatch`, n=8 and n=32,
difference over 24 (2026-10-28):

- git execs per claim branch: 55 ((1706 - 386) / 24)
- other execs per claim branch: 68 ((2210 - 570) / 24); awk, grep, sort, tr,
  sed, paste, head lead
- seconds: 2.88 (n=8), 12.68 (n=32): 0.41 s per branch

Where it goes (xtrace `PS4='+|${EPOCHREALTIME}|${FUNCNAME[*]}|'`, inclusive
time per function, same two fixtures, per branch): `dispatch_defect_state`
0.138 (of it `plan_names_issue` 0.108: every base plan `show`n once per
parked row), the two hooks 0.134, `cmd_dispatch`'s own row loop ~0.07,
`dispatch_branch_plans` 0.038, the release and edge readers ~0.04.

The `dfx` fixture itself (instrumented `dsp`/`dfx` wrappers logging origin
refs and seconds per call, `ST_ONLY=dispatch JOHARNESS_SELFTEST_JOBS=1`, a
loaded box: the full selftest ran beside it): `dfx` 41 calls, refs 2-19,
slope 0.461 s per ref; `dsp` 77 calls, slope 0.171. Its last state (19 refs,
39 plans) costs 10.2 s a call, of it the queue hook 4.3 s and the handover
hook 1.3 s. The queue hook's cost is the in-flight overlap test: one
`$(wave_split_hit)` per (free plan, claim) pair, each forking up to three
`$(scopes_overlap)` more, plus a `scope_lines` pipeline (6 execs) and two
`printf | grep | paste` per claim. The handover hook pays per ref two
`git log -1` (push time and age), three `merge-base`, a `diff-tree` per
commit for churn, and ~20 small execs (grep, comm, sort, awk).

On this repository (19 unmerged of 455 refs): 528 git and ~640 other execs,
6.1 s; the hooks 2.4 s and 0.55 s of it.

## Decisions

- Claimed; profile above.

## Rejected

- None yet.

## Review

- None yet.

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — the per-branch walk.
