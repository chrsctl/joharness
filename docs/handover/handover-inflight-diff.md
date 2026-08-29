---
workstream: handover-inflight-diff
status: review
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: handover-inflight-diff
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Retire plan + workstream file, open the pull request, merge on green checks.
---

## Goal

`docs/plans/handover-inflight-diff.md`. The session-start hook reports work
in flight by reading each branch's TREE, so a workstream file that merged and
was swept is still reported as live work on every branch older than the
sweep. AGENTS.md step 4 already states the rule — diff against merge base,
never read the tree — and the hook that teaches it does not follow it.

## Decisions

- Re-counted the plan's central claim before building on it, per its own last
  Trap. The plan says `joharness-minify-optimize` is listed on FOUR branches
  (2026-08-28). Today, 2026-08-29:

      for b in $(git for-each-ref --format='%(refname:short)' refs/remotes/origin); do
        git ls-tree -r --name-only "$b" docs/handover/ | grep -q joharness-minify-optimize &&
        git diff --name-only "$(git merge-base "$b" origin/main)" "$b" \
          -- docs/handover/joharness-minify-optimize.md
      done

  **18 branches carry it; the diff is empty for every one. 5 are unmerged**,
  so the hook lists that one dead workstream five times. Four to eighteen in
  a day — the report degrades as the repo moves, which is the argument for
  fixing it before more plans build on it.
- This session read that false list at every session start for six hours and
  skimmed past it, which is the plan's stated cost happening to the reader
  who was fixing it.

- `--diff-filter=ACMRT` in ONE call, not `files_at` intersected with
  `changed_at`. Same three-case semantics, one git invocation per ref instead
  of two, and copied verbatim from `joharness.sh:cl_inflight`, which learned
  it as PR 54 r8. The plan says "the fix is to intersect… not to add a new
  walk" and "model the new cases on it rather than inventing a second fixture
  shape" — deriving a second answer to a question this repo already answered
  is how two readers of one fact start disagreeing.

## Rejected

- The plan's stated justification for the third fixture. It says a naive
  `changed_at` swap "reports a file the branch DELETED as live work" and
  calls that the case that has to exist. Measured: the naive diff DOES return
  the deleted path, and the entry is dropped anyway — the hook's own
  `git show "$ref:$f"` returns empty for a file the branch deleted, and the
  row is skipped. Naive and filtered both give 0.

      # old hook (tree) vs naive swap vs ACMRT, on a retirer branch
      -> 0 / 0 / 0
      # the same three, on an inheritor branch
      -> 1 / 0 / 0

  So the retired case is guarded downstream, by accident rather than design.
  The filter stays — it states the intent and skips a `git show` that can
  only fail — but the fixture now says it pins the guard, not the filter. A
  test claiming to catch a bug it cannot catch is worse than no test.

## Review

Round 1, opus verifier. Nine findings; two severe, and both were mine turning
an over-report into an UNDER-report — the worse direction, and the one I had
explicitly told the reviewer to hunt for.

- r1 (verifier): `owned_at` returned nothing when `git merge-base` fails. A
  shallow clone has grafted history — 27 of this checkout's refs — and
  nothing was read as "claims nothing", not "unknown". The listing went 12
  entries to 3 and I reported that as the report becoming true. Most of the
  drop was real claims vanishing, one from a branch that provably authored
  its file. Falls back to the tree now: over-report when ownership cannot be
  computed, because a false claim costs a `/who` and a missing one is two
  sessions duplicating work (#119). (fixed)
- r2 (verifier): a branch still committing after its own pull request merged
  loses its claim — the merge base becomes the merge commit, which contains
  the file. The fallback does not cover it; the merge base exists. Judged
  CORRECT rather than fixed: after a merge and sweep that workstream is
  finished, and listing it as in flight is the original bug. Recorded so a
  reader who disagrees has something to argue with. (wontfix, reasoned)
- r3 (verifier): the plan's "keep reporting an inherited file, demoted"
  bullet was dropped with no record, and a code comment asserted the opposite
  of what shipped. Inherited files are counted and demoted on their own line
  now. (fixed)
- r4 (verifier): five of six new assertions were green against the UNFIXED
  hook — no-regression checks wearing regression-guard labels. The plan's
  Acceptance was wrong too: a writer's tree holds its file, so the
  tree-reading hook printed that line identically. Labelled honestly, and the
  demotion assertions added, which only the fix can satisfy. (fixed)
- r5 (verifier): a fixture comment claimed to pin the downstream guard.
  Measured: green with either the filter or the guard removed, failing only
  with both. It pins the outcome; the comment says so now. (fixed)
- r6 (verifier): two assertions, one needle, one `$out`. Replaced with one
  asserting the leftover COUNT, which the duplicate never did. (fixed)
- r7 (verifier): the new block was spliced between another block's comment
  header and its code, orphaning that header. Second time this session.
  (fixed)
- r8 (verifier): the only hook call in the suite without `HANDOVER_FETCH=0` —
  network-shaped I/O behind a 15s ceiling, buying nothing. (fixed)
- r9 (verifier): `next:` described the approach this file rejects, and it is
  the line the hook prints without opening the file. (fixed)

Round 2, mine.

- r10: the shallow-clone warning never printed. `owned_at` runs inside a
  command substitution, so the global it set died with the subshell.
  Signalled by exit status now. A false negative inside the fix for a false
  negative. (fixed)
- r11: the commit that claimed to record this round recorded nothing — the
  edit failed and the commit ran anyway, so its message asserted work that
  had not happened. Caught on the next read. A commit message is a claim like
  any other and this one was false. (fixed, here)

## What this does NOT fix, on this checkout

The clone here is shallow, so `merge-base` fails for 27 of 28 refs and every
branch takes the fallback. **The inheritance fix is inert in this container**
and the false claims remain — visible, and labelled as possibly-inherited
rather than asserted as claims. It works on a full clone, which is what the
fixtures exercise. `git fetch --unshallow` is the operator action, and the
hook now says so in its own output rather than leaving a reader wondering why
the numbers do not move.

## Blockers

None.

## Where to look

- `.agents/harness/handover-context.sh:files_at` and `:changed_at` — five
  lines apart; the fix is their intersection, not a swap.
- `joharness.sh:cl_inflight` — the same bug already fixed, PR 54 r8. The
  precedent to copy rather than re-derive.
