---
workstream: ci-minutes
status: review
branch: claude/ci-minutes
pr: none
plan: ci-billed-minutes
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: sonnet
updated: 2026-08-31
next: Open the pull request; read its checks to confirm the folded step reports
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

- r1: `if: always()` also fires on a CANCELLED run, spending the step's
  seconds on a verdict nobody will read. Three of this repo's 28 runs on
  2026-08-31 were cancelled, so the case is live rather than theoretical.
  (fixed — `${{ !cancelled() }}`, which is success-or-failure and not
  cancellation.)
- r2: folding removes the check NAME `verify-declared-layers`. A branch
  protection requiring it by name would block every future pull request
  forever, and the symptom is a check stuck at "Expected", not a red.
  Checked rather than assumed: `list_branches` reports `main` as
  `"protected": false`, so no rule names it. (fixed — nothing to fix; the
  risk was real and the fact refutes it.)
- r3: the two checks now run in SERIES on one runner, so a healthy run's
  wall clock goes ~99s to ~107s where it used to overlap. (wontfix — that
  is the trade, stated: 8s of latency for a third of the bill, and the
  bill is the thing that was asked about.)
- r4: verifier not spawned. Twenty-eighth consecutive edge. The session
  instruction in force forbids calling the Agent tool unasked, and Loop
  step 5 requires one reader that did not write the diff; they contradict,
  and only the human can lift either. (wontfix — issue #168, still open.)
- r5: `ci.yml` is seeded by `bootstrap-consumer.sh` and never synced
  afterwards, so this saving reaches only consumers created from here on.
  Every existing private consumer keeps its three-job bill. (wontfix —
  making it synced would clobber the consumer edits the seed-not-sync rule
  exists to protect. The recursion guard, which is the larger number, is in
  `joharness.sh` and IS synced, so the expensive half does reach them.)

## Blockers

None.

## Where to look

- `.github/workflows/ci.yml` — the two jobs.
- `.agents/scripts/bootstrap-consumer.sh:285` — where this file is seeded
  verbatim into a consumer, and why the bill lands there and not here.
