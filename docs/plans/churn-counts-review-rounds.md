---
plan: churn-counts-review-rounds
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: joharness.sh, .agents/docs/agent-selection.md, .agents/docs/orchestrated.md, .agents/harness/selftest/ci-churn.sh
---

## Goal

The review-churn rule (stop patching, take the research step) almost never
fires. `ci` measures churn as commits per file, but managers batch a
round's fixes into one commit. In gx since 2026-10-10:

- 208 of 338 workstreams reached review round r8 or later, and 75 reached
  r20 or later (max r58, pm-cycle-next).
- The research step was taken about 17 times.
- 17 review lines record a fix that undid an earlier fix. Example:
  crm-graphql-mentions-and-backlinks r10, "r4 undid the bin's rule".

Count review rounds too, and treat a line that says a fix undid a fix as
the signal the rule describes.

## Scope

- `joharness.sh:ci_churn` — keep the file measure. Add a second measure:
  the highest `rN` in this branch's own workstream files' `## Review`
  (`fin_own_ws`, `lint_review_bullets`).
  - Warning at `JOHARNESS_ROUNDS_THRESHOLD` (default 12).
  - Red at `JOHARNESS_ROUNDS_LIMIT` (default `computed` = twice the
    threshold; 0 lifts it).
  - The stage verdict is the worse of the two measures.
  - Separately, a warning (never red) for any Review bullet whose text
    matches, case-insensitively, `undid`, `undoes`, `reverts r`,
    `broke r` or `breaks r[0-9]`. It names the research step.
- `joharness.sh` knob table (beside `JOHARNESS_CHURN_LIMIT`) — declare the
  two new knobs with the same columns.
- `.agents/docs/agent-selection.md` § Review churn — the paragraph on what
  `ci` prints gains the round measure and the undid-line warning.
- `.agents/docs/orchestrated.md` — wherever the churn defaults are listed
  (§ The numbers are the human's), add the two new defaults.
- `.agents/harness/selftest/ci-churn.sh` — add cases:
  - r11 is quiet;
  - r12 warns;
  - r24 is red;
  - `JOHARNESS_ROUNDS_LIMIT=0` lifts the red;
  - an `undid` line warns and is not red.

## Assumptions

- A1: churn counts only commits per file — evidence:
  `joharness.sh:churn_top`, `.agents/docs/agent-selection.md` (`== churn`
  paragraph) — confidence: high.
- A2: the gx round counts above — evidence: deleted
  `docs/handover/*.md` recovered from gx history, max `rN` per stem,
  2026-10-29 — confidence: medium (keyword classification; the counts of
  rounds are exact, the 17 undid-lines approximate).
- A3: knobs are declared in one table that a selftest checks — evidence:
  `.agents/harness/selftest/knobs-declared.sh` — confidence: high.

## Out of scope

- Changing what the research step is, or who takes it.
- Counting plan-checker rounds. Plan files carry no `## Review`.
- Auto-escalating the agent tier. Money is the human's call.

## Acceptance

- `bash .agents/harness/selftest.sh ci-churn` — every case passes.
- `bash .agents/harness/selftest.sh knobs-declared` — passes.
- `./joharness.sh ci` — `ci: pass`; `== churn` prints both measures.
- `./joharness.sh verify` — 0 failed.

## Where to look

- `joharness.sh:ci_churn`, `joharness.sh:churn_top` — today's measure.
- `joharness.sh:num_knob` — how a `computed` default resolves.
- `joharness.sh:lint_review_bullets`, `joharness.sh:fin_own_ws` — the
  Review reader and the own-files list.
- `.agents/docs/agent-selection.md` — § Review churn.

## Traps

- The numbers are the human's (`orchestrated.md`): ship the defaults this
  plan names. Do not tune them to make a case pass.
- A test for a fix must FAIL without it.
- `local-check-required` also edits `joharness.sh` and reads the same
  Review bullets: reconcile, and reuse one helper if both land.
