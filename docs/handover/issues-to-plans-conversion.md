---
workstream: issues-to-plans-conversion
status: in-progress
branch: claude/issues-to-plans-conversion-qynza3
pr: none
plan: none
issue: 271
session: https://claude.ai/code/session_012KwmZctRi7ak4SDi197f3c
agent: opus
updated: 2026-09-17
next: Run ci and verify, retire this file, open the pull request
---

## Goal

Human ask, 2026-09-17: convert issues to plans. Loop step 2 — nothing builds
unplanned, an issue decomposes into a plan before code, and the
decomposition IS the work. Six issues were open. Five already carry a queue
artifact from earlier conversions; one, #271, carried none.

## Decisions

- **One plan, not six.** Each open issue was read against the artifacts that
  already exist rather than converted on sight. Coverage as counted
  2026-09-17:

  - **#249** — the scheduler half is `docs/research/scheduler-outside-the-
    fleet.md`, free in the queue; the liveness-field half is
    `docs/research/liveness-in-a-long-turn.md`, claimed and live on
    `origin/claude/drain-8jr601`. Its first cut merged as #253.
  - **#251** — `docs/research/peer-divergence-in-conduct.md`, free in the
    queue. Its other cheap slice, `findings-with-the-fix`, was built,
    backtested and WITHDRAWN (`71285ba`): the rule it would have enforced is
    not the one being broken. The sampling reviewer itself is money and
    stays the human's.
  - **#254** — proposal 1 merged as #257; proposal 3's half without a
    threshold is `docs/plans/unowned-block-age.md`, free in the queue.
    Proposal 2 is product direction and the threshold is a number, both the
    human's.
  - **#258** — option 1 built and retired (`53649d8`); option 2 is
    `docs/plans/promote-before-retire.md`, free in the queue; option 3 is
    where a consumer's findings should go, left with the human.
  - **#267** — `docs/plans/verifier-cannot-read-the-plane.md`, free in the
    queue, written by #269.
  - **#271** — nothing. This plan.

- **The plan carries no `research:` edge** to
  `bash-guard-reads-prose-as-a-loop`, though it is the node's graduation.
  The edge BLOCKS a plan while the node exists, and this is the one plan
  whose merge deletes it; declaring it would park the fix forever. Said in
  the plan's Goal so the next reader does not add it back.

- **Four payloads in the plan, not one.** The issue names the nested-`for`
  shape. Running it turned up a second false negative — an unbounded `until`
  inside a counter-bounded `while`, swallowed by the advance past the outer
  `done` and never judged. Review added the other end: the research node's
  two prose shapes are refused today and hold no unbounded loop. All four are
  the same pairing, so the plan closes both ends or neither.

- **The guard has two states in all history, and that answers a design
  question.** `f9ea7d6` matched once, greedily, over the whole command:
  payload 1 denied, both prose shapes allowed, and the two-loops case wrong —
  which is why `be726cb` replaced it with the per-loop walk. So three of the
  four payloads are regressions from that walk and only one predates it. The
  first draft said "both pre-existing" and cited a commit at which the guard
  is byte-identical to HEAD; corrected under r3.

- **agent: opus, effort: high** for that plan. The reverted narrowing was
  attempted twice and failed twice, and the bar is every existing case
  holding plus each new line pinned by mutation.

## Rejected

- **A plan from #249's newest comment (2026-09-17 17:09Z).** It reports that
  `orchestrate.md`'s IDLE row cannot be followed as written, because the
  nudge has no channel to a cloud session. Checked against the file here,
  and canonical already carries that branch: the tools table says what a
  missing `SendMessage`/`ListAgents` costs, and the STALL row says "NO
  messaging tool, or no row for it: send nothing and still write the ledger
  entry", which the IDLE row inherits by reference. Those landed `eb7a6c2`
  (2026-09-06) and `3c30289` (2026-09-11), both before the run that filed
  the comment — so it reads as a consumer on an older sync, the same shape
  as #254's own correction. Nothing to plan; reported to the human instead.

- **A plan from that comment's `cost_usd` discriminator.** It is evidence
  for `liveness-in-a-long-turn`, which is claimed and live on another
  branch. Not this session's to take (step 2). Flagged to the human,
  because that branch's graduation currently says `updated_at` is written by
  neither a read nor the connection, and the comment reports two unrelated
  sessions returning it 1.6 ms apart.

- **Manufacturing a carve-out from #251's remaining four conduct
  questions.** The issue puts the sampling reviewer's cost with the human
  and the two slices that could be carved already were. Writing a third
  would be inventing work.

## Review

Opus depth, adversarial. Nine findings, all from the independent reader; the
three that would have changed the plan most were re-derived here before
acting on them, and all three held.

- r1: (verifier) the Scope could not reach its own Acceptance. It prescribed
  replacing the end-finder — two lines — and payload 2 stays exit 0 under
  exactly that change: the wider span lets the outer loop's own counter bound
  it, the walk continues, and the advance past the outer `done` swallows the
  inner `until` whole. Prototyped and measured by the reader. (fixed: Scope
  now names four lines and makes re-judging a nested loop the requirement,
  with the prototype's reading as the evidence.)
- r2: (verifier) the plan deleted the research node while the node's own
  question is still live — its two prose reproducers are DENIED at HEAD, and
  the `when` control is allowed, so the prose keyword is the whole cause.
  Re-derived here. Depth counting alone does not fix them. (fixed: the four
  payloads are now one Acceptance covering both ends, the deny message the
  node records as owed is in Scope, and the deletion is conditioned on the
  prose shapes reading exit 0.)
- r3: (verifier) "both pre-existing, before #270 (`31064b7`)" was vacuous and
  half wrong. Re-derived: `git diff 31064b7 origin/main` on the guard is
  empty and #270 never touched the file; the guard has two states in all
  history, and at `f9ea7d6` payload 1 is DENIED. So payload 1 and both false
  positives are regressions from the per-loop walk (`be726cb`); only payload
  2 predates it. (fixed: Goal carries the two-state history and what it
  answers — the whole-command reader held the ends and lost the middle.)
- r4: (verifier) the SHIPS bullet claimed a consumer's `ci` runs this topic.
  Re-derived: `sync-to-consumer.sh` exempts `.agents/harness/selftest.sh` and
  the whole `.agents/harness/selftest` directory, and `cmd_ci` prints `not
  here` in a consumer — zero cases. (fixed: the consumer-side check is the
  payload feed against the synced guard, and the split is stated.)
- r5: (verifier) Acceptance omitted `./joharness.sh verify`, which step 7
  requires for a diff touching non-`*.md` files under `.agents/harness/`.
  (fixed.)
- r6: (verifier) "the two lines" undercounted: the end-finder is three lines
  and the advance below it is part of the same decision. (fixed in the plan
  and in this file.)
- r7: (verifier) payload 2's diagnosis was inverted. The outer counter is
  that loop's own legitimate bound; what is foreign is the `sleep`, and the
  cause is the swallowed inner loop. Pointing an implementer at `count_re`
  would have spent the effort budget in the wrong place. (fixed: Goal and
  Scope rewritten.)
- r8: (verifier) `${rest%%"$seg"*}` names no variable in the guard. The
  issue's own text carries that spelling and it was copied without checking.
  (fixed: `${rest%%"$kw"*}` and `${rest%%"$end"*}`.)
- r9: (verifier) once this merges, the plan and the still-open node are two
  free items over one file, and the queue cannot say so — a research node has
  no `scope:`, so the wave proof cannot see it. (fixed: one line in the
  node's `## Consequence` names the plan and says taking one means taking the
  other.)

Checked and found sound, so recorded rather than assumed: the reproduction
and both case counts (cross-checked a second way), termination, fail-open,
`cmd_mutate`'s behaviour, every anchor target, the frontmatter and section
shape, `curate` and `ci` verdicts, the no-`research:`-edge mechanics, and
every repo-checkable element of the coverage table above. The reader has no
GitHub tool, so every claim about issue text and comments is outside its
reach and stays unverified by it — named here rather than left implied.

## Blockers

None.

## Where to look

- `docs/plans/guard-pairs-done-by-depth.md` — the one artifact this work
  adds.
- `.agents/harness/pretool-bash-guard.sh:end_re` — the decision the plan
  replaces: three lines, plus the advance below them.
- `docs/research/bash-guard-reads-prose-as-a-loop.md` — the answer the plan
  graduates, and its `## Consequence`, which forbids the cheap fix.
