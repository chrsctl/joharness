---
research: glossary-enforcement
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/caveman.md
---

## Question

Is there established practice for mechanically enforcing a controlled
vocabulary in documentation, or would `harness-glossary`'s ci lint be
inventing one?

## Echo

`docs/plans/harness-glossary.md` proposes a glossary with an avoid-list and
a ci stage that fails when a banned wording appears in a tracked file. I am
asking whether that enforcement mechanism has prior art, because a plan
that invents a mechanism carries a different risk than one that copies a
proven one.

## Sweep

Goal-directed. Vocabulary discipline in software practice and whether
anyone automates it — not the whole of terminology management.

## What would settle it

Either a named practice with tooling, in which case the plan should follow
it, or an absence, in which case the plan is inventing and should say so.

## Findings

- **The discipline has a name and strong pedigree.** Ubiquitous Language in
  Domain-Driven Design: one shared vocabulary spanning conversation,
  documentation and the code itself.
- **The drift this repo measured has a name too.** "Stale language" is a
  recognised pitfall — terminology drifting out of step with the model over
  time. This repo's own count on 2026-08-25 was "workstream file" 107
  against "handover file" 10, with five files using both.
- **Bounded Context is the missing concept.** A term carries a single
  consistent meaning inside a delimited zone. This harness has two zones
  already — `.agents/harness/` and `.agents/env/<name>/` — and the
  glossary plan treats vocabulary as repo-global.
- **No tooling prior art surfaced.** The search returned no established
  practice for automated linting or drift detection over a controlled
  vocabulary; DDD's answer is recurring cross-functional conversation, a
  human ritual. Absence of evidence in one sweep is not proof none exists,
  and the sweep was goal-directed.

## Consequence for the queue

`harness-glossary`'s ci lint has no prior art behind it. That is not a
reason to drop it — the drift is measured and real, and a human ritual does
not transfer to a repo whose contributors are sessions that never meet.
But the plan should state that the enforcement half is invented, so a later
session weighing a finding against it knows it is weighing a local
invention rather than an industry practice.

The Bounded Context finding is the more useful one: a glossary that fixes
one meaning repo-wide will fight the layer split the harness is built on.
Terms that legitimately differ between the harness layer and an environment
layer need the zone named, not a winner picked.

## Verification

PENDING — no second context has checked these claims. The one most worth
checking is the negative: "no tooling prior art" is a claim about absence
from a single goal-directed sweep, and a comprehensive sweep by a second
context could overturn it cheaply.

## Graduates to

`.agents/docs/caveman.md`, which already owns this repo's rules about
instruction-file wording, including what must never be reworded.
