---
plan: reading-budget-always-loaded
urgency: normal
agent: haiku
effort: medium
needs: none
requirement: none
issue: none
scope: .agents/harness/selftest/reading-budget.sh
---

## Goal

Our style rule (`.agents/docs/caveman.md`) says every line of the files
that load into every session costs every session, but only four files
have a byte bound. GSD Core caps every agent prompt with a per-file
ratchet (`tests/agent-size-budget.test.cjs`). Bound the rest of ours, so
that growth is a decision made in a commit and not drift.

## Scope

- `.agents/harness/selftest/reading-budget.sh`: add `rb_bound` lines for
  the following files, each counted with `wc -c` on this branch at build
  time:
  - `.agents/harness/AGENTS.md`
  - the root `AGENTS.md`
  - `.claude/agents/verifier.md`
  - `.claude/commands/clerk.md`
  - `.claude/commands/scout.md`
  - `.claude/commands/keeper.md`
  - `.claude/commands/conduct.md`
  - `.claude/commands/curate.md`
  - `.claude/commands/upstream-report.md`

  Each bound gets a one-line comment above it naming the count and the
  date, as the existing entries have.

## Out of scope

- Shrinking any file. This plan only freezes sizes.
- A commit-trailer override. The file's header already says how a bound
  rises (move text out, or name the rule that must live there, in the
  commit).
- `manage.md` and `orchestrate.md`, which are already bounded.

## Acceptance

- `grep -c '^rb_bound' .agents/harness/selftest/reading-budget.sh` — 13.
- `./joharness.sh ci -v | grep -c 'bytes, bound'` — 13 or more, all pass lines.
- `./joharness.sh ci` — `ci: pass`.

## Where to look

- `.agents/harness/selftest/reading-budget.sh:rb_bound` — the helper and its third argument (base dir).

## Traps

- Count on the build commit, never copy a number from this plan or from
  memory: "Trust counted numbers, never written ones".
- Plans `verifier-goal-lens` (verifier.md) and `fast-lane` (AGENTS.md)
  grow files this plan bounds. If one merged first, count after it. If
  this one merged first, they raise the bound in their own commit and say
  why.
