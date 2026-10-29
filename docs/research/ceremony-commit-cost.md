---
research: ceremony-commit-cost
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/handover.md
---

## Question

Can the claim, handover and retire commits be cut by half without losing
claim-by-push, the same-commit handover rule, or the retire-before-PR rule?

## Echo

In gx since 2026-10-15, 253 of 802 commits on merged branches (31%) were
claim, handover, retire or scratch commits. That cost is paid on every pull
request: the typical one goes from claim to merge in 31 minutes. Before
cutting anything, the answer must say which commits buy a guarantee and
which are habit.

## Sweep

`goal-directed`: every commit kind the Loop asks for, the rule that asks
for it, and whether a later commit could carry it.

## What would settle it

For each ceremony commit kind, a yes or no, with the rule that needs it as
a separate commit:

- the claim push, needed before any code exists;
- the handover-only commit;
- the retire commit, needed as the LAST commit before the PR.

Then a count from gx history of how many such commits a "yes" removes.
Either outcome settles the question: a plan, or a recorded "keep, because".

## Method

To be written by the researcher before running. Start from:

`git -C <gx> log --since=2026-10-15 --no-merges --format=%s | awk '{print $1}' | sort | uniq -c | sort -rn`

## Findings

None yet.
