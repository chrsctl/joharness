---
research: where-a-consumers-own-findings-go
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/feedback.md
---

## Question

Where should a finding a consumer discovered about its OWN product go, given
that `upstream` deliberately refuses to carry it to the canonical and
`feedback` serves it only to a session that touches the same path?

This is #258's third direction, verbatim: "Point `upstream` at the consumer
too. The extraction machinery already works. What it lacks is a **destination**
for the findings it calls `unplaceable` — the ones about the consumer's own
product. That is the largest change and the one that fits the existing design
best." The issue's closing line calls it "the real fix".

A question rather than a plan because the destination is undecided, and a
destination nobody has chosen cannot have acceptance criteria. #249's scheduler
half is in this directory for the same reason.

## Echo

Two of #258's three directions have landed, each citing the issue in its own
commit message, so this file does not re-propose them:

- `f083aa0` — "Issue #258's first option": `.claude/commands/manage.md` §4's
  `lead <stem>: <text>`. Partial by construction: #258's measured instance was
  three findings about three queue items, and §4 says "One lead, not a list" at
  40 characters.
- `436d3a1` — "Issue #258, option 2": `joharness.sh:fin_promote` prints the
  finding count and the promotion count before the retire commit destroys the
  file.

And the issue's central factual claim no longer holds. It says findings are
"written down properly and then destroyed on merge". `joharness.sh:cmd_feedback`
serves them out of merged history; `./joharness.sh feedback joharness.sh`
returns findings from merged edges today. So this question is narrower than the
issue as filed: not "the findings are lost" but "which findings have no reader,
and where should they go".

## Sweep

Readers that exist, so an answer does not invent a second channel for a shape
already served:

| shape | reader today |
| --- | --- |
| finding whose fix path the canonical owns | `upstream` → `/upstream-report` on the canonical |
| finding whose fix path the consumer owns | `joharness.sh:cmd_feedback`, keyed on that path |
| finding with no path, no stem | `.claude/commands/manage.md` §4 routes a stem-less lead to the pull request body, "which outlives you and which a human reads" |
| finding with no `r<N>:` id | `joharness.sh:cmd_feedback` already counts these in its `volume:` line and prints a sentence for them |

That last row matters for whoever answers this: the sentence `feedback` prints
for a no-id finding is the existing idiom for "counted here, but nothing links
them to the files they landed on". An answer should reuse that wording rather
than invent a second one.

## What would settle it

- Which bucket is actually homeless, counted on a real consumer edge rather
  than reasoned. `cmd_upstream` splits three ways and the boundaries are not
  where a reader expects: a finding whose TEXT names a path the canonical does
  not own lands in `unplaceable` even though it carries a path, and the
  `from_text` case is not visible in any summary. Settle what the sets are
  before proposing where they go.
- Whether the destination is a place (a file, an issue, a report) or a reader
  (a command a human runs). #258 frames it as "the human running the fleet",
  which is a reader, while its own wording says `upstream` "lacks a
  destination", which is a place.
- Whether anything should be automatic. `JOHARNESS_UPSTREAM_FEEDBACK` is off by
  default and that default is the requester's, not an implementer's.

## Method

**This repo cannot answer it.** `cmd_upstream` returns early when
`JOHARNESS_CANONICAL=1`, which `joharness.conf` sets — `./joharness.sh
upstream` here prints "CANONICAL — this repo IS the harness … Nothing to
route". So the counting has to happen against a consumer's merged edge, or
against a fixture whose conf omits that key. A session that answers this from
the canonical checkout alone will produce numbers no edge can reproduce.

## Findings

Not yet answered.

## Consequence for the queue

Nothing is blocked on this. The two landed directions stand on their own, and
no plan names this question in `needs:`.

## Verification

Whatever answer lands carries the command that re-counts each number, and the
repo it was counted in — a figure measured on the canonical checkout is a
figure about a code path that returns early there.

## Graduates to

`.agents/docs/feedback.md`, which already documents the three buckets and the
rule that an unplaceable finding never flips the report verdict on its own.
The answer belongs beside that, not in a new file.
