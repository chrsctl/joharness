---
research: scorecard-without-gaming
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/agent-selection.md
---

## Question

What stops a process scorecard from being gamed by the sessions it measures?

## Echo

`docs/plans/process-scorecard.md` proposes counting per-branch process
facts — review findings recorded, workstream file moved with code, churn,
step 7 deletions — and reporting them. Sessions read the harness's own
rules, so they can read what is counted and optimise for it. I am asking
whether that is a real risk here and what the literature says prevents it.

## Sweep

Goal-directed. Only: how measured process metrics fail, and which
countermeasures transfer to a harness whose measured subjects can read the
measure.

## What would settle it

A named mechanism for metric failure plus at least one countermeasure
concrete enough to write into the plan. Vague advice to "use good metrics"
settles nothing.

## Method

Web search, 2026-08-25: "engineering process metrics Goodhart's law DORA
metrics gaming vanity metrics that change behavior".

## Findings

- **Goodhart's Law is the mechanism.** "When a measure becomes a target, it
  ceases to be a good measure." Once a metric guides behaviour, it distorts
  the process it was meant to observe.
- **Gaming is a design failure, not a discipline failure.** The sources are
  consistent that people gaming metrics "respond rationally to the
  incentive structure they were given" — so the fix belongs in the metric,
  not in an instruction telling sessions not to game it.
- **DORA's answer is a balanced set, not a better single number.** The four
  metrics are used together specifically because "individual metrics create
  competition while team metrics create collaboration", and pairing them
  lets each bound the others.
- **Shadow metrics.** Pair a target with a metric representing the harm its
  gaming would displace, so the displacement shows up rather than hiding.
- **Retire metrics.** Long-lived metrics accumulate sophisticated gaming
  strategies; a metric that has served its purpose should be removed.

## Consequence for the queue

`process-scorecard` is currently a report, not a gate, which the plan
already argues for on different grounds ("`churn` earned its ceiling with a
backtest; this has no backtest yet"). The research supports that ordering
for a stronger reason: a number nobody is graded on is not yet a target, so
reporting first is what keeps the counts honest long enough to backtest
them.

Two things the plan does not say and should. Its counts want pairing —
"review findings recorded" alone rewards recording noise, and wants pairing
with something that moves the other way. And nothing in the plan retires a
count, so every number it adds is permanent by default.

## Verification

PENDING — no second context has checked these claims. The check to run:
confirm the DORA "individual metrics create competition" wording traces to
a DORA-affiliated source rather than a secondary blog, since the plan would
quote it.

## Graduates to

`.agents/docs/agent-selection.md`, which already holds this repo's
measured-behaviour reasoning (review depth, churn thresholds and their
backtest).
