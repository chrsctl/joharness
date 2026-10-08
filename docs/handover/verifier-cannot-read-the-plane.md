---
workstream: verifier-cannot-read-the-plane
status: in-progress
branch: claude/verifier-cannot-read-the-plane
pr: none
plan: verifier-cannot-read-the-plane
issue: none
session: https://claude.ai/code/session_01JXryjCKHhwkN7Xrv1qXz55
agent: sonnet
updated: 2026-10-08
next: Add the outside-this-checkout limit to verifier.md and research README Verification, assert both in review.sh.
---

## Goal

Issue #267, option 1 only: the verifier has Read, Grep, Glob, Bash and no control-plane call, so a claim resting on a reading outside this checkout is one it can only check for internal consistency. Say so in verifier.md, have research nodes name their second context up front in Method, and pin both with one shared literal. Supervised-only plan, supervised session at the human's /drain, 2026-10-08.

## Decisions

- The shared literal is `outside this checkout`, the phrase the plan's
  Scope already uses. `review.sh` pins it against `verifier.md`, then looks
  up in the research README exactly what the first match held — needle
  first, and an empty first match is its own failure, never a pass.
- The verifier MARKS an unreachable claim UNVERIFIED and still reports it:
  arithmetic checked, repository checked for contradiction, the untaken
  reading named. Its tools are unchanged (the plan puts widening them out of
  scope, as the human's call).
- The new assertions carry the same canonical-only guard as the existence
  check beside them: a consumer receives these files and does not own them.

## Rejected

## Review

- r1: (session) proved by `./joharness.sh mutate .claude/agents/verifier.md
  67 ...`, the boundary line reworded, 2026-10-08: baseline green, 2 cases
  red — the boundary assertion and the cross-file comparison, both positive.
  The tool restored the line itself. `ci: pass`, 2300 passed, 0 failed.
  (fixed)

## Blockers
