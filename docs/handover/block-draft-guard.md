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
next: ci rerun after r2–r3 fix, then retire commit, PR, finish, merge
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

- r1: (verifier) a stale `drafted: <N>` carried from an earlier block cycle is trusted (wontfix: git cannot see the draft; the key is the manager's read-back, documented as such in manager-reference.md)
- r2: (verifier) quoted `drafted: "12"` false-fires (fixed)
- r3: (verifier) quoted `status: "blocked"` is never checked (fixed)
- r4: (verifier) `ls-tree` without `-z` skips a non-ASCII workstream path (wontfix: workstream names are kebab ASCII, glossary-enforced stems)
- r5: edge review, own pass over the diff: clean beyond r1–r4 (no change)

## Blockers

None.

## Where to look

- `.agents/harness/handover-guard.sh` — the new fact.
