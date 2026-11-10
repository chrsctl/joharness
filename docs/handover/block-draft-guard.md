---
workstream: block-draft-guard
status: in-progress
branch: claude/block-restore-pr-draft-check
pr: none
plan: block-draft-guard
issue: none
session: https://claude.ai/code/session_01J1YMK5qoGtaMQ4abBpkEjB
agent: sonnet
updated: 2026-11-10
next: Wait for selftest, then ci, verify, verifier, PR
---

## Goal

chrsctl/gx PR #1437 merged a restored workstream file onto main because the
manager blocked without drafting the PR. Make that step mechanical.

## Decisions

- Stop guard, not `ci`/`finish`: the human merged on red; only the draft
  stops a human, and only the blocking session can draft. The guard fires
  in that session, git-only.
- New key `drafted:`, not a suffix on `pr:`: `pr_num` readers parse `pr:`.

## Rejected

- `dispatch` warning: the orchestrator does not draft; arrives after the exit.

## Review

## Blockers

None.

## Where to look

- `.agents/harness/handover-guard.sh` — the new fact.
