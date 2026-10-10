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

Verifiers were 37.1% of opus-tier manager cost in this repo's fleet
(21.93 of 59.04 USD, 10 opus sessions, 2026-10-10), every subagent a
`verifier`. Sonnet 5.5 bills half of opus 5.5 per token. At equal tokens the
cut is 18.6% — under the bar. It clears 20% only if the sonnet verifier also
spends at most ~92% of the opus verifier's tokens. And the review-depth rule
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
   sonnet/opus cost ratio > 0.46 = NO (cannot reach 20%), no step 2.
2. Otherwise findings: same 10 pairs, each opus finding the sonnet run
   missed counted. Any missed finding the opus run's author recorded
   `(fixed)` = NO. None missed = YES pending a human-authorised fleet trial
   (tier change = money).

## Method

Not run yet.

## Findings

None yet.

## Consequence for the queue

A YES becomes a plan a human authorises: the verifier tier rule in
`.claude/agents/verifier.md` and `./joharness.sh review`.

## Verification

None yet.

## Graduates to

`.agents/docs/agent-selection.md` Cost levers.
