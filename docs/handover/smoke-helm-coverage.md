---
workstream: smoke-helm-coverage
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: smoke-helm-coverage
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: Add helm check to smoke-test.sh, move written counts, verify, review, finish
---

## Goal

Plan `docs/plans/smoke-helm-coverage.md`: environment installs helm, smoke
suite never exercises it — only manual checks ever did (2026-08-21). Close
the gap so the suite covers every tool the environment installs.

## Decisions

- Session runs opus, plan wants sonnet: escalation, allowed. Review depth
  follows the SESSION tier — adversarial, separate lenses
  (`.agents/docs/agent-selection.md`).
- Branch restarts from origin/main again (PR #90 merged).

## Rejected

- Public chart repo (bitnami etc.): plan's Out of scope — egress allowlist
  has no chart repos, adds network flake to a deterministic suite.

## Review

(pending)

## Blockers

None.

## Where to look

- `.agents/env/k8s/smoke-test.sh` — header check list, PASS/FAIL counters,
  summary line, cleanup trap.
- `.agents/env/k8s/AGENTS.md` — written pass total moves with the count.
