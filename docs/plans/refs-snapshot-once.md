---
plan: refs-snapshot-once
urgency: normal
agent: opus
effort: high
needs: dispatch-no-merged-walks
requirement: none
issue: none
scope: shared:joharness.sh, shared:.agents/harness/selftest/dispatch.sh, .agents/harness/selftest/refs-snapshot.sh
---

## Goal

Thirteen `for-each-ref refs/remotes/origin` sites, 107 `while IFS= read -r`
loops and 39 `merge-base` call sites in `joharness.sh` (counted 2026-10-13,
`grep -c`) each walk every remote ref and ask git per ref the same three
things: is it merged, what is its merge-base, what `docs/handover/*` files
sit at its tip. `dispatch-no-merged-walks` fixes the merged question in the
seven dispatch walks. This plan makes the whole answer a table computed
ONCE per invocation and read by every walker — `who`, `janitor`, `finish`,
the clerk, conduct and curate reports, `cl_inflight`, `cl_merged_branches`,
`claim_branches` — and pins the property in the selftest: the number of git
calls a command makes must not grow with the number of merged refs.
Measured: `dispatch` 156 s on gx (508 refs) and 218 s on joharness (282
refs) before `dispatch-no-merged-walks`; `./joharness.sh scout`, which
already walks once, 1 s.

## Scope

- `joharness.sh` — `refs_snapshot`: one `for-each-ref --no-merged` and one
  `--merged` listing, one `for-each-ref --format='%(objectname) %(committerdate:unix) %(refname)'`
  for tips and ages, one `git grep -l` across the unmerged tips for
  `docs/handover/`, one `git merge-base` per UNMERGED ref only; written to a
  temp file under `mktemp -d` once per process, removed at exit (the
  existing `trap` pattern). Readers: `claim_branches`, `cl_inflight`,
  `cl_merged_branches`, `scout_refs`, `scout_walk`, the clerk, conduct and
  curate branch walks, `dispatch_curate_branches`, `cmd_who`, `cmd_janitor`,
  `cmd_finish`'s behind check. Each becomes a reader of the table; its
  output must not change (the selftest's existing cases are the oracle).
- `.agents/harness/selftest/refs-snapshot.sh` — a fixture repository with 5
  merged refs and then 60 merged refs (same unmerged set): the git exec
  count of `dispatch`, `who`, `clerk` and `scout` differs by at most 6
  between the two (counted with `strace -f -e trace=execve` when present,
  else by a `GIT_TRACE=1` line count); the case `skip`s with the reason when
  neither counter exists, in the selftest's own `skip` idiom.
- `.agents/harness/selftest/dispatch.sh` — the perf comment at the
  `dispatch_curate_branches` site ("paid for it 130 times") moves to the
  snapshot and becomes the one place that says why.

## Out of scope

- Any change to what a walker prints: this is a cache, not a redesign.
- The fetch: `git fetch --prune` of every ref stays where it is
  (`stale-refs-report` is the plan about ref population).
- `handover-context.sh` (the session-start hook, 3.8 s measured): separate
  process, separate plan if ever.

## Acceptance

- `DISPATCH_FETCH=0 time ./joharness.sh dispatch` on gx and on this
  repository, before and after, in the pull request: expected under 30 s on
  both (from 156 s and 218 s).
- `bash .agents/harness/selftest.sh` — `refs-snapshot.sh` passes and every
  existing case still passes unchanged; `./joharness.sh ci` — `ci: pass`.
- `grep -c 'for-each-ref' joharness.sh` — at most `4` (the snapshot's own
  calls); quote the count.
- Plan `ci` calls SHIPS: gx's next orchestrator report shows the pass
  duration; the first health pass after sync is the consumer's number.

## Where to look

- `joharness.sh:scout_refs` and `joharness.sh:scout_walk` — the fast shape
  already in the file; the snapshot generalises them.
- `joharness.sh:claim_branches`, `joharness.sh:cl_inflight`,
  `joharness.sh:cl_merged_branches` — the slow shape, three copies.
- `joharness.sh:dispatch_curate_branches` — the comment that states the rule.
- `.agents/harness/pretool-bash-guard.sh` — the "NO FORKS" perf doctrine and
  how its row is budgeted; the shape the new perf case copies.

## Traps

- Fix undoes an earlier fix? `dispatch-no-merged-walks` lands first and this
  plan reads its result; never rewrite its loops a second way.
- Never `pgrep -f` a pattern your own command line carries (the selftest's
  exec counter must count the child, not itself).
- A background command must be able to finish: bound the strace run.
