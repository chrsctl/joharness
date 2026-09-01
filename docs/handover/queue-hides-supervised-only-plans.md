---
workstream: queue-hides-supervised-only-plans
status: in-progress
branch: claude/current-state-review-oxfb7f
pr: none
plan: queue-hides-supervised-only-plans
issue: none
session: https://claude.ai/code/session_011LSGxqQsZyuMYSqxa3jVT5
agent: opus
updated: 2026-09-01
next: Implement the SUPERVISED ONLY mark in queue-context.sh, then teach drain to read it
---

## Goal

The endurance retry of 2026-08-31 spent 55 minutes and $12.05 on
`marker-gate-needs-no-done`, a plan whose whole declared scope is protocol
text — which the unsupervised-mode Constraints forbid an unattended session
to commit. The session did everything right and could not finish. The queue
offered it as the top free item, and the disqualifying fact was in the
plan's own `scope:` frontmatter the whole time. Mark such a plan and stop
offering it to an unsupervised fleet.

## Decisions

- **Mode-gated, both the mark and the de-rank.** The plan's Acceptance says
  a supervised session sees the plan unchanged, and `queue-context.sh`
  already states the rule for itself: every mode-dependent line sits inside
  a branch `qc_mode` guards, so supervised output stays byte-identical.
  Supervised also pays zero extra forks, which keeps the perf row honest.
- **The protocol list comes from `joharness.sh protocol-paths`, one fork per
  hook run, not per plan.** Second copy is what issue #114 cost. Same call
  shape `handover-guard.sh` already uses.
- **Comparison is git pathspec semantics**, matching how the guard compares
  the same list: an entry is protocol when it equals a protocol path or sits
  under one at a slash boundary. `joharness.shX` therefore does not match
  `joharness.sh` — a Trap the plan names.
- **Classification is pure bash, no forks per plan.** A `tr`/`sed`/`grep`
  pipeline per plan is the fork-in-a-loop regression the perf budget exists
  to catch, in the file whose budget is tightest.
- **`scope:` is read in the row loop's existing `fields` call.** That call
  already reads six keys in one pass; a seventh costs nothing, and the rank
  is computed there.
- **De-rank is +2, the weight `claimed` carries** — listed, never leading.
  Not +4 (blocked): nothing is blocking it, and a supervised session should
  still see it as takeable work.
- **A plan with no `scope:` is UNKNOWN and is not marked SUPERVISED ONLY**,
  because guessing scope is out of the plan's scope. It gets its own
  unsupervised-only label instead, so absence is not silently read as clean.
- **`drain` reads the hook's answer, never re-derives it.** `drain_plan`
  filters the same string the hook prints, and `cmd_drain` names the
  supervised-only plans before deferring to the sweep — otherwise "queue
  empty" would print over a plan that is sitting right there, which is the
  DRAINED-over-a-requirement defect PR 157 fixed.

## Rejected

- **Marking in supervised mode too.** Reads as a useful warning; breaks the
  Acceptance line that says a supervised session cannot tell the feature
  shipped, and buys nothing — a supervised session may legitimately take the
  plan.
- **Blocking the session from taking it.** Explicitly out of scope: this
  marks and de-ranks, it does not forbid.

## Review

Pending — depth is `./joharness.sh review` for this branch, plus a verifier
that did not write the diff.

## Blockers

None.

## Where to look

- `.agents/harness/queue-context.sh` — the row loop computes rank and label;
  `qc_mode` guards every mode-dependent line.
- `joharness.sh:protocol_paths` — the one list. `protocol-paths` is the
  subcommand.
- `joharness.sh:drain_plan` — the filter that keeps claimed and blocked rows
  out of `next:`.
