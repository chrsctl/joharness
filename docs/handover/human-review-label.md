---
workstream: human-review-label
status: in-progress
branch: human-review-label
pr: none
plan: human-review-label
issue: none
session: https://claude.ai/code/session_016i8T8r7viQifvrmJ2g2rbz
agent: sonnet
updated: 2026-10-12
next: Record review, retire plan and workstream files, open PR, merge
---

## Goal

Label `human-review` marks an issue or PR as waiting on a human; only a human removes it.

## Decisions

- Small doc edits, done directly by the manager, no workers.

## Review

- r1: (verifier) clerk Never line comma/semicolon tangle (no change: carve-outs read clearly; sentence kept)
- r2: (verifier) manage.md path split across a line (fixed)
- r3: (verifier) manage.md finish rule lacked how to read labels (fixed: names `pull_request_read` `get`)
- r4: (verifier) AGENTS.md Block bullet lacked "if set" for issue (fixed)
- r5: (verifier) other findings minor/style (no change)

## Blockers

None.

## Where to look

- `docs/plans/human-review-label.md`
