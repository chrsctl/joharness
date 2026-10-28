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

All runs in one cloud container (4 CPUs, `nproc`). Runs 1-5 and 8 on
`origin/main` at d8cc1328; run 7 in the scratch worktree at f4eb2729 (d8cc1328
plus this branch's claim commit, a handover file only); run 9 on d8cc1328 and
on the candidate. Wall times are `date +%s.%N` differences around
`bash .agents/harness/selftest.sh`, not `time`.

The runner patch below, applied UNCOMMITTED in a scratch `git worktree`,
none of it shipped. It writes `<topic> <start> <end> <pass>` per topic to
`$ST_TIMING`; with `ST_GITLOG` set, a `git` shim ahead of the real one logs
`$ST_TOPIC` per exec; `ST_ONLY` runs named topics alone; `ST_FIRST` makes
workers claim the units whose first topic it names before the rest, both
groups in LIST order (not in `ST_FIRST`'s order). It also lists the two
split topics of run 6.

```diff
diff --git a/.agents/harness/selftest.sh b/.agents/harness/selftest.sh
index 54c2d8b9..7c46c40c 100755
--- a/.agents/harness/selftest.sh
+++ b/.agents/harness/selftest.sh
@@ -160,6 +160,11 @@ fi
 mkdir -p "${TMP}/bin"
 printf '#!/bin/sh\nexit 0\n' >"${TMP}/bin/shellcheck"
 chmod +x "${TMP}/bin/shellcheck"
+if [ -n "${ST_GITLOG:-}" ]; then
+  realgit="$(command -v git)"
+  printf '#!/bin/sh\nprintf "%%s\\n" "${ST_TOPIC:-runner}" >>"%s"\nexec "%s" "$@"\n' "$ST_GITLOG" "$realgit" >"${TMP}/bin/git"
+  chmod +x "${TMP}/bin/git"
+fi
 PATH="${TMP}/bin:${PATH}"
 export PATH
 
@@ -584,6 +589,7 @@ SELFTEST_TOPICS=(
   cleanup
   orchestrated
   dispatch
+  dispatch-park
   dispatch-rescope
   dispatch-curate
   dispatch-order
@@ -592,6 +598,7 @@ SELFTEST_TOPICS=(
   retired-ledger
   analysis
   release
+  release-halt
   guard
   scout
   ci-canonical-only-selftest
@@ -772,7 +779,10 @@ selftest_unit() {
     PASS=0 FAIL=0 SKIP=0
     for _st_t in "$@"; do
       # shellcheck source=/dev/null
+      _st_t0="$(date +%s.%N)"
+      export ST_TOPIC="$_st_t"
       . "${selftest_topics_dir}/${_st_t}.sh" >"${_st_out}/${_st_t}.out" 2>&1
+      printf '%s %s %s %s\n' "$_st_t" "$_st_t0" "$(date +%s.%N)" "$PASS" >>"${ST_TIMING:-/dev/null}"
     done
     printf '%s %s %s\n' "$PASS" "$FAIL" "$SKIP" >"${_st_out}/u${_st_n}.counts"
   ) >"${_st_out}/u${_st_n}.log" 2>&1
@@ -782,15 +792,22 @@ selftest_unit() {
 # <out dir> <unit>...: claim units in list order until none is left. mkdir is
 # the claim, atomic across workers.
 selftest_worker() {
-  local _st_wout="$1" _st_wn=0 _st_unit
+  local _st_wout="$1" _st_wn=0 _st_unit _st_order=()
   shift
-  for _st_unit in "$@"; do
+  local -a _st_all=("$@")
+  for _st_wn in "${!_st_all[@]}"; do
+    case " ${ST_FIRST:-} " in *" ${_st_all[$_st_wn]%% *} "*) _st_order+=("$_st_wn") ;; esac
+  done
+  for _st_wn in "${!_st_all[@]}"; do
+    case " ${ST_FIRST:-} " in *" ${_st_all[$_st_wn]%% *} "*) ;; *) _st_order+=("$_st_wn") ;; esac
+  done
+  for _st_wn in "${_st_order[@]}"; do
+    _st_unit="${_st_all[$_st_wn]}"
     if mkdir "${_st_wout}/u${_st_wn}.claim" 2>/dev/null; then
       date +%s >"${_st_wout}/u${_st_wn}.claim/start"
       # shellcheck disable=SC2086  # a unit is a space-separated topic list
       selftest_unit "$_st_wn" "$_st_wout" $_st_unit
     fi
-    _st_wn=$((_st_wn + 1))
   done
 }
 
@@ -877,6 +894,7 @@ selftest_report() {
   [ "$FAIL" -eq 0 ]
 }
 
+if [ -n "${ST_ONLY:-}" ]; then read -ra SELFTEST_TOPICS <<<"$ST_ONLY"; SELFTEST_CHAINS=(); fi
 selftest_chain_bad="$(selftest_chain_problems)"
 if [ -n "$selftest_chain_bad" ]; then
   printf 'selftest: SELFTEST_CHAINS disagrees with the list:\n%s\n' \
```

Other instruments:

- Section times: every `# --- ` header of `dispatch.sh` and `release.sh`
  rewritten by `sed -E 's/^# --- (.*)$/printf "SEC %s %s\\n" "$(date +%s.%N)" "\1" >>"$ST_SEC"/'`.
- Per-call cost: `dsp` and `dfx` in `dispatch.sh` wrapped to log seconds
  and `git for-each-ref refs/remotes/origin | wc -l` (every origin ref,
  `main` included: refs, not claim branches).
- The scheduling simulation, run from the repository root as
  `python3 sim.py <timing file>`:

```python
# python3 sim.py <timing file> : greedy 4-worker schedule, list order vs longest first
import sys,re
src=open('.agents/harness/selftest.sh').read()
topics=re.search(r'SELFTEST_TOPICS=\((.*?)\)',src,re.S).group(1).split()
chains=[c.split() for c in re.findall(r'"([^"]+)"',re.search(r'SELFTEST_CHAINS=\((.*?)\n\)',src,re.S).group(1))]
d={}
for l in open(sys.argv[1]):
    t,a,b,_=l.split(); d[t]=float(b)-float(a)
seen=set();u=[]
for t in topics:
    if t in seen: continue
    un=[t]
    for c in chains:
        if t in c: un=c
    seen|=set(un); u.append(sum(d.get(x,0) for x in un))
def sim(u,w=4):
    free=[0.0]*w
    for c in u:
        i=free.index(min(free)); free[i]+=c
    return max(free)
print('sum',round(sum(u)),'list',round(sim(u)),'longest-first',round(sim(sorted(u,reverse=True))))
```

Runs:

1. `ST_TIMING=t4` (jobs default = 4): wall and per-topic time.
2. `ST_TIMING=tg ST_GITLOG=git.txt`: git execs, `sort git.txt | uniq -c`.
3. `JOHARNESS_SELFTEST_JOBS=1 ST_TIMING=t1`: per topic, one worker.
4. `ST_ONLY="dispatch release" JOHARNESS_SELFTEST_JOBS=1` with SEC lines.
5. `ST_ONLY=dispatch JOHARNESS_SELFTEST_JOBS=1` with the per-call wrapper.
6. The candidate: `dispatch.sh` cut before its line 1096
   (`# --- a defect:`) into `dispatch.sh` + `dispatch-park.sh`, `release.sh`
   cut before its line 771 (`# --- release --human`) into `release.sh` +
   `release-halt.sh`, each tail moved byte-identical under a two-line
   header and a `step`. Run as is (`ts`), then with
   `ST_FIRST="dispatch-park dispatch release scout release-halt dispatch-branch-plans bootstrap-consumer"` (`tl`).
7. `strace -f -qq -e trace=execve` and an arg-logging `git` shim over one
   `DISPATCH_FETCH=0 DRAIN_FETCH=0 ./joharness.sh dispatch`; the 530 logged
   git lines replayed alone (`eval "git $l"`), timed with `time`.
8. 3736 `grep -qF` over a 200-line haystack, timed with `time`, while runs
   6 were loading the box.
9. Repeat for n=2 per arm, nothing else running: plain `bash
   .agents/harness/selftest.sh` in a worktree at d8cc1328, then the run 6
   candidate with the same `ST_FIRST`, alternating, twice.

Per-topic causes outside the dispatch family: call counts of each topic's
command wrapper (`grep -cE '\$\(<wrapper>'` in the topic file).

## Findings

F1. **One topic is the run.** Run 1: wall 406 s (4 jobs), topic sum
1254 s. `dispatch` took 362 s, +38 s to +401 s, the critical path; the last
other topic ended at +303 s, so `dispatch` ran alone for the final 98 s.
Next: `release` 152, `scout` 70, `dispatch-branch-plans` 64. Run 3 (1 job):
wall 996 s, sum 988 s; `dispatch` 277 (28%), `release` 125; 14 topics cover
80.6%. Contention inflates the 4-job sum 1.27x. GROUNDED (runs 1, 3).

F2. **The dispatch family is `joharness.sh dispatch` calls, priced per
origin ref.** Run 2: 86 517 git execs; `dispatch` 29 476, `release` 14 341,
`dispatch-branch-plans` 5 650. `dispatch`, `dispatch-*` and `release` are
525 s of 988 serial (53%). Run 5: 118 calls (77 `dsp`, 41 `dfx`) summed
250 s (run 3's `dispatch` topic: 277 s, a different run). Linear fits over
run 5: `dfx` 0.42 s per origin ref, `dsp` 0.15 s per ref; `dsp` calls are
the larger share (129 of 250 s). `dfwork` accumulates refs, so its late
sections pay most: in run 4 part 2 (from line 1096) took ~177 of `dispatch`'s
~321 s (55%), the #626 section 79 s and the defect section 77 s. Run 7: one
call execs 1116 programs (successful `execve`), 499 of them git, 617 other;
the shim logged 530 git lines, 58 of them exact repeats (a branch's
`merge-base` twice, a handover file `show`n three times); the git lines
alone replay in 3.6 s of the call's 6.1 s (from the session's `time`
output, not saved). GROUNDED for counts and fits (runs 2, 5, 7); the replay
WEAK.

F3. **The two topics split clean.** `dispatch.sh` from line 1096 reads no
name its lines 1-1095 define, nor the reverse; the same for `release.sh` at
line 771 (each `$name` and function checked by the verifier both ways;
shared only `ROOT`, `TMP`, and `rc`, set before read). Run 6: 3736 passed,
0 failed, 1 skipped, as run 1; the sorted PASS/FAIL/SKIP lines are
identical but for two measured-time lines and the shipped-file count
(136 -> 138, the two new files). GROUNDED.

F4. **Split plus heavy-first reaches the floor.** Run 6 (n=1): split alone
355 s (-12.5% on run 1's 406 s); split with the `ST_FIRST` units claimed
first, in list order, 327 s (-19.5%), against a floor of 319 s (topic sum /
4). Run 9 (n=2 per arm, quiet box): RUN9. `dispatch-park` (221 s under
contention) is then the critical path. The simulation predicted 332 and 314.
RUN9VERDICT

F5. **Chains are not the cost.** The four `SELFTEST_CHAINS` total 85 s of
988 serial (8.6%); longest `ci-graph-lint clerk` 48 s. GROUNDED (run 3).

F6. **The other top topics: a whole command per case.** Serial (run 3) and
cause, from wrapper call counts: `scout` 59 s, 31 runs of `scout` or
`conduct` (4852 git execs); `bootstrap-consumer` 41 s, 52 runs of
`bootstrap-consumer.sh`, each copying and checksumming a tree (443 git
execs: the time is file work); `review` 36 s, 27 fixture `ci` runs; `retro`
36 s, 20 `retro` runs; `checks` 30 s, fixture `finish` runs, each a whole
`ci`; `ci-graph-lint` 28 s, 61 fixture `ci` runs read for one section.
Proposed: a `ci` that runs only the named stage when a fixture asks for
one section would cut the `ci`-driven topics (`review`, `checks`,
`ci-graph-lint`, ~94 s serial, ~10%) by perhaps half, ~5% of the suite
(estimate). The rest have no cheap cut: their cases ask the command whole.
Under the 20% bar; filed as no plan. WEAK (counts grounded, savings
estimated).

F7. **Duplicate fixtures and assertions are noise.** 145 `git init` lines
across the runner and topic files (`cat .agents/harness/selftest.sh
.agents/harness/selftest/*.sh | grep -c 'git init'`); a fixture build is
~10-20 git execs, so all builds are a few thousand of 86 517 (under 5%,
estimate). Run 8: 3736 `grep -qF` took 9.6 s under load, an upper bound
under 1% of the serial sum (3736 is the case count reused, not the suite's
grep count). No duplicate assertion found whose removal saves time without
its command going too. WEAK.

F8. **A stale written number.** `ci-selftest-scope.sh` says "16s of a 22s
ci run"; runs 1 and 3 refute it. GROUNDED.

Answer: the time is `joharness.sh dispatch` calls, priced per origin ref of
the fixture, run in one topic that holds the critical path. Split plus
heavy-first saves ~20% (F4); beyond the floor only cheaper commands help,
the dispatch family's at most 53% of serial work (F2). No case is dropped:
a case moves with its bytes (F3).

## Consequence for the queue

- New plan `selftest-split-heavy-topics`: the F3/F4 change, plus F8.
- New plan `dispatch-claim-read-cost`: cut the per-ref cost of `joharness.sh
  dispatch` (F2), proven by identical dispatch-family case lines. Saving
  not measured; the build measures it.
- F6's stage-only `ci`: no plan (est. ~5%, under the bar).
- No single-topic selector plan: it saves no suite time (`ST_ONLY` was a
  measurement aid). Research `conduct-c2-design` may want one on its own.

## Verification

Pending: a second context checks the findings.

## Graduates to

`.agents/harness/selftest.sh`: the runner's header records where the time
goes and the budget it holds.
