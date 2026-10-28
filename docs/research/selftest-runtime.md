---
research: selftest-runtime
urgency: normal
agent: opus
effort: high
graduates: .agents/harness/selftest.sh
---

## Question

Where do the 493 s of `.agents/harness/selftest.sh` go? And which changes
cut that time most without dropping a case that fails without its fix?

## Echo

The selftests are about 24.8k lines (`cat .agents/harness/selftest.sh
.agents/harness/selftest/*.sh | wc -l`), about 1.6 times the code they
test. Two verifier runs of `time bash .agents/harness/selftest.sh` in a
cloud container with 4 CPUs and the default `JOHARNESS_SELFTEST_JOBS`
measured `real 8m13.848s` and `real 8m51.963s`. `ci-selftest-scope.sh`
writes "16s of a 22s ci run", which these measurements contradict.

Every branch whose diff touches harness code pays this on each `ci` and
`finish` (`ci-selftest-scope.sh` skips the suite otherwise). On a busy base, `finish`
had to be re-run three times in one session while main kept moving.
Rule: no case is skipped, disabled or quarantined to save time.

## Sweep

goal-directed: complete when the top topics by wall time are named with
their causes, covering at least 80% of the total, and each cause has a
proposed change with its estimated saving.

## What would settle it

- Per-topic wall time and git-exec count, measured with the command named.
- The serial chains (`SELFTEST_CHAINS`) and how much of the run they cover.
- Duplicate fixtures: repos built the same way in several topics.
- Cases that assert the same output twice.
- Per change: the saving, and the proof that no case loses its
  fail-without-the-fix property.

Settled either way: "no change saves over 20%" is an answer too.

## Method

All runs in this cloud container (4 CPUs, `nproc`), on `origin/main` at
d8cc1328, from a scratch `git worktree` whose runner carried an UNCOMMITTED
timing patch (none of it ships):

- `selftest_unit` writes `<topic> <start> <end>` per topic to `$ST_TIMING`
  (`date +%s.%N` around the `.` source) and exports `ST_TOPIC`.
- With `ST_GITLOG` set, a `git` shim ahead of the real one on the runner's
  `PATH` appends `$ST_TOPIC` per exec: the per-topic git-exec count.
- `ST_ONLY="<topics>"` replaces `SELFTEST_TOPICS` (chains emptied) after
  the list checks: one topic alone.
- Section times: every `# --- ` header line of `dispatch.sh` and
  `release.sh` rewritten by `sed` into `printf "SEC <epoch> <title>"`.
- Per-call cost: `dsp`/`dfx` in `dispatch.sh` wrapped to log seconds and
  `git for-each-ref refs/remotes/origin | wc -l` of the fixture.

Runs, each `bash .agents/harness/selftest.sh` from the worktree:

1. `ST_TIMING=t4` (jobs default = 4): wall time and per-topic time.
2. `ST_TIMING=tg ST_GITLOG=git.txt`: git execs, `sort git.txt | uniq -c`.
3. `JOHARNESS_SELFTEST_JOBS=1 ST_TIMING=t1`: uncontended per-topic time.
4. `ST_ONLY="dispatch release" JOHARNESS_SELFTEST_JOBS=1` with SEC lines.
5. `ST_ONLY=dispatch JOHARNESS_SELFTEST_JOBS=1` with the per-call wrapper.
6. The candidate change, built in the worktree: `dispatch.sh` cut at its
   line 1096 into `dispatch.sh` + `dispatch-park.sh`, `release.sh` cut at
   its line 771 into `release.sh` + `release-halt.sh`, both new names
   listed after their parent; run as is (`ts`), then with workers claiming
   `ST_FIRST="dispatch-park dispatch release scout release-halt
   dispatch-branch-plans bootstrap-consumer"` units first (`tl`).
7. `strace -f -e trace=execve` and a `git` arg-logging shim over one
   `DISPATCH_FETCH=0 DRAIN_FETCH=0 ./joharness.sh dispatch` on the real
   checkout; the logged read-only git lines replayed alone, timed.
8. 3736 `grep -qF` over a 200-line haystack, timed: the assertion cost.

A scheduling simulation (greedy, 4 workers, list order vs
longest-first) over the measured per-topic times; script in the session,
inputs are the `t1`/`t4` files.

## Findings

F1. **One topic is the run.** Run 1: wall 406 s (`real`, 4 jobs), sum of
topic times 1254 s. `dispatch` took 362 s, start 38 s, end 401 s: the
critical path. Next: `release` 152, `scout` 70, `dispatch-branch-plans` 64,
`dispatch-order` 52. Run 3 (1 job): wall 996 s, sum 988 s; `dispatch` 277
(28%), `release` 125; 14 topics cover 80.5%. Contention inflates the
4-job sum by 1.27x. GROUNDED (runs 1, 3).

F2. **The cost is `joharness.sh dispatch` calls, priced per claim
branch.** Run 2: 86 517 git execs; `dispatch` 29 476, `release` 14 341,
`dispatch-branch-plans` 5 650. The dispatch family (`dispatch`,
`dispatch-*`, `release`, every one built on `dispatch` calls) is 525 s of
988 serial (53%). Run 5: 118 calls (77 `dsp`, 41 `dfx`) took 250 of
`dispatch`'s ~277 s; a `dfx` call costs 1.3 s with 4 origin branches and
8.7 s with 19, about 0.45 s per claim branch. `dfwork` accumulates branches,
so its late sections pay most: run 4 puts the #626 section at 79 s and the
defect section at 77 s, part 2 (`dfwork`, line 1096 on) at ~177 of 277 s.
Run 7: one dispatch on the real checkout execs 1322 programs, 499 of them
git (530 git lines with the shim, 58 exact repeats); the git lines alone
replay in 3.6 of the call's 6.1 s. GROUNDED (runs 2, 4, 5, 7).

F3. **The topics split clean.** `dispatch.sh` from line 1096 reads only
`df*` names it defines (no `dsp*` after it, no `df*` before it, grep);
`release.sh` from line 771 reads only `h*` names (no `j*` after it).
Run 6: both splits give 3736 passed, 0 failed, 1 skipped, as run 1; the
sorted PASS/FAIL/SKIP lines are identical but for three lines that print a
measured time or the shipped-file count (the two new files). GROUNDED.

F4. **Split plus longest-first reaches the floor.** Run 6: split alone
355 s (-12.5%); split with the longest units claimed first 327 s (-19.5%),
against a floor of 319 s (topic sum / 4). The simulation predicted 332 and
314. `dispatch-park` (221 s under contention) is then the critical path.
GROUNDED (run 6), the simulation WEAK.

F5. **Chains are not the cost.** The four `SELFTEST_CHAINS` total 85 s of
988 serial (8.6%); longest `ci-graph-lint clerk` 48 s. GROUNDED (run 3).

F6. **Duplicate fixtures and repeated assertions are noise.** About 180
`git init` across the topic files (`grep -c`); a fixture build is ~10-20
git execs, so all builds together are a few thousand of 86 517 execs (under
5%, estimate). Run 8: 3736 `grep -qF` take 9.6 s (taken while two suite
runs loaded the box: an upper bound), under 1% of the serial sum. No case
was found whose removal saves time without its own command going too: the
time is in the commands, not in the assertions. WEAK (estimate).

F7. **Stale written numbers.** `ci-selftest-scope.sh` says "16s of a 22s
ci run"; runs 1 and 3 refute it (406 s and 996 s for the suite alone).
GROUNDED.

Answer: the time is `joharness.sh dispatch` calls, whose price grows with
the claim branches in a fixture, run in one topic that holds the critical
path. Split plus longest-first saves 19.5% (measured); beyond the floor
only cheaper dispatch calls help, up to about a quarter of the serial work
if their cost halves (estimate, F2: 53% x 1/2). No case is dropped by
either.

## Consequence for the queue

- New plan `selftest-split-heavy-topics`: the F3/F4 change, plus the F7
  comment. Measured saving 19.5%.
- New plan `dispatch-claim-read-cost`: halve the per-claim-branch cost of
  `joharness.sh dispatch` (F2), proven by identical outputs of the dispatch
  family. Estimated saving up to ~26% of serial work; not measured.
- No single-topic selector plan from here: it saves no suite time
  (`ST_ONLY` in the method was a measurement aid). Research
  `conduct-c2-design` may still want one on its own grounds.

## Verification

Pending: a second context checks the findings.

## Graduates to

`.agents/harness/selftest.sh`: the runner's header records where the time
goes and the budget it holds.
