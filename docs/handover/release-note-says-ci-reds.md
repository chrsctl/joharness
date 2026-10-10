---
workstream: release-note-says-ci-reds
status: in-progress
branch: manage/release-note-says-ci-reds
pr: none
plan: release-note-says-ci-reds
issue: 279
session: https://claude.ai/code/session_01CbngYVEaR7c37YXNzDqLZ7
agent: sonnet
updated: 2026-10-10
next: Record verifier findings in ## Review, retire plan+workstream, open PR, merge
---

## Goal
Plan release-note-says-ci-reds, whole plan.

## Notes
- Unfixed-branch count: 8 (command in plan Acceptance, run 2026-10-10).
- Selftest 0 failed with fix; with janitor_apply reverted, the 2 new assertions FAIL (2400 passed, 2 failed), restored.
- ci: pass. verify: 4 failed, all docker container egress in this sandbox (pull alpine, HTTPS, network, compose) — not this diff; check GitHub run for layer.
- Verifier spawned, result pending.

## Review
- r1: (verifier) lint_enum assertion tautological, grep also matched the new why= literal (fixed: now greps `lint_red .*not one of`)
- r2: (verifier) "quoting the lint wording" duplicated r1 and the reconcile check (fixed: dropped)
- r3: (verifier) `${ROOT:-.}` inconsistent (fixed: `${ROOT}`)
- r4: (verifier) why text paraphrases the lint wording with `...` (wontfix: the note quotes the stable prefix; the r1 assertion guards the lint wording)
