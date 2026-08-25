---
requirement: research-capability
priority: normal
---

## Goal

The harness can execute work it has been given and cannot find out anything
it does not already know. The protocol mentions research three times and
gives it a shape in none of them: the review-churn rule sends a session to
"a research step at raised tier or effort"
(`.agents/harness/AGENTS.md`), `agent-selection.md` repeats that step, and
`subagents.md` lists "Research sweeps — read many files, return the
conclusion only" as work a subagent may be handed. The harness knows
research is an activity and has never said what it produces or where the
product goes. So research happens, produces real findings, and evaporates:
the session that did it merges a plan whose prose happens to carry a trace,
and the next session starts from nothing.

Measured on 2026-08-25, in this repo, in one evening: a mechanism
comparison across six candidates for running the fleet unattended settled a
claim that `docs/plans/unsupervised-fanout.md` had already shipped and got
wrong; the comparison itself lives outside git and is not reachable from
any node. `unsupervised-sources` dropped two of five work sources because
neither had a detector — a question nobody can file, so nobody will answer
it. Both are research the repo paid for and did not keep.

Give research the same standing as a plan: something the queue can hand to
any session, whose answer is measured rather than argued, and which
graduates into the rules and docs it settles.

## Satisfied when

- A session can file a question the repo needs answered, as a file the
  queue lists beside plans, without inventing a shape for it.
- A research file states one answerable question and what would settle it.
  A question no evidence could close is not one, and the shape says so.
- An answer carries the commands it was measured with and their output, so
  the next reader re-runs them and sees the same thing or does not. Prose
  that cannot be re-run is not an answer.
- A plan resting on an unmeasured assumption can point at the research that
  settles it, and the queue shows a plan blocked on an open question the
  same way it shows one blocked on a plan.
- An answer is checked from a context other than the one that produced it,
  and the file records who checked and from where. Self-graded research is
  the failure both the harness's diamond rule and every external practice
  surveyed name first.
- Reaching an answer graduates it — into the layer's `AGENTS.md` or
  `docs/` — and deletes the research file, the same terminal action every
  other node in the graph already uses.
- The review-churn rule's "research step" points at this shape instead of
  leaving the session to improvise one.
- `./joharness.sh ci` lints research nodes and their edges as it already
  lints plans and requirements.

## Constraints

- No new state store, no auto-extraction, no embeddings
  (`.agents/docs/graph.md`, Rules). Research is a file node with
  delete-on-graduated, derived at read time like everything else. A
  research index that has to be maintained is the second copy that rule
  forbids.
- Counted numbers or it is not an answer. The repo's standing rule is trust
  counted numbers, never written numbers, and research is exactly where a
  written number gets minted.
- A research file is not a plan and may not carry implementation. It settles
  a question; a plan acts on the settlement. Blurring the two turns every
  disagreement into a branch.
- Sessions may file questions. Only the human writes requirements, so a
  research node can never become an authorization to build something
  nobody asked for.
- The harness stays caveman: this adds one node type and one edge, not a
  methodology. If it cannot be stated in the existing tables, it is too big.
