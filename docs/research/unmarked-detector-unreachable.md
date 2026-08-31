---
research: unmarked-detector-unreachable
urgency: urgent
agent: opus
effort: medium
graduates: docs/product/unsupervised-mode.md
---

## Question

Can `sources`' unmarked-findings detector ever reach zero, and if it cannot,
what should replace it — given that the mode is only allowed to stop when
every detector is zero?

## Echo

`unsupervised-finding-dedupe` asks me to implement the requirement's
constraint that a finding already addressed by a plan stops counting as a
source. Before writing it I checked what the detector counts. It counts
findings in MERGED history, and merged history cannot be edited — so the
question is not "how do I dedupe" but "is the thing I am deduping capable of
reaching zero at all". If it is not, the constraint the plan implements
cannot achieve its own stated purpose, and writing it is the expensive
mistake the salvage plan warned about: a plan for work that cannot pay off.

What rests on it: the mode's only stopping condition, and therefore whether
an unsupervised fleet can ever terminate.

## Sweep

`goal-directed` — everything needed to decide whether this detector can be
driven to zero, not a survey of the feedback measure. Specifically: what the
detector reads, whether that input is mutable, and whether the prescribed
dedupe can name every item in it.

## What would settle it

- **Reachable**: some sequence of commits a session could make drives the
  count to 0. Then the plan proceeds as written.
- **Unreachable**: the count is a function of immutable history, and the
  prescribed dedupe cannot name every contributor to it. Then the plan is
  blocked and the requirement needs a different detector.

The deciding number is how many unmarked findings carry no `rN:` id: a
citation keyed on `<label>:<id>` cannot name those, whatever the citation
mechanism is.

## Method

```
JOHARNESS_FEEDBACK_EDGES=0 ./joharness.sh feedback
sed -n '/^src_unmarked()/,/^}/p' joharness.sh
JOHARNESS_FEEDBACK_CACHE="$D" JOHARNESS_FEEDBACK_EDGES=0 ./joharness.sh feedback
awk -F'\t' '...'  "$D"/fb-*.hist     # marker precedence copied from fb_marker
```

All on `main` at `aecd338`, 2026-08-31.

## Findings

- **The detector reads every merged edge, deliberately.** `src_unmarked`
  sets `local FB_LIMIT=0` with the comment "Read EVERY edge, overriding
  FB_LIMIT… a sweep that decides whether a fleet may stop has no business
  trading completeness for speed." So its input is all of merged history.

- **That input is immutable.** A finding lives in a `## Review` section of a
  workstream file, and step 7 deletes that file in the pull request that
  merges it. The text survives only inside merged commits. Nothing a session
  can commit changes what a past commit says, so the count is
  monotonically non-decreasing.

- **155 findings are unmarked, and 62 of them carry no `rN:` id.**
  `feedback` reports 154 unmarked of 811; a re-count from the cached history
  using `fb_marker`'s own precedence gives 155, a one-finding discrepancy I
  did not chase because it does not move the argument. The split is
  93 keyable / **62 unkeyable**.

- **Therefore citation-based dedupe cannot reach zero.** `fb_keyable`
  requires `r<digits>:`; 62 findings have no such id, so no citation keyed on
  the finding can ever name them. The best case for the plan as written is
  155 → 62, and 62 ≠ 0.

- **Therefore the sweep can never be dry.** `cmd_sources` sets `dry=0`
  whenever `unmarked` is non-zero. `sources` on `aecd338` prints `sweep NOT
  dry — checks(0 failing, 1 skipped) findings(151 unmarked)`.

- **This is the failure the requirement forbids, from inside.** Its own
  constraint: "An uncountable source never reaches zero, so a mode that
  draws on one can never terminate." This source is countable but
  unreachable, which has the same consequence and is not covered by the
  wording.

## Consequence for the queue

`docs/plans/unsupervised-finding-dedupe.md` is BLOCKED on this question and
now carries `research: unmarked-detector-unreachable`. Implementing it as
written would move 155 to 62 and leave the mode unable to stop.

`docs/plans/unsupervised-stop-condition.md` is NOT blocked: it makes the
four parts of the condition countable, which is right whatever this
detector becomes, and it explicitly holds the 151 out of scope.

Three candidate answers, for the human, because which one is chosen decides
when a fleet may stop:

1. **Count only findings newer than a baseline commit.** History before the
   mode existed is not the mode's backlog. Reachable immediately, and matches
   the constraint's stated purpose — "a finding that unsupervised-generated
   work itself introduced". Needs a baseline nobody can quietly move.
2. **Count only keyable findings, and make an unkeyable one red at the
   edge.** `lint_finding_ids` already reports them. Reachable, but only
   after the 93 keyable ones are addressed, and it silently writes off 62.
3. **Keep the detector and add citation dedupe anyway.** Reaches 62 and
   stops. Not an answer; recorded so it is not re-proposed.

My recommendation is 1, with 2 as prevention beside it: 1 makes the count
reachable, 2 stops the same hole reopening. Both are cheap. Neither is mine
to ratify, because the choice changes when an unattended fleet is allowed to
stop.

## Verification

Not yet verified from a second context. Every finding above carries the
command that produced it and can be re-counted; the load-bearing one is the
62, from `awk` over the cached history with `fb_marker`'s precedence copied
literally. Marked WEAK until a reader who did not run these commands
re-counts it. The verifier subagent that Loop step 5 names was not spawned —
this session runs under a standing instruction not to spawn subagents.

## Graduates to

`docs/product/unsupervised-mode.md`. The answer changes what "the source
sweep goes dry" means, which is a `Satisfied when` bullet and a Constraint —
requirement text, not a rule line, and the human's to ratify.
