---
workstream: marker-gate-needs-no-done
status: review
branch: claude/marker-gate-needs-no-done
pr: none
plan: marker-gate-needs-no-done
issue: none
session: https://claude.ai/code/session_01Samg4LcLJBw1jg4RfCtT8Z
agent: sonnet
updated: 2026-08-31
next: Verifier pass is out (a94344e5d137e30ed); fold its findings into
  ## Review, open the pull request, watch CI (real GitHub runners are
  unaffected by the local perf-budget noise — see Blockers)
---

## Goal

`docs/plans/marker-gate-needs-no-done.md`: `lint_finding_markers` only reds
on `status: done`, and nothing requires a branch to ever say it — a branch
that goes `review` straight to the retire commit merges undispositioned
findings unchecked. PR 172's own r5 is the evidence.

## Decisions

- RED trigger is the retire commit itself, not `status: done`. New
  `fin_retired_own(ref)` (joharness.sh) reads the LOG (added-then-deleted
  within this branch's own commits under `docs/handover`, still absent from
  HEAD's tree), not the tree alone — `fin_adds_at` is tree-based and is
  blind at exactly the moment retirement happens, since the retire commit
  deletes the file from HEAD's tree.
- `fin_strength` is UNCHANGED (still only `done`/`edge`, tree-based) —
  first draft folded a third `retired` value into it, which broke a
  pre-existing invariant: `fin_strength`'s return value also decides
  whether `ci` prints the `== finish` section at all, and a branch that
  retires cleanly (everything dispositioned) must stay silent there.
  `lint_finding_markers` now calls `fin_retired_own` directly instead,
  reusing its own already-computed `$base`. `fin_gate` (finish's own gate)
  is unaffected either way: a retired file has no `adds`, so its `n == 0`
  branch already returns clean regardless of strength.
- `(recorded` stays OUT of `fb_marker`'s vocabulary. It names no outcome —
  every finding under `## Review` is already recorded by being there, and
  several historical uses are bare `(recorded)` with nothing after it: not
  fixed, not wontfix, not a reason. Accepting it as a fourth verdict would
  let a finding close itself by restating what section it's in — the exact
  silent drop step 5 forbids. Findings marked only `(recorded` keep
  counting as unmarked, same as before this branch, going forward and in
  the historical pile FB_SINCE already bounds. Reasoning lives beside
  `fb_marker` itself (joharness.sh) and in the comment above
  `lint_finding_markers`'s red-trigger block.

## Rejected

- Making `status: done` mandatory. The plan's own Trap: that moves the
  problem to a field rather than removing the dependence on one — a hurried
  session would just as easily skip a mandatory field as an optional one,
  and the gate would still fire on the wrong signal (a field) instead of the
  fact (the file is gone).
- Folding `retired` into `fin_strength` as a third value. Tried first,
  reverted: it silenced nothing to fold it in, since `fin_strength`'s value
  also gates the `== finish` section header in `ci`, and a clean retirement
  (every finding dispositioned) must print nothing there — see Review r1.

## Review

- r1: my first draft folded `retired` into `fin_strength` as a third
  return value. That function's return value ALSO decides whether `ci`
  prints the `== finish` section at all — so a branch retiring cleanly
  (no unmarked findings) started printing `== finish` / "none — this
  branch retires what it claimed" where it used to print nothing, breaking
  a pre-existing selftest case (`the ritual silences the gate`). Caught by
  running the full selftest suite before assuming the change was done.
  (fixed — `fin_strength` reverted to its original two-value shape;
  `lint_finding_markers` reads `fin_retired_own` directly instead)
- r2 (code-review, high): `fin_retired_own` matched "added" and "deleted"
  as SETS over the branch's whole history, so a file added, `rm`'d by
  mistake, then re-added and still present at HEAD read as retired too —
  a false RED on a branch that is mid-build with the file right there,
  exactly the case this gate must stay silent on. Confirmed by simulation
  before the fix. (fixed — added a tree check: retired now means absent
  from `fin_docs_at HEAD`, not merely deleted at some point in the log;
  pinned by a new selftest case, `markreadd`)
- r3 (code-review, high): unlike `fin_adds_at` (a tree diff, "own files
  only" by construction), the log walk in `fin_retired_own` had no
  ownership guard — a `git merge origin/main` done to reconcile a conflict
  at finish (`.agents/docs/product/README.md`, "Conflict at finish") could
  in principle pull in another branch's own already-finished
  add-then-delete lifecycle for a file this branch never touched, if the
  merge-base computation raced a stale local `origin/main` ref. (fixed —
  `--first-parent` on both log calls keeps the walk on this branch's own
  commit sequence; not folded into a fixture — a realistic multi-branch
  merge race is expensive to construct and the mitigation is a standard,
  well-understood git technique, verified by re-reading rather than by a
  dedicated case)
- r4: verifier spawned (a94344e5d137e30ed) — findings pending, to be
  folded in before the pull request opens.

## Blockers

- LOCAL-ONLY, not this branch's: `./joharness.sh perf` (both inside
  `.agents/harness/selftest.sh`'s own `perf.sh` topic and inside `ci`'s own
  `== perf budget` section) reports `graph`, `session-start`,
  `queue-context` and `drain` OVER their fork-count budgets in THIS sandbox
  container. Confirmed NOT caused by this branch: identical counts
  (`graph` 391 vs budget 260) on a clean `origin/main` worktree, with and
  without this branch's diff. Confirmed NOT real in the environment that
  actually gates merges: GitHub's own `ci` workflow run for `origin/main`'s
  current head (run 33435722331, commit 8412fad) is `conclusion: success`.
  Root cause not chased (out of scope for this plan) — plausible guess is
  this container's wider local ref set (dozens of stale `origin/claude/*`
  branches fetched) inflating `graph`'s per-ref work relative to what a
  fresh single-ref GitHub Actions checkout walks, but that is a guess, not
  measured. Left for a session with room to chase it; not blocking this
  plan's merge since the actual CI gate does not reproduce it.
  `bash .agents/harness/selftest.sh` here: 1170 passed, 1 failed (this
  one). `./joharness.sh ci` here: FAIL, same one section.

## Where to look

- `joharness.sh:lint_finding_markers` — the gate; reds on `status: done`
  OR `fin_retired_own` being non-empty.
- `joharness.sh:fin_strength` — unchanged; two values, tree-based.
- `joharness.sh:fin_retired_own` — new; log-based retirement detection,
  own-commits-only, tree-checked against false positives.
- `joharness.sh:fb_marker` — vocabulary; `(recorded` decision recorded
  beside it.
- `.agents/harness/selftest/review.sh` — existing "THE RETIRE COMMIT" case
  (markretire) now asserts `ci`'s exit code, not just message text; new
  cases `markretirereview` (the leak itself: `review` status straight to
  retire), `markretireclean` (must stay green), `markreadd` (r2's false
  positive, must stay green). Two pre-existing fixtures (`ws.md` in the
  review-gate block, `fin.md` in the fin_gate block) had filler findings
  with no verdict; both retire later in their own fixtures and now trip
  the new gate, so both were given real verdicts to preserve their
  original, unrelated test intent.
