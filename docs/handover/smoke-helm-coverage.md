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
- Real install over `--dry-run` (plan allowed either): renders, rolls out to
  Ready, uninstalls — proves the release lifecycle, not just templating.
  `image.tag=alpine` reuses the image check 6 already pulled, so the check
  measures helm and not the registry twice.
- Check proven to fail, not just pass: same script with a bad image tag
  reports FAIL, `7 passed, 1 failed`, exit 1, and prints `STATUS: failed`.
- Best-effort `helm uninstall --ignore-not-found` before install: after a
  `--keep` run the release survives, and "name in use" would be this check
  failing for the previous run's success. Matches the `|| true` re-run
  idiom the namespace and deployment steps already use.
- SCOPE EXTENSION, decided alone, flagged for human: seven OTHER plan files
  wrote `verify — 7 passed, 0 failed` as acceptance for unrelated work. This
  branch moves that count, so each would have shipped stale. Rewritten
  count-neutral ("all checks pass, 0 failed") — same requirement, immune to
  the next count change. Intent preserved, no plan's meaning altered. This
  is the PR85 r4 failure (a moved count orphaning another plan's bullet)
  caught before merge rather than after.

## Rejected

- Public chart repo (bitnami etc.): plan's Out of scope — egress allowlist
  has no chart repos, adds network flake to a deterministic suite.
- Rewriting the cold-verify story's `7/7` to `8/8` in env AGENTS.md: that is
  a past measurement, not a current total. Falsifying it to match today's
  count is worse than the confusion it fixes; marked "the suite was 7 checks
  then" instead.
- Fixing the suite's re-run brittleness generally: measured on origin/main's
  own script (3 checks fail on a re-run over a kept namespace), so it is
  pre-existing and belongs to plan `smoke-rerun-safety`, not this diff.

## Review

(pending)

## Blockers

None.

## Where to look

- `.agents/env/k8s/smoke-test.sh` — header check list, PASS/FAIL counters,
  summary line, cleanup trap.
- `.agents/env/k8s/AGENTS.md` — written pass total moves with the count.
