---
workstream: roles-plain-docs
status: in-progress
branch: claude/roles-plain-docs
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01EyLq7aiPMD1oHLsUeZAb4Z
agent: sonnet
updated: 2026-10-24
next: Write .agents/docs/roles.md, point README and orchestrated.md at it, run ci and verify
---

## Goal

User: "Simplify and update joharness docs. Focus on roles and how they
interact. Use plain human language."

## Decisions

- One new plain-language page, `.agents/docs/roles.md`, for humans: who each
  role is, what it does, how they hand work to each other. Synced to
  consumers, so their humans get it too (README is not synced).
- README "How it works" rewritten around roles in plain words, linking there.
- `orchestrated.md` stays the precise reference; its intro points humans to
  `roles.md`. Rule text in role commands untouched: agents need it exact.
- Plain prose over caveman: the page is for people, and caveman.md itself says
  use plain when caveman is not shorter.

## Rejected

- Rewriting `orchestrated.md` or the role commands in prose: they are the
  operative rules agents execute literally; the fast lane's 3-path bound also
  rules it out.

## Review

## Blockers

None.

## Where to look

- `.agents/docs/orchestrated.md` Roles table — the source of truth roles.md
  must agree with.
