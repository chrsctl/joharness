---
workstream: role-in-new-session
status: in-progress
branch: claude/role-in-new-session
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01J1YMK6feckvXP4AdjUBvJZ
agent: opus
updated: 2026-10-29
next: Add the one-role-per-session rule to the Loop, orchestrate.md Never and subagents.md Never
---

## Goal

Human, after the gx orchestrator fixed #1010 on main and ran a clerk pass
itself: "Do not allow spawning the role in the same session open in new
session." A session holds one role; work another role owns opens a new
session for that role.

## Decisions

- Rule text only, three places: Loop step 2 (every session reads it),
  `orchestrate.md` Never (the role that broke it), `subagents.md` Never (the
  subagent route around it). No new mechanism: no command can tell which
  role a turn is doing.

## Rejected

- None yet.

## Review

- None yet.

## Blockers

None.

## Where to look

- `.agents/harness/AGENTS.md` Loop step 2 — role routing.
- `.claude/commands/orchestrate.md` `## Never` — "take a queue item yourself".
- `.agents/docs/subagents.md` `## Never` — "Standing in for session fan-out".
