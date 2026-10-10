---
workstream: requirement-row-claim
status: in-progress
branch: requirement-row-claim
pr: none
plan: requirement-row-claim
issue: none
session: https://claude.ai/code/session_01KGbgAo5HRoJy1hGBGbRy34
agent: opus
updated: 2026-10-10
next: Record verifier findings in ## Review, fix, then retire + PR
---

## Goal

A pushed workstream file whose `plan:` names a requirement stem must be a
claim on that requirement — in-flight row, slot counted, not offered
UNPLANNED, blocked = held not respawned.

## Decisions

- Claimed requirement stays printed under "Requirements without plans" with
  `claimed on <branch>` (ranked after unclaimed) — dispatch's in-flight walk
  builds rows from that label; `drain_requirement` skips claimed lines and
  the free walk skips every `docs/product/` row (unclaimed ones are offered
  by `drain_requirement` alone).
- Plan/research stem wins over a requirement stem in queue-context too, not
  only in joharness.sh's `for cand` loops: one resolution order everywhere.
- `manage.md` untouched: its "`plan:` names the item" already says it.

## Rejected

- None yet.

## Review

- r1: revert test — `git checkout origin/main -- joharness.sh .agents/harness/queue-context.sh` in a worktree, `bash .agents/harness/selftest.sh` → 2458 passed, 7 failed (the five claim cases, the lint claim case, the reworded dead-claim message); restored → 2465 passed, 0 failed. Tests pin the fix. (no change)

## Blockers

None. `./joharness.sh verify` local run 2026-10-10: 2 passed, 4 failed —
every fail a docker registry/egress check; `docker pull alpine:3` returns
`429 Too Many Requests` from registry-1.docker.io. Diff touches no
`.agents/env/` file; step 7 needs the PR head's CI verify job read instead.

## Where to look

- `docs/plans/requirement-row-claim.md` — Scope lists every site.
