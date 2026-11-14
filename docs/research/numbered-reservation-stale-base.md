---
research: numbered-reservation-stale-base
urgency: normal
agent: opus
effort: medium
graduates: .agents/docs/plans.md
---

<!--
Report from consumer chrsctl/gx (upstream-report, filed on a human's request).
Canonical decides; nothing here is a fix.
-->

## Question

Does `.agents/docs/plans.md` § Numbered artefacts state that reserving in the
plan's own pull request stops two branches taking one number, when nothing
measures that the reservation merged before another branch picked the same
"next free" number?

## Echo

The rule moves the race from the building branch to the plan pull request,
but a plan pull request picks its number from the base it branched from and
can stay open for hours; a building branch whose plan reserved nothing (or a
`plan: fast` branch) picks from its own base too. Two picks from two stale
bases land on one number, the registry conflicts textually at merge, and the
later one renumbers by hand. What rests on it: whether the rule needs a
check (registry claim re-validated against fresh `origin/main` at merge) or
only a wording change.

## Sweep

`goal-directed`: one consumer night (2026-11-13/14) on chrsctl/gx, its
criteria-id registry `tools/criteria/blocks.md`.

## What would settle it

Settled YES if a branch that followed the rule (reserved in its plan pull
request) still lost its number to another branch's in-branch claim. Settled
NO if every collision traces to a branch that broke the rule outright.

## Method

```
git log --format='%h %ad %s' --date=iso -S'CRM7960-7969: reeve-fit-timeline' origin/main -- tools/criteria/blocks.md
git log --format='%h %ad %s' --date=iso e10769be6^1..e10769be6^2
git show badaa2e0d --cc -- tools/criteria/blocks.md
git show 14d9f4d2c:docs/plans/reeve-fit-timeline.md | head -12
git log --format='%h %ad %s' --date=iso -3 -- tools/criteria/blocks.md   # on badaa2e0d^2
./joharness.sh upstream clerk-2026-11-13-e
```

Run in chrsctl/gx, 2026-11-14 ~06:20Z.

## Findings

- **A building branch claimed a block in-branch although it had a plan.**
  `14d9f4d2c 2026-11-13 19:47:46Z timeline: browser checks, criteria
  CRM7960-7963, handover` added `CRM7960-7969: reeve-fit-timeline` to
  `tools/criteria/blocks.md`. Its plan `docs/plans/reeve-fit-timeline.md`
  exists (no `plan: fast`), so per § Numbered artefacts the number should
  have been reserved by the plan pull request. Merged as #1686 at
  2026-11-14 00:54Z.
- **The clerk followed the rule and still lost.** Clerk PR #1678
  (`clerk-2026-11-13-e`): `2f6778a61 2026-11-13 22:19:31Z Plans for #1662
  and #1657 (reserves CRM7960-7969)` — reserved in the plan pull request as
  § Numbered artefacts and `.claude/commands/clerk.md` (HOLDS) say. Its base
  did not hold the timeline line (unmerged). The PR stayed open until
  `badaa2e0d 05:42:46Z Merge origin/main into clerk-2026-11-13-e`, whose
  combined diff shows both sides appending at the registry's tail
  (`+ CRM7960-7969: reeve-fit-timeline` vs `+CRM7960-7969:
  suggest-door-own-key-allowance`) — no automatic merge; then
  `402e4b972 05:44:40Z Move suggest plan's criteria block to CRM8010-8019
  (7960-7969 taken)`. Cost: ~7h20m the reservation was not a reservation,
  plus a manual renumber of the plan file.
- **Same shape twice more that night.** `d546901d1 2026-11-14 04:17:23Z
  Merge origin/main; the rail's criteria move to CRM8000-8003 (CRM7970
  block taken by reeve-fit-chart-view)` — a second in-branch claim beaten by
  a third.
- **The edge is invisible to `upstream`.** `./joharness.sh upstream
  clerk-2026-11-13-e` printed `no workstream file on this edge ... verdict
  : NOTHING TO REPORT`. Clerk edges carry no workstream file by protocol, so
  a harness defect met by a clerk never routes; this report was filed by
  hand on a human's instruction.

Dropped: none; one edge, findings all measured above.

## Consequence for the queue

`.agents/docs/plans.md` § Numbered artefacts: the "Why" claims the race is
removed; measured, it is moved and widened (a plan PR open for hours holds
a number that is not yet on main). Candidate changes for canonical to weigh:
(a) say the reservation counts only once merged, and that a plan PR re-picks
after merging `origin/main` at finish; (b) a building branch with a plan
adds no registry line (the consumer's ADR 0383 rule already says this; the
timeline branch broke it unchecked); (c) a `finish`-time check that the
branch's registry lines are not claimed on fresh `origin/main` by another
owner. Also: whether `upstream` should route clerk edges with no workstream
file.

## Verification

Not yet verified from a second context.

## Graduates to

`.agents/docs/plans.md` — the rule whose "Why" this measures.
