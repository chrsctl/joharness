---
workstream: ci-minutes
status: in-progress
branch: claude/ci-minutes
pr: none
plan: ci-billed-minutes
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: sonnet
updated: 2026-08-31
next: Fold verify-declared-layers into lint, run ci, open the pull request
---

## Goal

*"Issue is it uses up all build minutes on gh."* Answer it with the run data
rather than by assuming it, then take the part of the bill that is real.

## Decisions

- **Check the premise first.** `chrsctl/joharness` is public, so its Actions
  minutes are free. Reporting a fix for a bill nobody is paying would have
  been the whole answer wrong. The bill is real in a *private consumer*,
  which is what this repo seeds.
- **Fold the job, do not path-filter it.** A `paths:` filter is
  workflow-level, not job-level; a job-level `if:` needs a changed-files
  computation that costs its own job. The round-up is the cost, so removing
  the second job is the only thing that removes it.
- **`if: always()` on the folded step.** Without it a red lint would hide the
  layer verdict, which is a coverage loss the separate job did not have.
- **Left the `main` push run alone.** Biggest remaining line (~13 runs/day of
  re-verifying an already-passed tree) but `ci.yml` argues for it explicitly
  as the cross-PR collision gate. Reversing that is product direction.

## Rejected

- **Skipping the `main` run when the merge commit's tree equals the pull
  request head's tree.** Precisely targeted — a collision shows up as a
  *different* tree, so the skip would only fire where the PR's verdict
  already covers the bytes. Rejected anyway: it cannot be expressed in a
  job-level `if:` (no tree access before checkout), so it needs a guard step
  inside a job that has already started and already billed its minute. Zero
  saving for real machinery.

## Review

## Blockers

None.

## Where to look

- `.github/workflows/ci.yml` — the two jobs.
- `.agents/scripts/bootstrap-consumer.sh:285` — where this file is seeded
  verbatim into a consumer, and why the bill lands there and not here.
