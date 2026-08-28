---
workstream: smoke-rerun-safety
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: smoke-rerun-safety
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: Make reruns safe in smoke-test.sh, verify back-to-back green, review, finish
---

## Goal

Plan `docs/plans/smoke-rerun-safety.md`: cleanup deletes the namespace with
`--wait=false`, so an immediate rerun lands in a `Terminating` namespace,
pods cannot schedule, and the suite false-FAILs. Back-to-back runs must both
pass.

## Decisions

- Failure shape already measured this session (PR 91 review, r7): back-to-back
  without `--keep` gives `4 passed, 4 failed` here and `5 passed, 2 failed` on
  the pre-helm script — every post-namespace check dies, not just one.

## Rejected

(pending)

## Review

(pending)

## Blockers

None.

## Where to look

- `.agents/env/k8s/smoke-test.sh:cleanup` — the `--wait=false` delete.
- `.agents/env/k8s/smoke-test.sh:NS` — the one place the name is chosen.
