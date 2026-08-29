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

The first two passes were web searches whose queries were not kept, and this
section said so rather than reconstructing plausible ones after the fact. A
third pass, run by the closing session, re-ran the findings with the queries
recorded — because a graduation resting on unreproducible findings inherits
their unreproducibility, and `.agents/docs/research/README.md` names this file
as its one instance of that.

Queries, verbatim:

```
WebSearch: Vale linter accept.txt Vale.Terms substitution rule enforce terminology docs
WebSearch: textlint-rule-terminology npm enforce consistent technical terms CI
WebSearch: Elastic docs Vale ruleset house style guide GitHub elastic/vale-rules
WebFetch:  https://docs.vale.sh/keys/vocabularies
WebFetch:  https://martinfowler.com/bliki/BoundedContext.html
```

Repo counts, on the tree at this branch:

```
git grep -icF -- 'workstream file' -- '*.md' | awk -F: '{s+=$2} END {print s}'
git grep -icF -- 'handover file'   -- '*.md' | awk -F: '{s+=$2} END {print s}'
git grep -lF  -- 'handover file'   -- '*.md'
```

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
- **Bounded Context, now quoted.** Fowler: contexts "each of which can have
  a unified model", and "Different contexts may have completely different
  models of common concepts with mechanisms to map between these polysemic
  concepts for integration." (`WebFetch martinfowler.com/bliki/BoundedContext.html`).
  The earlier passes paraphrased because they had not fetched the page; the
  paraphrase was accurate and is now the source's own words.
- **"Stale language" is NOT a DDD term of art.** Retracted. No source uses
  it as established vocabulary; the adjacent sourced ideas are failure to
  co-evolve the language, technical dominance, and the linguistic divide.
- **The drift is now measured twice, and it closed.** 107 against 10 with
  five files carrying both when this question was filed; **77 against 2**
  on the tree at this branch, two files carrying both. Both survivors are
  required: `.agents/docs/glossary.md`, whose `Not this` cell must spell the
  banned form, and this file, which quotes it. The mechanism shipped in the
  interval and the drift it was built for is gone.

## Consequence for the queue

**None left, and the earlier answer here was overtaken by events.** It said
the question had become *adopt or build* for `docs/plans/harness-glossary.md`.
That plan is retired and the thing is built: `.agents/docs/glossary.md` and
`joharness.sh:lint_glossary` are on `main`, and `ci` runs a `== glossary`
stage. So the choice was made — **build** — and what this file owes its
reader is the reasoning behind it, not a decision still pending.

Bounded Context remains the finding that matters most and is unaffected by
the refutation: a glossary fixing one meaning repo-wide will fight the
layer split this harness is built on. Terms that legitimately differ
between `.agents/harness/` and an environment layer need the zone named,
not a winner picked. That is what graduates.

## Verification

Checked by an independent context that did not write these
findings, asked specifically to refute the negative claim. The third pass
that closed the file re-ran the sources rather than re-deriving them, so its
own claims carry the fetch that produced each; the independent context is
still the one that refuted the original.

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
