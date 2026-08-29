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

First pass goal-directed, and it got the answer wrong. Second pass
comprehensive, run by the verification context specifically to refute the
first — which it did.

## What would settle it

Either a named practice with tooling, in which case the plan should follow
it, or an absence, in which case the plan is inventing and should say so.

## Method

Not recorded. Both passes were web searches and the queries were not kept,
so there is nothing to quote here — this section says so rather than
reconstructing plausible queries after the fact, which would read as a
record and be a guess. The shape came later than the file
(`.agents/docs/research/README.md`); the cost of that is exactly this: the
findings below cannot be re-run as written.

## Findings

- **Controlled-vocabulary linting is mature, named, and in production.**
  Vale ships the mechanism directly: entries in `accept.txt` are
  automatically added to a substitution rule, `Vale.Terms`, "ensuring that
  any occurrences of these words or phrases exactly match their
  corresponding entry". `textlint-rule-terminology` does the same for tech
  writing and runs as `textlint --fix --rule terminology`, i.e. CI-ready.
  Datadog and Elastic both run Vale over their docs; Elastic publishes its
  house style as a Vale ruleset.
- **Adjacent enforced-term tooling exists too**: alex, write-good,
  proselint, woke, retext, and the Microsoft Writing Style Guide packaged
  as a Vale ruleset.
- **Even the DDD half has tooling.** A Ubiquitous Language Verifier exists
  that checks correspondence between vocabulary in code and the domain
  model. DDD's *canonical* answer is still recurring human conversation,
  but "no tooling" is false.
- **Bounded Context, paraphrased not quoted.** Fowler describes contexts
  "each of which can have a unified model", with different contexts holding
  "completely different models of common concepts" and explicit mappings
  between them. No one-line formal definition matches the phrasing this
  file first used.
- **"Stale language" is NOT a DDD term of art.** Retracted. No source uses
  it as established vocabulary; the adjacent sourced ideas are failure to
  co-evolve the language, technical dominance, and the linguistic divide.
- **The drift this repo measured is still real and still local**:
  "workstream file" 107 against "handover file" 10 on 2026-08-25, five
  files carrying both.

## Consequence for the queue

`harness-glossary`'s motivation changes shape. Its plan proposes building a
ci lint for banned wordings; Vale's `accept.txt` plus `Vale.Terms` is
precisely that, already built and running at Datadog and Elastic. The open
question is no longer *invent or not* but **adopt or build** — and adopting
brings a dependency into a harness whose ci is currently shell and
shellcheck, which is a real cost to weigh rather than a free win.

Bounded Context remains the finding that matters most and is unaffected by
the refutation: a glossary fixing one meaning repo-wide will fight the
layer split this harness is built on. Terms that legitimately differ
between `.agents/harness/` and an environment layer need the zone named,
not a winner picked.

## Verification

Checked by an independent context that did not write these
findings, asked specifically to refute the negative claim.

- Original central claim — "no tooling prior art exists" — **UNGROUNDED,
  decisively refuted**, with named tools and production adopters. Findings
  above rewritten from the refutation.
- "Stale language" as DDD terminology — **UNGROUNDED**. Retracted above.
- Bounded Context — **GROUNDED in substance**, but paraphrase rather than
  quote; done.

The negative claim was reached from one goal-directed sweep and stated as
though it were general. That is the failure this file now records against
itself: absence from a narrow sweep is not absence.

## Graduates to

`.agents/docs/caveman.md`, which already owns this repo's rules about
instruction-file wording. The adopt-or-build question belongs in
`harness-glossary` itself and is named there, not settled here.
