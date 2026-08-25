---
workstream: review-findings-filed
status: review
branch: claude/pr-review-merge-q5vm9t
pr: none
plan: none
session: https://claude.ai/code/session_013gbMpgGTeYzxsBa7RfW4ch
agent: opus
updated: 2026-08-25
next: Delete this file and open the pull request; merge per Loop step 7 once checks are green and the branch is 0 behind origin/main
---

## Goal

Human: "Review prs, research, fix and merge if ready", then "Cleanup; then
run Full Review (also Review structure)", then "Continue". The first two are
done — #67, #68, #70 merged and the leftover workstream file swept. This
branch is the third: land the full review's findings where the next session
will meet them, instead of leaving them in one session's transcript.

The review ran four lenses over `main`: structure, measurement design,
doctrine-against-tree, correctness. Seven findings. Two were small enough to
fix here; three became plans; two are decisions this session does not own.

## Decisions

- **Split by size, using the repo's own rule.** `.agents/docs/feedback.md`
  says capture always, fix inline when small, route when not. The two written
  numbers and the duplicated typo are message-sized, so they are fixed in
  this diff. The layering rule, `verify` on `none`, and the recurrence
  definition each need a decision, a test, or both — those are plans.
- **The stale figure became a fraction, not a fresher figure.** `132K of the
  320K` was counted at 179K of 405K today, and writing today's number in
  would only reset the same clock. The fraction (more than two fifths) is the
  part that carries the argument and the part that does not rot, and the text
  now says to count rather than quote. Same reasoning in both places it
  appeared.
- **`recurrence-can-fall` asks its implementer to CHOOSE, not to guess.**
  Precedent is `guard-docs-only-branch.md`, which names two defensible answers
  and makes choosing the deliverable. Leaving the choice implicit is how the
  current line survived a document that argues against it.
- **`recurrence-can-fall` is opus/high.** It changes the meaning of the
  repo's headline measure and its portability traps have already caused two
  findings in that exact awk (PR54 r1, r3).
- **No dedupe needed against `tree-vs-diff-rule`.** Another session filed it
  while this review ran; it writes the rule, `graph-inherited-workstream-label`
  fixes the caller, and its Out of scope already names mine. Checked, not
  assumed.

## Rejected

- **Filing all seven findings as plans.** Two of them are two-word edits. A
  queue entry for a typo costs a session's orientation to save nothing, and
  the queue is the thing that has to stay readable.
- **Fixing the recurrence definition in this branch.** It was tempting — the
  arithmetic is settled and the fix is small. But choosing the window is a
  call about what the repo's headline number means, and a session that
  reviewed the measure should not also be the one that quietly redefines it.
- **Filing the `JOHARNESS_REVIEW` default as a plan.** It is product
  direction (Decide alone: stop and ask). A plan is work an agent executes
  without a human in the loop; a plan whose first step is "ask the human" is
  a plan that will be claimed and then stall. Surfaced to the human instead.
- **Fixing the `reding` typo only once.** It appears in two functions
  identically. Fixing one leaves the copy that will be copied next.

## Review

- r1: checked every finding still reproduced on today's `main` before writing
  it down, not against the notes taken earlier in the session — `main` moved
  15 commits during the review. The consumer-payload count had already
  drifted again (176K→179K of 403K→405K), which is the finding demonstrating
  itself and the reason the fix is a fraction. (fixed)
- r2: `recurrence` re-counted twice ~40 minutes apart on purpose. N went
  54→57, D stayed 24, the score went 55%→57%. Three data points beat an
  argument from arithmetic alone, and the middle column not moving is the
  whole proof. (fixed — the table is in the plan)
- r3: nearly filed `graph-inherited-workstream-label` a second time as part
  of the layering finding. Read `docs/plans/tree-vs-diff-rule.md` first: a
  parallel session had already graduated the rule and cross-referenced my
  plan. A duplicate plan is worse than a missing one — two sessions claim it
  and one wastes a branch. (no change needed — checked before writing)
- r4: `layer-rule-enforced` originally proposed moving the k8s test out of
  `.agents/harness/`. Rejected in the plan's own Out of scope: the test is
  correct where it is, its comment argues why, and a plan that relocates a
  security regression test while claiming to fix documentation has changed
  coverage under cover of a docs change. The defect is that the rule does not
  admit the exception, not that the exception exists. (fixed — became an
  explicit Out of scope)
- r5: `verify-none-layer` scoped to exclude "write an empty smoke-test.sh for
  `none`", which is the obvious fix and the wrong one — it manufactures a
  green tick nobody ran, the exact shape `consumer-repos.md` refuses for sync
  pull requests. (fixed — named in Out of scope)
- r6: confirmed no branch in flight touches `joharness.sh`,
  `.agents/docs/consumer-repos.md` or `.agents/scripts/sync-to-consumer.sh`
  before editing them — `joharness.sh` is the third-hottest file in the repo
  by the feedback measure, and a comment-only edit is not worth forcing
  another session to reconcile. (no change needed — none in flight)
- r7: the two findings this session did not file are recorded in the pull
  request body rather than dropped, because a decision nobody wrote down is
  indistinguishable from a decision nobody noticed. (fixed)

## Blockers

None.

## Where to look

- `docs/plans/recurrence-can-fall.md` — the counted table is the argument;
  the D column not moving is what makes it arithmetic rather than opinion.
- `docs/plans/layer-rule-enforced.md` — Out of scope is the important
  section, not Scope. It exists to stop a helpful session deleting the k8s
  test.
- `.agents/docs/consumer-repos.md`, the canonical-only table — why the text
  now names a fraction and a way to count instead of a figure.
