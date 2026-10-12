---
workstream: plans-role-usage-review
status: in-progress
branch: plans-role-usage-review
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01PhFHAaBX1c6NWtFEfwo3hd
agent: opus
updated: 2026-10-12
next: Write one plan per issue #424-#429, run ci, open the plan-only PR
---

## Goal

Human asked: review the role usage of the current orchestrator run
(session_01LRrvSrFRZExrbQotmHKxQA, 2026-10-12), file issues, convert them to plans.

## Decisions

- Plans written directly by this session (precedent: #418's plan PR), not
  through a clerk: a clerk (clerk-2026-10-12) is in flight on #251, and the
  human asked for plans now. Each plan carries `issue:` so no clerk replans it.
- orchestrate.md and clerk.md are touched by several plans: marked `shared:`.
