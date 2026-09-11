---
workstream: curator-role
status: in-progress
branch: claude/work-visibility-orchestrator-zvzo62
pr: none
plan: curator-role
issue: none
session: https://claude.ai/code/session_01BrSMgwe9csBqCjehd6v16R
agent: opus
updated: 2026-09-11
next: Build cmd_curate in joharness.sh, then the dispatch cadence, then commands/curate.md; selftest cases first for each
---

## Goal

A periodic role that checks the plan queue: repairs stale declarations,
declutters obsolete plans, and proposes ordering and decomposition. Plan:
`docs/plans/curator-role.md`. Second item on this branch — the first,
`rescope-held-plans`, is pushed and awaiting the human's merge (protocol
text), and both touch the same `cmd_dispatch` region, so a separate branch
would conflict for nothing.

## Decisions

- Name **curator** (`/curate`, `./joharness.sh curate`): verb-command plus
  `-or` role noun, matching the existing vocabulary. Rejected "worker" — a
  worker here is a claimless subagent that dies with its parent's turn, and
  this role needs a branch and a pull request. It is a second KIND of session
  at manager level, like the reporter, holding no slot.
- Requester's two calls, 2026-09-11: REPAIR and DECLUTTER act; ORDER and
  DECOMPOSE only propose. Orchestrator-driven cycle, no Routine.
- `urgency:` is never the curator's — ordering by priority is product
  direction, the stop-and-ask list. It orders by derived facts only and
  proposes the rest.
- Cadence state is derived from GIT, never stored: the last curate is the
  newest base-branch commit deleting a `docs/handover/curate-*.md`. The
  orchestrator's ledger dies with its run; git does not.
- `JOHARNESS_CURATE_HOURS` default 168 (weekly), matching `update.yml`'s sync
  cadence — the only hygiene cadence this repo already has. The number is the
  human's; 0 disables.

## Rejected

- A Routine driver. Would close the idle-queue gap; the requester chose
  orchestrator-driven only, so the gap is recorded in the plan's Goal, not
  closed.
- Letting the curator split plans. Decomposition is the opus-tier judgement
  every build rests on and it MULTIPLIES the queue — one plan into five and a
  session has grown its own backlog, which is the circularity the
  requirement ban exists to stop. It proposes instead.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:lint_nodes` — the whole-queue plan walk to reuse.
- `joharness.sh:dispatch_rescope_branches` — the stateless in-flight scan to copy.
