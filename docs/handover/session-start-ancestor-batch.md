---
workstream: session-start-ancestor-batch
status: review
branch: claude/review-optimize-1g74te
pr: none
plan: session-start-ancestor-batch
issue: none
session: https://claude.ai/code/session_01SqqhwxWTrXDj4t8bo2K9cU
agent: opus
updated: 2026-09-11
next: Retire this file and the plan file in the last commit before the pull request opens (step 7)
---

## Goal

Human asked to "review, optimize". The review found the harness's
most-paid-for loop: both session-start hooks spawn one
`git merge-base --is-ancestor <ref> origin/main` per remote ref, only to
skip refs already merged. 271 of session start's 463 git processes on this
checkout. `git for-each-ref --merged` answers it for every ref in one
process. Plan: `docs/plans/session-start-ancestor-batch.md`.

## Decisions

- **Batch the boolean, not the SHA.** Only the merged/not-merged test is
  batchable. The second `merge-base` per ref returns a SHA its caller needs
  (`owned_at`, churn base) and is left alone. It already ran for the unmerged
  refs only, since the `--is-ancestor` it follows came first and `continue`d
  — so the whole saving is the boolean, and the arithmetic says so: 271
  `--is-ancestor` removed, 2 `for-each-ref` added, live session-start down
  270. Nothing else moved.
- **Not a memo cache.** Measured first: 297 merge-base calls, 290 distinct.
  A cache would have saved 7 calls and added a cache. Rejected on the
  number, before writing it.
- **Not the 417KB parse.** `joharness.sh` is 8216 lines and the obvious
  suspect; measured at ~10ms to parse, ~20ms for a trivial invocation.
  Rejected on the number.
- **Escalated opus over the plan's `sonnet`.** The plan is written for a
  literal reader and its steps are mechanical, but the change turns a
  per-ref predicate into a banked set, and the ways that goes wrong are
  quiet: a spelling mismatch, an unanchored match, a fallback that fails
  the wrong way. None of them alter the output of a repo whose branch names
  happen to be well spaced. Escalation is legal, downgrade is not
  (`.agents/docs/agent-selection.md`); recorded here because r7 is what
  happens when it is not.
- **`perf` is the instrument, not a git shim.** Every count in this
  workstream that decided anything came from `./joharness.sh perf`, which
  counts every external command. The PATH shim over `git` that FOUND the
  loop also reported a 57% saving for a spelling that saved nothing (r9).
  A shim that counts one binary answers a question nobody asked.

## Rejected

- **Splitting joharness.sh to cut startup cost.** 20 invocations of
  `bash -n joharness.sh` take 0.201s total — 10ms each. Parse is not the
  bottleneck and a split would have been a large diff buying nothing.
- **Trimming the selftest to make `ci` faster.** `ci` is 4m37s, of which
  the selftest is 4m17s and ~31k git subprocesses. Real, but the fix there
  is fixture reuse across topics, which changes what the tests prove. The
  session-start loop is a strictly better first cut: it is paid by every
  session rather than by every pull request, and its output is a verifiable
  invariant.

## Review

Depth: opus adversarial (`./joharness.sh review`), plus
`.claude/agents/verifier.md` at opus — one reader that did not write the
diff. r1-r8 are its findings; r9 and r10 are this session's own, found by
mutation-testing before the verifier ran.

- r9: the first membership test was `grep -qxF`, one process per ref — the
  same per-ref spawn the change exists to remove, in a different binary. A
  git-only PATH shim reported session-start 463 -> 198 and missed it
  entirely. (fixed — `case` glob, no fork; and the instrument is
  `./joharness.sh perf`, which counts every external command, not a shim
  that counts one)
- r10: the no-base-ref case asserted a bare filename that also appears in a
  branch's OWN section, so it passed under a mutation that filtered every
  ref. (fixed — the reporting branch is cut before the file exists and the
  assertion names the in-flight entry line; confirmed FAIL with the
  mutation, PASS without)
- r1: (verifier) the only assertion covering `queue-context.sh` was
  unfalsifiable — the fixture carried no `docs/plans/`, so the hook printed
  "No plans" and the claims block emitted nothing for any branch. Verified
  green with `ref_merged() { return 1; }`, i.e. the filter deleted outright.
  (fixed — two plans in the fixture, a claim per branch, and the assertion
  is now `claimed on origin/claude/foo` present and `origin/claude/foo-2`
  absent)
- r2: (verifier) the `refute` on the merged branch's listing entry was
  unfalsifiable in `handover-context.sh` too: a merged ref cannot reach that
  listing whatever the filter does, because `owned_at` diffs
  merge-base(ref, base)..ref and the range is empty. The topic pinned
  over-filtering only, while its header claimed both. (fixed — the dead
  `refute` is gone and the reason is a comment where it stood; under-
  filtering is pinned in the queue hook, where it does change output)
- r1a: the first fix for r1 STILL pinned nothing — with the merged branch's
  workstream file sitting unchanged on the base branch, the claims loop drops
  it through its blob guard rather than the merged filter, and mutation A
  passed again. (fixed — the fixture now retires that file on the base
  branch, which step 7 requires of every merge anyway; both mutations then
  FAIL: filter disabled, and bank built in the wrong ref spelling)
- r3: (verifier) both plan and workstream file claimed the second
  `merge-base` per ref "now runs for the ~11 unmerged refs instead of all
  136, which is the same saving by another route". False — the
  `--is-ancestor` it follows always came first and `continue`d, so it
  already did. (fixed — the claim is withdrawn in both, and the arithmetic
  that disproves it is written beside it: 271 removed, 2 added, live
  session-start down 270)
- r4: (verifier) `joharness.sh` "both queue rows count 126 today" was stale
  before this diff and staler after it re-pinned those very rows to 104.
  (fixed — the sentence now carries all three numbers and the reason to read
  the table instead)
- r5: (verifier) the retained "844, against 805 — 39 spawns" contradicts the
  new live drain pair three lines below. Re-counted 2026-09-11: 428 and 418,
  a gap of 10. (fixed — the old pair is kept as the reasoning it was written
  for and explicitly marked not a current reading, with today's count beside
  it)
- r6: (verifier) the plan's `scope:` named `.agents/harness/selftest/perf.sh`,
  untouched, and omitted `.agents/harness/selftest.sh` and the new topic
  file, both edited. (fixed — scope matches the diff; ship verdict unchanged,
  both selftest paths are CANONICAL_ONLY)
- r7: (verifier) the plan wants `sonnet` and this session ran `opus` without
  recording the escalation, and `## Review` was an empty section, which is
  not a clean pass. (fixed — the escalation and its reason are in Decisions;
  this section is the record)
- r8: (verifier) `queue-context.sh` carried a verbatim copy of a note citing
  `session-start`'s 327 against a 336 budget — the wrong row for that file,
  and a budget the same commit retired. (fixed — the note keeps the lesson,
  the numbers stay in the file whose row they measure)

## Blockers

None.

## Where to look

- `.agents/harness/handover-context.sh` — `while IFS= read -r ref` loop,
  full `refname` spelling.
- `.agents/harness/queue-context.sh:claims` — same test, `refname:short`
  spelling. The two spellings are the trap.
- `joharness.sh:cmd_perf` — `JOHARNESS_PERF_BUDGET_*` defaults to re-pin.
