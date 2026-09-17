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
next: Review the plan with a verifier, record findings, retire this file
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

- **Two payloads in the plan, not one.** The issue names the nested-`for`
  shape. Running it turned up a second, and the second is worse — an
  unbounded `until` inside a counter-bounded `while`, where the counter that
  lets it through belongs to a different loop. Both measured ALLOWED here
  and on the pre-#270 guard (`31064b7`).

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

- r1: (open) — verifier pass on `docs/plans/guard-pairs-done-by-depth.md`
  not yet run.

## Blockers

None.

## Where to look

- `docs/plans/guard-pairs-done-by-depth.md` — the one artifact this work
  adds.
- `.agents/harness/pretool-bash-guard.sh:end_re` — the two lines the plan
  replaces.
- `docs/research/bash-guard-reads-prose-as-a-loop.md` — the answer the plan
  graduates, and its `## Consequence`, which forbids the cheap fix.
