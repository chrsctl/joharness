---
plan: requirement-deleted-under-open-plans
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: shared:joharness.sh, .agents/harness/selftest/ci-graph-lint.sh, shared:.agents/harness/selftest/dispatch-curate.sh, .agents/docs/product.md
---

## Goal

"Satisfied = last plan's PR deletes the requirement file" (`product.md`), but
`ci` lets ANY branch delete a requirement while other open plans still name
it, as long as their `serves:` reads `all` or is absent. On chrsctl/gx every
`reeve-fit-*` plan names a requirement already gone from `main`; `ci` only
warns ("gone from tree") and plan-checkers flag it again on every pass.
`curate`'s DECLUTTER stays silent because it only speaks when ONE plan names
the gone requirement. Catch it where it is made, and name the stragglers.

## Scope

- `joharness.sh:lint_req_deleted` — red when the branch deletes
  `docs/product/<r>.md` while a plan in HEAD's `docs/plans/` (not deleted by
  this diff) still names `requirement: <r>`. Message: `<rel>: deleted while
  open plan(s) <a>, <b> name it — retire or re-point them in this pull
  request (.agents/docs/product.md)`. Shallow history = no change (the
  check reads HEAD and the merge base only).
- `joharness.sh` DECLUTTER in `curate` (the `plans_for -le 1` block): when
  `plans_for` > 1, print one line per requirement: `requirement '<r>' is gone
  and <n> plans still name it: <stems> — satisfied or retired? re-point their
  requirement: lines`. Keep the single-plan delete proposal as is.
- `.agents/harness/selftest/ci-graph-lint.sh` — case: delete a requirement
  that a remaining plan (`serves: all`) names → red; delete it together with
  its only plan → green.
- `.agents/harness/selftest/dispatch-curate.sh` — the two-peer case
  (`peer_a`, `peer_b`) now expects the new multi-plan line; the existing
  refutes stay.
- `.agents/docs/product.md` — Clauses, **Deletion** bullet: one sentence
  stating the new red.

## Assumptions

- A1: the dangling warn is in `lint_plans` ("gone from tree — satisfied
  while this plan is open?") and stays a warn for plans already dangling on
  `main` — evidence: `joharness.sh:lint_existed` call site — confidence: high
- A2: `lint_serves_of` already walks the plans naming a requirement and can
  be reused or mirrored — evidence: `joharness.sh:lint_serves_of` —
  confidence: medium
- A3: DECLUTTER's `<= 1` guard was added on purpose (verifier r5 in
  `dispatch-curate.sh`) so peers are not each offered for DELETION; a
  re-point line is not a deletion proposal — confidence: high

## Out of scope

- Editing chrsctl/gx's plans: that is the consumer's own cleanup after sync.
- Turning the existing "gone from tree" warn red: it would red every
  consumer already carrying a dangling plan on its next sync.
- Dispatch rows for dangling plans.

## Acceptance

- `./joharness.sh ci` — `ci: pass`; the new ci-graph-lint case FAILS on
  `origin/main` without the change.
- `./joharness.sh verify` — `0 failed`.

## Where to look

- `joharness.sh:lint_req_deleted` — the deletion check.
- `joharness.sh:lint_serves_of` — plans naming a requirement.
- `joharness.sh:n_declutter` — curate's DECLUTTER block.
- `.agents/harness/selftest/dispatch-curate.sh:peer_a` — the peer cases.

## Traps

- NEVER skip, disable or quarantine a test to get green.
- Shares `joharness.sh` with `retired-edge-stall-window` and
  `stranded-branch-plans`: reconcile, do not overwrite.
