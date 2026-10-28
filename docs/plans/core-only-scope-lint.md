---
plan: core-only-scope-lint
urgency: normal
agent: sonnet
effort: high
needs: core-only-spawns-manager
requirement: none
serves: all
issue: none
scope: shared:joharness.sh, .agents/harness/selftest/curate-apply.sh, .claude/commands/clerk.md, shared:.agents/docs/plans.md
---

## Goal

`core-only-spawns-manager` made a `CORE ONLY` plan spawnable: a manager
builds the core edit in a `human/<stem>` pull request and a human only
merges it. `ci` still refuses an ADDED plan whose `scope:` is core paths
only ("no session may build it; mark the issue for a human instead"), and
the clerk never writes one (verdict HUMAN). So a core-only issue still waits
on a human to implement it, which is what the requester wanted gone: *"We
should only wait for the PRs to be merged not the implementation."*

## Scope

- `joharness.sh:lint_plans_in_diff` — drop the `plan_core_only` refusal;
  drop `plan_core_only` if nothing else reads it.
- `.agents/harness/selftest/curate-apply.sh` — the `coreonly` case asserts
  `ci` passes the plan (`refute "names core paths only"`), and fails without
  the change.
- `.claude/commands/clerk.md` — HOLDS: a core-paths-only plan is written like
  any other; it is not a HUMAN verdict on that ground alone.
- `.agents/docs/plans.md` ("A core path in `scope:`") — drop "`scope:` of
  core paths ONLY is red in `ci`".

## Assumptions

- A1: Nothing but `lint_plans_in_diff` reads `plan_core_only` — evidence:
  `grep -n plan_core_only joharness.sh` — confidence: high
- A2: A core-only plan's manager can retire on its own branch while its
  `human/` pull request carries only the core edit — evidence:
  `.agents/docs/manage-reference.md` § Human remainder — confidence: medium

## Out of scope

- The queue hook's `CORE ONLY` marking and dispatch's spawn row: done by
  `core-only-spawns-manager`.
- Letting any session merge a core-path pull request.

## Acceptance

- `bash .agents/harness/selftest.sh` — `0 failed`; the `coreonly` case in
  `curate-apply.sh` passes and fails with the refusal restored.
- `./joharness.sh ci` — `ci: pass`; `./joharness.sh verify` — `0 failed`.

## Where to look

- `joharness.sh:lint_plans_in_diff` — the refusal.
- `.claude/commands/clerk.md` — HOLDS verdict, "core paths only".

## Traps

- The gate stays: CODEOWNERS and the `human-review` label, never a session's
  merge of a core-path pull request.
