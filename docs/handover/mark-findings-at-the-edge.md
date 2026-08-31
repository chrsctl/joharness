---
workstream: mark-findings-at-the-edge
status: done
branch: claude/mark-findings-at-the-edge
pr: none
plan: docs/plans/unsupervised-mark-findings-at-the-edge.md
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Retire this file and the plan, open the pull request, merge.
---

## Goal

An unmarked finding is a SOURCE OF WORK: `cmd_sources` counts it and a
non-zero count sets `dry=0`, so under unsupervised mode the fleet cannot stop
while one is outstanding. The baseline (PR 161) bounded the historical pile;
this keeps the new count near zero. Step 5 already required it — "Fix them or
record why not — never drop silent" — and nothing enforced it.

## Decisions

- **Taken ahead of `unsupervised-edge-generates-work`**, which `drain` named
  first. That plan's precondition is a genuinely empty queue, including
  unplanned requirements, so it cannot run while the queue holds two plans —
  whatever the human decides about the mode flip. This one also moves toward
  that precondition.
- **Two strengths, reusing `fin_strength`.** Report always, red at
  `status: done`. Same reasoning that function already carries: a gate that
  reds mid-build fights the review gate, which needs findings recorded while
  the review is happening, and a finding written this hour and dispositioned
  next hour is the normal case.
- **`fb_marker`'s vocabulary, not a new one.** A second spelling of the same
  verdict is how two counts drift apart.
- **The walk is now shared, not copied.** `lint_finding_ids` already solved
  the hard parts — the diff rather than the tree, the retire commit, indented
  bullets — so those became `lint_ws_in_diff`, `lint_ws_content` and
  `lint_review_bullets`. Two copies of forty commented lines is two things
  that drift.

## Rejected

- **Failing mid-build.** It would make red a branch's normal state, which is
  the argument the review gate already lost once.
- **Reading the tree.** A branch inherits every workstream file its base
  carries; the tree read names somebody else's findings on every run.

## Review

Round 1, opus, self, with `mutate`.

- r1: **I destroyed the whole change with `git reset --hard HEAD~2`.** I had
  probed both strengths by committing a fake finding, and `git add -A` had
  swept the gate into those probe commits — so reverting the probe reverted
  the feature. Diagnosed from the fixture's `ci` output having no `== finding
  verdicts` section at all while the working tree "had" one. Second time this
  session I have deleted my own uncommitted work with a git command aimed at
  something else (PR 156, `git checkout -q joharness.sh`). (fixed — rebuilt;
  the standing lesson is that `git add -A` makes every later reset a wider
  blast radius than it looks)
- r2: my "fully dispositioned" case asserted `ci` goes green at
  `status: done`, and it cannot: a branch that says done while still carrying
  its own workstream file is red at the FINISH gate whatever this stage
  thinks. The case was asserting somebody else's verdict and failed for a
  reason unrelated to markers. (fixed — the green case sits at `review`, and
  the comment says why)
- r3: the mutation redded a case I did not write —
  `refute "done is no longer a mere report" "Reported, not failed"`, which
  guards the finish gate. My stage prints that same phrase, so at
  `status: done` the two are coupled through a shared string over the whole
  `ci` output. Correct as it stands — nothing should say "Reported, not
  failed" on a done branch — but a reword of either message would break the
  other silently. (recorded, no change; naming it is what a later reader
  needs)
- r4: shellcheck caught two things I did not: backticks inside a
  single-quoted `printf` (SC2016), and `write_ws marks.md done ...` where a
  bare `done` reads as a loop terminator (SC1010). The existing fixture calls
  already quote it, and its own comment says why — I copied the shape without
  the quoting. (fixed)
- r5: verifier round owed and NOT run — standing instruction, twentieth
  consecutive edge. (wontfix on this branch — this session cannot spawn
  subagents, so the round cannot happen here; the gap is the human's to lift
  and is reported on every edge until they do)

  Written as a verdict because THIS GATE demanded one. At `status: done` the
  stage redded `ci` on its own workstream file, naming this bullet, and the
  choice was to disposition it or not merge. That is the behaviour the diff
  exists for, applied to its author before anyone else — and the honest
  verdict is wontfix-here rather than fixed, because nothing about the
  verifier changed.

- r6: **the gate read only each bullet's FIRST line**, so a verdict on a
  continuation counted as no verdict. It flagged r1..r4 of this very file as
  unmarked while every one of them ends in "(fixed" or "(recorded". Caught
  the first time the stage ran against a real workstream file rather than a
  fixture — every case here used one-line findings, and real findings wrap.
  (fixed — `fb_findings`, which folds; and the deciding reason is not
  convenience: `fb_collect` applies `fb_marker` to exactly that folded form
  to produce the count `sources` reports, so any other extraction would
  enforce a different number from the one this stage cites)
- r7: the fixtures could not have caught r6, because all of them wrote
  single-line findings. (fixed — a wrapped pair, one with its verdict on the
  continuation and one without; mutating the fold back to first-lines-only
  reds both)

## Verification

- `mutate` the red-at-done branch → reds **3**, two mine and the finish-gate
  one above; `mutate` the fold back to first-lines-only → reds **2**
- `ci: pass`; `verify` 6 passed, 0 failed; selftest **1103 passed, 0 failed**
  (17 new cases)
- Probed by hand both ways before the cases existed: at `status: in-progress`
  it reports and `ci` stays green; at `status: done` it prints `RED: this
  branch says status: done` and `ci: FAIL`.

## Blockers

None.
