---
plan: planning-review-bound
urgency: urgent
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: joharness.sh, .agents/harness/selftest/review.sh, .agents/docs/manager-reference.md, .agents/docs/agent-selection.md, .agents/docs/orchestrated.md
---

## Goal

A planning pass (a manager decomposing an unplanned requirement into plan
files, no code) cost $108-191 a pass on chrsctl/gx on 2026-11-12/13, four
passes, ~$619 at list price, 94% of it at the fable rate. The cost is
review: 16 plan-checker runs on one branch, 11 verifier passes on another,
237 findings recorded on one, every reviewer at fable, and the churn
gate cannot stop it (it skips `docs/plans|handover|product`). The human
(money decision, `agent-selection.md`) chose: cap the rounds, and run a
planning pass's reviewers at opus.

## Scope

- `joharness.sh` — `review_report`: a workstream whose `plan:` names a
  requirement (`docs/product/<stem>.md`, no `docs/plans/<stem>.md`) is a
  planning pass; a fable tier there prints opus, and the line names the
  round bound.
- `.agents/harness/selftest/review.sh` — cases: planning pass at fable
  reads opus with the bound; a fable plan's build stays fable.
- `joharness.sh` KNOBS — `JOHARNESS_PLANNING_REVIEW_ROUNDS`, default 25
  (the human's number), 0 = no cap; `.agents/docs/orchestrated.md` table row.
- `.agents/docs/manager-reference.md` § Challenge — the cap: at most that
  many review rounds a pass (plan-checker spawns and verifier passes
  together), on top of the per-plan 3 rounds and churn stop; an open
  finding on a plan becomes a low-confidence `A<n>` in that plan, any other
  goes to the PR body. Reviewers at opus.
- `.agents/docs/agent-selection.md` — Review depth: the planning-pass
  exception, citing the human's decision.

## Assumptions

- A1: a planning workstream's `plan:` is the requirement stem and no plan
  file of that stem exists — evidence: gx `manager/invoicing-app` workstream
  `plan: invoicing-app`, `agent: fable`; verifier reports "docs/plans/
  invoicing-app.md exists at neither sha" — confidence: high

## Out of scope

- Reviewer report length cap and excluding the `## Review` record from
  review (offered, not chosen).
- Counting `docs/plans` in the churn gate: the bound replaces it.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- New selftest cases fail with the `review_report` change reverted.
- Consumer side, after sync: on a planning branch (`plan:` a requirement
  with no plan of its stem on the base, `agent: fable`), `./joharness.sh
  review` prints `[opus` and `at most 25 review rounds`
  (`./joharness.sh review | grep -c 'at most 25 review rounds'` → 1).

## Where to look

- `joharness.sh:review_report`, `review_tier`
- `.agents/docs/manager-reference.md` § Challenge
- `.agents/docs/agent-selection.md` § Review depth
