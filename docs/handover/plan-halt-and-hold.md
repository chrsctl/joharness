---
workstream: plan-halt-and-hold
status: in-progress
branch: claude/plan-halt-and-hold
pr: none
plan: halt-and-hold
issue: none
session: https://claude.ai/code/session_016VB32myigsC5a7gT5th1gL
agent: fable
updated: 2026-10-24
next: Run plan-checker on both plans and the verifier on the diff; record findings; retire; pull request; merge
---

## Goal

Planning pass for `docs/product/halt-and-hold.md`: decompose the requirement
(halt a live claim on a human's order; hold an unplanned requirement behind
other work without a slot) into plans. Plans only, no implementation.

## Decisions

- Two plans, one per gap, no `needs:` edge between them: `halt-claim`
  (opus, xhigh: a new leased writer onto a branch the session does not own,
  Part 2 territory) and `hold-requirement` (sonnet, high: hook rows, a lint
  arm, a dispatch line). Both declare `shared:joharness.sh`: disjoint
  functions, a routine reconcile.
- Halt reuses `status: abandoned`. Measured: the hook drops an `abandoned`
  claim from `claimed on` (`queue-context.sh`, awk `$3 != "abandoned"`),
  dispatch then has no in-flight row and no slot, `dispatch_freeable` and
  `dispatch_branch_plans` hide the branch, the orchestrator drops a branch
  dispatch stops listing. A new word would touch every `status:` reader
  for no measured gain; the halt is told apart in git by its commit subject
  and `next:` text.
- An edge branch (retired record, open pull request) is halted by
  restoring its own retired record with the word: `dispatch_retired_edges`
  skips any branch whose diff against the base adds a workstream file, so
  the slot goes and the claim reads released.
- Hold = two optional requirement fields: `needs:` (deferred behind an
  item; clears without an edit when the file is gone) and `hold:` (a
  human's reason; clears by edit). Resolution across plans, research and
  requirements in the claim order. The reason never enters a hook label
  (forged-claim rule, verifier r6 in the hook); dispatch prints it from the
  base on a `withheld` line.
- Requirement clause checks against code: janitor gates are in
  `janitor_candidates` (age `HANDOVER_STALE_SECONDS`, `pr:`, status) and
  `cmd_guard`'s janitor-only `pr:` arm — confirmed; requirement frontmatter
  reads `priority` only (`queue-context.sh`, `lint_graph`) — confirmed;
  `drain_requirement` is the one offering reader — confirmed.

## Rejected

- `janitor --apply --halt <branch>`: overloads the sweep whose rules the
  requirement says must stay for claims nobody halted; a separate command
  keeps the age gate and the `pr:` refusal untouched and readable.
- A `priority: held` value or `needs: human`: `priority` is an enum two
  readers red on; `needs: human` reds `lint_graph` as a stem that never
  existed. Two fields, two meanings.
- A plan's `needs:` reaching requirements: not asked, and the plan edge
  stays plan to plan.

## Review

One bullet per finding, written BEFORE its fix, committed WITH it, in exactly
the form `- rN: text (fixed|wontfix: why|no change)` — `ci` checks it. Tag the
verifier's findings `(verifier)`. Clean pass = one bullet saying so. Remove
this paragraph when you add the first bullet.

## Blockers

None.

## Where to look

- `docs/product/halt-and-hold.md` — the requirement.
- `docs/plans/halt-claim.md`, `docs/plans/hold-requirement.md` — the plans.
- `joharness.sh:janitor_apply` — the leased write halt copies.
- `joharness.sh:drain_requirement` — the one reader that offers a requirement.
