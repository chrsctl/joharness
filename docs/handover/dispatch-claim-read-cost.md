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
next: ci and verify green (verify hit Docker Hub 429 once), then the verifier at opus
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

## Measurements (2026-10-28, this container, 4 CPUs)

Old build = worktree at the merge base ca892f00, `CLAUDE_PROJECT_DIR` at
this checkout where a command reads this repo. Masking sed (`sed -E -f`),
applied to both sides before `diff`:

```
s/[0-9]+(m|h|d)( ago| since|  |$| \(|\)|,|:| \.|;| --|\.)/AGE\2/g
s/[0-9]+ (second|minute|hour|day|week|month|year)s? ago/AGE ago/g
```

- Slope, the run-5 wrapper rebuilt: in a scratch worktree per build,
  `dsp()`/`dfx()` log `<name> <git for-each-ref refs/remotes/origin | wc -l>
  <seconds>` per call, and `selftest_unit` skips topics not in `ST_ONLY`;
  `ST_ONLY=dispatch JOHARNESS_SELFTEST_JOBS=1 bash .agents/harness/selftest.sh`,
  old then new back to back, nothing else running; least-squares fit per
  wrapper. Last pair (run E, head 7a0d8a3e's code): `dfx` old 0.460 s per
  ref, new 0.219 (0.48x), total 134.4 s -> 67.9 s; `dsp` old 0.163, new
  0.105 (0.64x). Earlier pairs on earlier heads: old 0.424 / 0.476 / 0.475,
  so against the plan's written 0.42 the new slope is 0.52x; against every
  old arm measured back to back, 0.46x-0.48x.
- Execs per claim branch (strace, the n=8/n=32 fixture of the Profile, head
  of run E's code minus the last two commits): git 26.7 (was 55), other 26
  (was 68).
- `JOHARNESS_SELFTEST_JOBS=1 bash .agents/harness/selftest.sh`: old 3795
  passed, 0 failed, 1 skipped; new 3800 passed, 0 failed, 1 skipped. Sorted
  `grep -E '^  (PASS|FAIL|SKIP) '` lines identical but for two measured-time
  lines, the five lines of the new cache case, and one count a case name
  carries: "a hook that may fetch has the merge bases read again (4 then 6)"
  now "(2 then 4)" — fewer merge bases asked, the count it bounds.
- `DISPATCH_FETCH=0 DRAIN_FETCH=0 ./joharness.sh dispatch` and
  `./joharness.sh release` on this checkout, old then new: identical after
  masking (dispatch 34 lines, release 11). Also identical on the `dfx`
  snapshot (19 refs), the 32-branch fixture, and an overlap fixture.
- SHIPS: consumer scratch repo bootstrapped from the old worktree
  (`bootstrap-consumer.sh --env none`), two claim branches, `dispatch`
  before, `sync-to-consumer.sh` from this branch (3 updated), `dispatch`
  after: identical after masking (30 lines).
- This checkout, one `dispatch`: 6.1 s -> 5.8 s; the handover hook 2.6 s ->
  1.5 s, the queue hook 0.69 -> 0.53 s.

## Decisions

- A1: confirmed — the profile above: per-branch execs (55 git, 68 other per
  claim branch) and subshell forks, no single slow command; the largest one,
  the queue hook's overlap test, is forks, not git.
- A2: confirmed low — the real checkout's `dispatch` output is diffed old
  against new besides the selftest (see Measurements).
- "Call" = one `cmd_dispatch` run. Every cache is a shell variable, primed at
  the top of `cmd_dispatch` (`mb_prime`, again after a hook fetch) or lazily
  inside it (`base_issues_prime`); `release_write` and `release_report` run
  `cmd_dispatch` inside `$(...)`, so nothing it primes reaches the release
  code that pushes after it. No cache on disk.
- Ref names: the row loop and the handover hook now ask git with the full
  `refs/remotes/<name>` where they spelled `origin/<name>`; the two differ
  only when a local branch or tag is named `origin/<name>`, where the short
  spelling read the local one: a latent bug, not a contract.
- The queue hook's overlap helpers set `HIT` instead of printing into
  `$(...)`, and `scope_split` replaces `scope_lines` plus two pipelines
  with builtins: same splitting, trimming and `shared:` rule.
- The handover hook lists only unmerged refs (`--no-merged`), push time and
  age ride on that listing, one merge base per ref is kept for its three
  readers, churn is one `log --name-only` (root commits shown as nothing,
  as `diff-tree` showed them) and its sort runs only once the paths can
  reach the threshold.
- Memo lookups cut with `%%` and a substring (`memo_get`): bash's
  `${memo#*key}` cost 10 ms a lookup on a 33-line memo, quadratic, and
  `base_mb` already paid it per ref per reader.
- Parked rows run `dispatch_defect_state` outside `$(...)` (its line in
  DEFECT_STATE), so the retired plans its walk reads are `show`n once per
  call (PNI_MEMO), and its file history is read once for both walks.
- Ages read the clock with bash's `printf '%(%s)T'` where it exists (4.2+),
  `date` otherwise: the same instant, no exec.
- Left alone: the queue hook's per-plan `git log --diff-filter=A -1` (one
  walk over `docs/plans` would simplify history over the directory, not the
  file, and can pick another add commit) — per plan, not per branch.
- `REF_MEMO` holds the unmerged refs only: over all 455 refs here, bash's
  `${var#*pattern}` made each lookup a scan and the call took 18 s.

## Rejected

- None yet.

## Review

- r1: (plan-checker) "sorted PASS/FAIL/SKIP lines identical" contradicts the new cache case, and names no command (fixed: plan says identical but for the new case's lines, measured-time lines and the shipped-file count, and names the grep)
- r2: (plan-checker) "call" reads as process or as `cmd_dispatch` run; `release_write` runs `cmd_dispatch` in-process (fixed: plan and Decisions say one `cmd_dispatch` run; the nested runs are in `$(...)`)
- r3: (plan-checker) a two-process case passes for any in-memory cache (fixed: plan says the case catches a cache kept on disk; the in-process reading rests on the `$(...)` nesting, Decisions)
- r4: (plan-checker) the run-5 wrapper exists only as prose, `ST_ONLY` is no runner knob (fixed: plan points at the wrapper this workstream file records)
- r5: (plan-checker) only the `dfx` slope is gated, `dsp` is the larger share (no change: the plan gates `dfx`; `dsp` is measured and recorded beside it)
- r6: (plan-checker) no item compares `release` output (fixed: plan adds `release` on the real checkout, old against new, masked)
- r7: (plan-checker) "first commit" and "per claim branch" undefined (no change: the first commit after the claim, counted as a difference between fixtures of 8 and 32 claim branches, Profile)
- r8: (plan-checker) masking sed and old build unspecified (fixed: plan says the old build is a worktree at the merge base; the sed is in this file)
- r9: (plan-checker) consumer clone and sync command unnamed (fixed: plan names them)
- r10: (plan-checker) "8 s late calls" unverified (wontfix: a pointer in Where to look, no acceptance rests on it)
- r11: (plan-checker) an existing per-branch cache (`evcache`) is not named (no change: the build extends `mb_prime`'s memo, no parallel mechanism)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — the per-branch walk.
