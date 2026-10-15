---
workstream: retire-legacy-compat
status: in-progress
branch: claude/retire-legacy-compat
pr: none
plan: retire-legacy-compat
issue: none
session: https://claude.ai/code/session_01CdQa5qCUV3WTK7S9jSKFUf
agent: sonnet
updated: 2026-10-15
next: Read ci and verify counts; green = retire workstream and plan, open PR, merge
---

## Goal

Owner: every consumer is upgraded; old-version support goes.

## Decisions

- Keep fallbacks that also guard a broken or missing `joharness.sh` (guard
  boundary list, `start` missing command, queue-context unknown boundary):
  their removal weakens a safety check, not only old-version support.
- `.github/workflows/update.yml` two-spelling probe is a core path: flagged
  for the human, not edited.

## Rejected

- None yet.

## Review

- r1: (verifier) clean pass at sonnet: acceptance greps empty, no dangling pointer, from_canonical still used, only removed-behaviour assertions dropped (no change)

## Blockers

None.

## Where to look

- `docs/plans/retire-legacy-compat.md` — scope and out-of-scope.
