---
plan: branch-plan-spawn-bound
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: shared:.claude/commands/orchestrate.md, shared:.claude/commands/manage.md, docs/handover/branch-plan-spawn-bound.md
---

## Goal

`.agents/docs/orchestrated.md`, "A plan the queue cannot see", settles how a
plan on an unmerged branch reaches the queue (issue #297). It states a bound
the acting roles do not carry: when the human orders a spawn on a row of
dispatch's `plans on a branch` block, the manager carries the plan to its own
branch and never pushes to the owner's. `.claude/commands/orchestrate.md`
("Report, every pass") offers that spawn with no bound; `manage.md` says
nothing about it. Put the bound where the roles read it.

## Scope

- `.claude/commands/orchestrate.md`, "Report, every pass": the spawn the
  human orders names the row's branch and stem in the manager prompt, and
  points at the orchestrated.md section.
- `.claude/commands/manage.md`: prompt names a plan on another branch →
  cut own branch from `main`, copy that plan file only, push nothing to the
  owner's branch, build as usual. PR body names the owner branch and says
  its later merge re-adds the retired plan unless the owner drops it at
  reconcile (measured, orchestrated.md).

Acceptance: `./joharness.sh ci` prints `ci: pass`; `git grep -n
"branch-plan-spawn-bound\|carry the plan" .claude/commands` shows both files.

## Out of scope

- Any `joharness.sh` change: no guard for a resurrected plan, no row for an
  abandoned branch's plan (both accepted gaps in orchestrated.md; a guard is
  its own plan if a run pays for one).
- Letting the orchestrator spawn on a branch plan without the human.

## Where to look

- `.agents/docs/orchestrated.md` — "A plan the queue cannot see".
- `.claude/commands/orchestrate.md` — "Report, every pass".
- `.claude/commands/manage.md` — step 0.2, "Prompt names a branch".
