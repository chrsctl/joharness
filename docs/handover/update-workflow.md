---
workstream: update-workflow
status: in-progress
branch: claude/joharness-update-workflow-ckjg86
pr: none
plan: none
session: https://claude.ai/code/session_01RLj1xhpyfb2CVx3J7yPtpM
agent: sonnet
updated: 2026-08-23
next: open the PR; delete this file in its final state
---

## Goal

Human ask: "Add update workflow for joharness." Consumers keep harness
copies current by running `scripts/sync-to-consumer.sh` by hand — automate
it: GitHub Actions workflow in each consumer that clones canonical, runs
the sync, opens a pull request with the result. Sibling branch on
`chrsctl/redocted` receives the consumer copy.

## Decisions

- Consumer-own file, same delivery as `ci.yml`: seeded by
  `bootstrap-consumer.sh`, never in sync's FILES list. Reason: the
  canonical pointer (`CANONICAL_REPO`) and cadence are per-consumer edits;
  a synced file would flag every such edit AHEAD forever.
- File lives in canonical's `.github/workflows/` so bootstrap can seed it
  verbatim; a guard step reads `JOHARNESS_CANONICAL=1` and no-ops there,
  so canonical's own weekly run stays green and pointless-red-free.
- Sync exit 2 (AHEAD) proceeds to commit + PR: updates were applied,
  nothing clobbered; warning rides the sync log (stderr merged) into the
  PR body. Any other nonzero fails the job before commit. AHEAD with a
  clean tree (drift is the ONLY finding) fails the run instead — a green
  "current" there would bury the drift forever.
- Review round (high) applied 5 findings: PAT push de-fanged by
  checkout's persisted http.extraheader (unset it); sync warnings on
  stderr missing from PR body (2>&1); AHEAD-only silent green (red run);
  stale PR body after force-push (gh pr edit); guard comment overclaimed
  what the engine refuses (engine checks its ROOT, not DEST — guard is
  the only defense).
- Canonical cloned full-history into `$RUNNER_TEMP`, outside the
  workspace: shallow reads honest copies AHEAD (sync header), and a clone
  inside the workspace would be swept up by `git add -A`.
- Bot branch `joharness-update`, rebuilt and force-pushed each run, one
  open PR reused. Sync commit carries no workstream file, per protocol.
- Optional `JOHARNESS_UPDATE_TOKEN` secret: private canonical clone + CI
  triggering on the update PR (plain GITHUB_TOKEN gets neither).
- Drive-by fix, one character: selftest "ceiling turns churn into a hard
  stop" expected `hot-file.txt`, fixture creates `hot file.txt` (space is
  the point of that fixture). Pre-existing red on `main` since PR #26;
  ci must be green to land this branch, so fixed here.

## Rejected

- Adding `update.yml` to sync's FILES list instead of seeding: consumer
  edits (fork canonical, cadence) would read AHEAD on every later sync —
  permanent warning noise for a legitimate per-repo setting.
- `actions/checkout` for the canonical clone: it only checks out under
  `GITHUB_WORKSPACE`, which puts the clone where `git add -A` grabs it.
  Plain `git clone` to `$RUNNER_TEMP` instead.
- Marketplace PR action (peter-evans/create-pull-request): repo style is
  stock `actions/checkout` only; `gh` on the runner does the job without a
  third-party pin.

## Blockers

None.

## Where to look

- `.github/workflows/update.yml` — the workflow; guard, sync, PR steps.
- `scripts/bootstrap-consumer.sh` — seeds it beside ci.yml.
- `harness/selftest.sh` — bootstrap block: BOOT-UPDATE-STUB seed expects.
- redocted branch `claude/joharness-update-workflow-ckjg86` — consumer
  copy, verbatim (no workstream file there: copy task, diff
  self-describing).
