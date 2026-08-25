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

- **Goodhart's Law is the mechanism — but mind the attribution.**
  "When a measure becomes a target, it ceases to be a good measure" is the
  standard modern statement and safe to use as *commonly stated as*. It is
  NOT Goodhart's wording: his 1975 original is "Any observed statistical
  regularity will tend to collapse once pressure is placed upon it for
  control purposes", and the popular phrasing is Strathern's (1997), citing
  Hoskin. Quoting the short form as Goodhart's own sentence is wrong.
- **Gaming as a design failure rather than a discipline failure** holds,
  but rests on industry writing, not on a literature consensus. The one
  academic anchor is Robert Austin, *Measuring and Managing Performance in
  Organizations* — measurement dysfunction under partial observability.
  Cite Austin; do not claim the field agrees.
- **DORA does NOT say what this file first claimed.** The sentence
  "individual metrics create competition while team metrics create
  collaboration" traces to no DORA, Google Cloud or *Accelerate* source.
  What dora.dev actually says is about team-vs-team siloing: "Sharing all
  five metrics across development, operations, and release teams fosters
  collaboration and shared ownership... Isolating teams with specific
  metrics can lead to friction and finger-pointing", and "The goal is to
  improve your team's performance over time, not to compete against other
  teams". A different proposition from the one first written here.
- **What DORA does support**, and is quotable: its metrics are team- and
  system-level and should not be tied to individual performance review.
- **Shadow metrics.** Pair a target with a metric representing the harm its
  gaming would displace, so the displacement shows up rather than hiding.
  Industry practice, not a sourced study.
- **Retire metrics.** Long-lived metrics accumulate gaming strategies; a
  metric that has served its purpose should be removed. Same standing.

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

Both survive the verification pass, because neither depends on the DORA
sentence that failed. Pairing is supported by dora.dev's own reasoning
about not isolating metrics; retirement is industry practice and the plan
should say so rather than dressing it as research.

## Verification

Checked 2026-08-25 by an independent context that did not write these
findings.

- DORA "individual metrics create competition" — **UNGROUNDED as an
  attributed quote**. No DORA-affiliated source uses it; exact-phrase
  search returned only secondary newsletters. Replaced above with dora.dev's
  actual siloing text, which supports a narrower point.
- Goodhart short form — **GROUNDED as the standard statement, UNGROUNDED as
  Goodhart's own words**. Attribution corrected above.
- Design-not-discipline — **WEAK**: industry writing, not literature.
  Austin substituted as the anchor.

The claim this file flagged for checking is the one that failed. Flagging
it was right; publishing it unflagged would not have been.

## Graduates to

`.agents/docs/agent-selection.md`, which already holds this repo's
measured-behaviour reasoning (review depth, churn thresholds and their
backtest).
