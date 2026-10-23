---
workstream: refusal-is-not-credentials
status: in-progress
branch: refusal-is-not-credentials
pr: none
plan: refusal-is-not-credentials
issue: none
session: https://claude.ai/code/session_01GCgdvphDZPwKLGLRQsdZxt
agent: sonnet
updated: 2026-10-23
next: Build the plan as rewritten on this branch: one hooks bullet in manage.md §2, one sentence in orchestrated.md, pins
---

## Goal

Write down the safe way to build hook work. A registered hook runs from the
working tree on the session's own calls, so never edit one. Build a new
hook unregistered, test it through fixtures, and register it in the
`human/<stem>` pull request.

## Decisions

- The orchestrator rewrote the plan on this branch to this scope, on the
  human's delegation (2026-10-23). The earlier scope and its history are in
  git log on this branch. Build from the plan file as it now reads.

## Review

- r1: (verifier) clean pass: no defects; pins fail on origin/main, ci pass, verify 6 passed 0 failed (2026-10-23) (no change)

## Blockers

None.

## Where to look

- `.claude/commands/manage.md:## 2` — the `human/<stem>` pull request.
