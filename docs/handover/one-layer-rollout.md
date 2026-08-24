---
workstream: one-layer-rollout
status: in-progress
branch: claude/celluloid3-update-occ76a
pr: 45
plan: none
session: https://claude.ai/code/session_01JoK1BRUuDsQ2VR9zbJMKHD
agent: opus
updated: 2026-08-24
next: Merge PR 45 when green, sync celluloid3 from main, then open its git rm -r cleanup PR
---

## Goal

Fallout from PR 43 (one layer per consumer, merged). Dropping docker, k8s
and none from celluloid3 turned its `ci` red: `.agents/harness/selftest.sh`
copies `.agents/env/k8s/setup.sh`, so the always-on layer reaches into one
environment — the coupling `.agents/env/README.md` forbids. Invisible while
every consumer carried every layer.

## Decisions

- The case stays, guarded. A hostile cluster name executing when the env
  file is sourced is worth a git-only regression test, and a layer's own
  `smoke-test.sh` needs the sandbox this cannot assume. Skips where the
  layer is absent; the comment names the smell so the next reader does not
  treat it as a pattern.
- celluloid3's cleanup waits for this to merge and sync. Deleting its
  unused layers first would leave its CI red on a canonical bug.

## Rejected

- Moving the case into `.agents/env/k8s/`. The layer contract has one test
  hook, `smoke-test.sh`, and it runs only in a provisioned sandbox — a
  git-only regression test would stop running on GitHub entirely.
- Dropping the case with the layers. It guards a shell injection.

## Review

## Blockers

None. PR 45 waiting on CI.

## Where to look

- `.agents/harness/selftest.sh` — the `.agents/env/k8s/setup.sh env-file
  quoting` step; the guard is the `[ ! -f ... ]` branch above it.
- celluloid3 `claude/drop-unused-layers` — local branch, `git rm -r` of
  docker/k8s/none already staged, not pushed until PR 45 lands.
