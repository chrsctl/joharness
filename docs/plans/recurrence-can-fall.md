---
plan: recurrence-can-fall
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
scope: joharness.sh, .agents/docs/feedback.md, .agents/harness/selftest.sh
---

## Goal

`.agents/docs/feedback.md:40` says it plainly:

> **Recurrence is the score. Everything else explains it.**

And `joharness.sh` prints, every run: `— want this falling`.

It cannot fall. Not "has not yet" — cannot, by the definition's own
arithmetic.

`joharness.sh:1336` walks every `(edge, path)` fix pair oldest-first, marks a
path's first-ever appearance as non-repeat and every later one as repeat.
`seen[]` is never cleared and has no window. So for `N` file-level fixes over
`D` distinct paths:

```
repeats = N − D          recurrence = 1 − D/N
```

`N` grows without bound. `D` saturates — the repo is finite, and only a
handful of files ever draw findings. So recurrence converges to 100%
regardless of how well the loop works.

Counted, all three from `JOHARNESS_FEEDBACK_EDGES=0 ./joharness.sh feedback`:

| when | edges | fixes (N) | distinct (D) | recurrence |
| --- | --- | --- | --- | --- |
| 2026-08-24, as written in the doc | 39 | 19 | 12 | 36% |
| 2026-08-25, morning | 58 | 54 | 24 | 55% |
| 2026-08-25, ~40 minutes later | 62 | 57 | 24 | 57% |

The last two rows are the proof and they cost nothing to reproduce: three
more fixes landed, **D did not move at all**, and the score rose two points.
No judgement about loop quality is involved in that movement. It is division.

Two consequences, and the second is worse than the first:

1. The number cannot answer the question the document asks of it, so
   `feedback.md`'s own deferred check — *"The number to watch is whether
   recurrence falls; ask again at 30 edges"* (`:208`) — is unanswerable as
   posed. That threshold has also passed unnoticed, because nothing fires it.
   62 edges now.
2. **It fights the feature printed directly beneath it.** The same output
   lists hot spots — `selftest.sh` at 10 edges, `.agents/harness/AGENTS.md` at
   8, `joharness.sh` at 7 — and tells the session to read what those edges
   found *before touching that file again*. Every finding correctly fixed
   there increments the numerator. A session that does exactly what the
   harness tells it to do drives the score the harness tells it to lower.

The document defends recurrence as ungameable because "producing more output
is not what makes it fall" (`:53`). Under this definition, producing more
output on the files the harness itself points you at is precisely what makes
it rise. The defence is against the wrong failure mode.

## The choice this plan must make

Two defensible answers. **CHOOSE one**, implement it, and record which and
why in the workstream file's `## Review`. Do not implement both, and do not
leave the choice to the reader — that is how the current line survived.

1. **Window it.** Recurrence over the last N edges, or a repeat counted only
   when the earlier finding is within N edges. The denominator can then stay
   flat and the number can genuinely fall. Cost: N is a new arbitrary
   constant, and the harness has to say what it is and why. Precedent for
   naming one: `JOHARNESS_FEEDBACK_EDGES`, the churn threshold, the churn
   ceiling.
2. **Keep it cumulative and stop scoring it.** Cumulative recurrence honestly
   answers a different, still-useful question — *how concentrated is this
   repo's defect surface* — and the hot-spot list is that question answered
   better. Then `feedback.md:40` must stop calling it the score, the printed
   `want this falling` must go, and the document needs a different answer to
   "did the loop work", or an explicit statement that it has none yet.

Answer 1 keeps the document's thesis and pays for it with a constant.
Answer 2 keeps the arithmetic honest and costs the thesis. Both are
defensible; shipping neither is not.

## Scope

- `joharness.sh` — the recurrence computation (`cmd_feedback`, the
  `repeat_pairs` awk) and the line it prints.
- `.agents/docs/feedback.md` — `## Scoring`, the `Recurrence is the score`
  claim, the ungameable defence at `:53`, the `ask again at 30 edges` line at
  `:208`, and the `## What this cannot see` list, which does not name this
  property and should.
- `.agents/harness/selftest.sh` — cases pinning whichever definition wins.

## Out of scope

- **The other four yields.** Coverage, retention, generalization and cost are
  not in question here and changing them widens this past one argument.
- **Making the measure fall.** This plan fixes the instrument, not the
  reading. If honest recurrence is still bad afterwards, that is a true
  result and belongs in the doc as one.
- **Storing anything.** Every number in this subsystem is counted from git at
  read time by deliberate doctrine — "it cannot rot and cannot be written
  wrong". A cache or a checked-in history file breaks the property the whole
  measure rests on.
- **The classes-not-files blind spot.** Already named in the doc, already
  understood, genuinely hard, and independent of this.
- **Re-deriving the historical numbers in the doc.** Whatever the new
  definition is, restate today's count under it and date it. Do not
  back-compute the 36% into the new definition and present it as a trend —
  two definitions on one axis is a worse defect than the one being fixed.

## Acceptance

- A fixture where the loop demonstrably improves — later edges fixing
  findings in files no earlier edge touched — produces a **falling** number
  under answer 1, or produces no scored number at all under answer 2. This is
  the acceptance criterion the current definition cannot meet, and it is the
  whole plan.
- A fixture where the same file draws a finding on consecutive edges raises
  the number (answer 1) or is visible in the hot-spot list (answer 2).
- Whichever answer wins, `feedback.md` and the printed output agree with the
  implementation when read cold. No third statement of the rule anywhere.
- If answer 1: the window constant is named, overridable in the same shape as
  `JOHARNESS_FEEDBACK_EDGES`, and the doc says why that value.
- If answer 2: nothing in the repo still calls recurrence the score, and
  `feedback.md` states what replaced it or that nothing has.
- The `ask again at 30 edges` deferral is resolved, not re-deferred: either it
  fires on a counted threshold, or it is deleted because the new definition
  answers it continuously.
- Equivalence discipline, as PR54 used: diff the new output against the old
  across every origin ref before and after, and record what changed and why.
- `./joharness.sh ci` — `ci: pass`. Trust the counted number, never a written
  one — including every number on this page.

## Where to look

- `joharness.sh`, the `repeat_pairs` awk and the comment block above it
  ("the one number worth watching, and the only one whose direction is
  unambiguous") — that comment is the claim under test.
- `joharness.sh:cmd_feedback`, the `FB_CAPPED` / `JOHARNESS_FEEDBACK_EDGES`
  handling — the existing precedent for a bounded window over edges, and
  probably the shape answer 1 wants.
- `.agents/docs/feedback.md:28-56` — the Scoring section and the
  volume-is-not-a-score argument, which is correct and must survive whichever
  answer wins.
- `.agents/docs/feedback.md:185-209` — the blind-spot list this property
  belongs in.

## Traps

- The hot-spot list and the score must end up pointing the same way. If a
  session can follow the printed advice and worsen the printed score, the
  fix is not finished.
- `awk` here must stay portable: no `delete array`, no `tac`, no GNU-only
  behaviour. PR54 r1 and r3 are both regressions of exactly this in exactly
  this function.
- Rename resolution is unique-suffix matching. A windowed definition changes
  which edges are in scope and can therefore change which renames resolve —
  check it, do not assume it.
- Do not relax the measure because it currently reports badly. The repo's own
  rule: never relax a guard that just caught you. If 57% is the true reading
  under an honest definition, ship the honest definition and the true
  reading.
