---
workstream: handover-rot-enforcement
status: in-progress
branch: claude/handover-rot-enforcement-8chuvt
pr: none
session: https://claude.ai/code/session_016Fb42AZrNDN76pKG3gNQCP
updated: 2026-08-21
next: Add workstream-file rot check to joharness.sh ci; graduate keepers from env-harness-split.md, then delete it
---

## Goal

PR #3 merged with its workstream file still in the tree, so
`docs/handover/env-harness-split.md` now sits on `main` — the exact state the
protocol forbids ("No workstream file belongs on `main`"). Only the
session-start hook notices, one session too late. Make `joharness.sh ci`
enforce it: red on `main`, a warning on a pull request so the file gets
deleted before merge, not discovered after. Clean up the file the gap let
through.

## Decisions

- Check lives in `cmd_ci`, not a new subcommand: ci.yml already calls
  `joharness.sh ci` on both PRs and pushes to `main`, so both enforcement
  points come free.
- PR context warns instead of failing: the protocol wants the workstream file
  ON the branch during review (PR body links to it) and deleted in the final
  commit. Failing the PR would fight the protocol's own review flow.

## Rejected

- (none yet)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_ci` — where the check goes.
- `harness/handover-context.sh` — existing rot check (informs, cannot refuse);
  its `files_at` filter (`TEMPLATE.md`, `README.md` excluded) is the shape to
  mirror.
- `docs/handover/env-harness-split.md` — the stale file; its "Measured" 429
  note graduates to `env/k8s/AGENTS.md` trip-wires.
