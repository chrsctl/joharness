---
research: sonnet-verifier-on-opus-plans
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/agent-selection.md
---

<!--
Split out of `docs/research/cost-per-merge-levers.md` when that node
closed: levers 1, 2 and 4 answered NO by ceiling and graduated
(`.agents/docs/agent-selection.md`, Cost levers). Lever 3 is the one whose
ceiling cleared the bar in one fleet. Recover the parent's readings:
`git log --diff-filter=D -- docs/research/cost-per-merge-levers.md`.
-->

## Question

In this repo's fleet, does a sonnet 5.5 verifier on opus-tier plans cut
cost per merged edge by at least 20% without more reverted merges or more
defects reaching `main`?

## Echo

In the parent's sample, verifiers in this repo's 10 opus-tier manager
sessions cost 21.93 USD, 37.1% of all 12 sampled managers (59.04 USD);
every subagent there was a `verifier`. Sonnet 5.5 bills half of opus 5.5
per token. At equal tokens the cut is 18.6% — under the bar. It clears
20% only if the sonnet verifier also spends at most ~92% of the opus
verifier's tokens. And the review-depth rule
says the verifier exists for independence, so a cheaper verifier that
misses defects costs reverts, which count against it. The gx fleet already
answered NO (16.0% even at a 100% cut).

## Sweep

`goal-directed` — enough paired verifier runs to fix the sonnet/opus token
ratio and compare findings on the same diffs; then a fleet trial only if
the ratio clears the bar.

## What would settle it

1. Token ratio: the same verifier prompt on the same 10 merged opus-tier
   diffs at sonnet 5.5 and at opus 5.5, cost read from each run. Median
   sonnet/opus cost ratio > 0.46 = NO (cannot reach 20%), no step 2. The
   0.46 uses the manager-only denominator, so it can only prove NO: at or
   below it the lever MAY reach 20%, and only the fleet trial in step 3,
   with orchestrator cost in, says whether it does.
2. Findings: for each of the 10 diffs, the merged edge's own `## Review`
   (the workstream file in git history) is the record. A finding the
   sonnet run missed that the record marks `(fixed)` = NO. Misses the
   record marks `wontfix` or `no change` do not count; neither does a
   finding of the fresh opus run that the record lacks.
3. No `(fixed)` miss = a fleet trial a human authorises (tier change =
   money): 10 merged edges each way, the parent's settling rule.

## Method

Not run yet.

## Findings

None yet.

## Consequence for the queue

A YES becomes a plan a human authorises: the verifier tier rule in
`.claude/agents/verifier.md` and `./joharness.sh review`. Those govern
every consumer, and gx already answered NO, so the plan scopes the change
to fleets whose verifier share clears the bar — how is the human's call.

## Verification

None yet.

## Graduates to

`.agents/docs/agent-selection.md` Cost levers.
