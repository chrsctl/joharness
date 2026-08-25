---
workstream: research-capability
status: in-progress
branch: claude/research-capability
pr: none
plan: none
session: https://claude.ai/code/session_0126bZYruEVL7vNBLb7RXF4v
agent: opus
updated: 2026-08-25
next: Open PR for the requirement and the research-node plan
---

## Goal

Requester: improve the harness's research capabilities. Came straight out
of re-comparing against joharnessburg — 38 merges in three hours, every one
of them self-governance, and the only plans left untouched were the three
that came from looking outward. The harness can execute what it is given
and cannot find out what it does not know.

## Decisions

- `research` appears exactly ONCE in the whole protocol: the review-churn
  rule's "research step at raised tier or effort"
  (`.agents/harness/AGENTS.md:54`). It names a step with no shape, no
  output and nowhere to put the result. That dangling pointer is the
  concrete gap, not a general wish for the harness to be cleverer.
- A research node, not a research subsystem. Files are nodes, frontmatter
  is edges, delete-on-done is state, and `graduated` already means a node
  reaching `AGENTS.md` or `docs/`. Research reuses all four; the plan says
  that adding a store, an index or a status field means it went wrong.
- An answer carries the command and that command's output. The repo's
  standing rule is trust counted numbers, and research is exactly where a
  written number gets minted.
- A plan may block on an open question via a `research:` edge, reusing the
  `needs` machinery rather than a parallel implementation.
- Deliberately NOT specifying how to research. A methodology written before
  a single research file exists would be invented rather than observed, and
  a session already has Bash, the web and subagents.
- Two files only in this PR. Touching `graph.md`, `queue-context.sh` and
  `lint_graph` is the plan's job; doing it here would collide with five
  queued plans that share those files.

## Rejected

- A `./joharness.sh research` sweep. The queue hook already lists nodes; a
  second view is the stored-copy failure `.agents/docs/graph.md` forbids.
  Reconsider only if the node exists and the hook proves insufficient.
- Back-filling tonight's mechanism comparison into the new shape. Seeding a
  node type with retrofitted content proves nothing about whether the shape
  survives contact with a real question.
- Letting research carry implementation. It settles a question; a plan acts
  on the settlement. Blurred, every disagreement becomes a branch.
- Writing this as a plan without a requirement. The ask is product
  direction from the human, so it enters where product direction enters.

## Review

- r5: the first draft had NO verification section, and the harness's own
  `.agents/docs/graph.md` Rules already carries the diamond rule — verify
  outside the context that wrote the thing. Two independent practices agree
  and I had crossed neither over: John's `grounding-checker` is a separate
  agent because "a model can't reliably audit its own grounding", and
  Anthropic's own research design runs a separate citation pass after the
  subagent fan-out. Measured citation accuracy across commercial
  deep-research systems spans 78% to 94% — the size of the error the
  section catches. Added to the template and to the requirement's
  Satisfied-when. (fixed)
- r6: ADR practice never deletes a record, because superseded ones carry
  the timeline; this harness deletes the node on graduation. Not a
  contradiction to resolve by copying ADRs — the graduated file is where
  the reasoning is supposed to land. But the plan said "graduates to
  AGENTS.md or docs/" without saying which carries what, and a one-line
  rule with the reasoning stranded in a deleted file is how a settled
  question gets re-opened. Now explicit: the rule is what the next session
  obeys, the why-explanation is what stops the session after that
  re-litigating it. (fixed)
- r7: added Echo and Sweep to the template, from John's
  `self-correction-echo` and `sweep-strategy`. Echo catches the
  misread-then-reason-competently failure at its cheapest point; Sweep
  names comprehensive versus goal-directed, without which "complete" is
  unfalsifiable and the question never closes. (fixed)
- r8: the out-of-scope line said "no methodology" while I was adding four
  template sections. Reworded to what is actually true — the sections are
  fields a reader fills, drawn from measured practice; what stays out is
  procedure, source lists, confidence scoring and loop shape. Left as
  written it would have read as contradicting the diff. (fixed)

- r1: the plan's `AGENTS.md` review-churn anchor read MISSING on a grep.
  False alarm — the phrase wraps across lines 54 and 55. Confirmed by
  reading them. Every other anchor in the plan opened and resolved. (no
  change needed)
- r2: `origin/claude/unsupervised-goal` also touches `docs/product/`, but
  only `unsupervised-mode.md`; this branch adds a new file and shares no
  path with it or with any other in-flight branch. Checked every remote ref
  before claiming. (no change needed)
- r3: the requirement's Satisfied-when has to be checkable, per the goal
  bound that merged in #55 — every bullet names an observable state, and
  the terminal one is the existing delete-on-graduated action rather than a
  new kind of done. (fixed while writing)
- r4: docs-only diff, so `verify` is out of scope (step 7 scopes it to
  non-`*.md` files under four paths). `ci` covers the graph lint, which is
  what can break here. (no change needed)

## Blockers

None.

## Where to look

- `docs/product/research-capability.md` — the requirement, including the
  two measured cases from tonight that motivate it.
- `docs/plans/research-node.md` — the node, its edge, and the five things
  deliberately out of scope.
- `.agents/harness/AGENTS.md:54` — the one existing mention of research,
  and the pointer this closes.
- `.agents/docs/graph.md`, Nodes and Edges — the two tables the plan adds a
  row to, and the Rules paragraph that forbids the easy wrong answer.
