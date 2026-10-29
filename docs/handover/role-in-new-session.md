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
next: Run ci, verify, finish; open the PR and merge it
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

- A mechanism (`role <name>` refusing inside an orchestrator session): no
  command can tell which role a turn plays; follow-up candidate, not this lane.

## Review

- r1: rule is prose only; gx broke a rule that already said spawn, ref § Role sessions, (wontfix: no command can see the session's role; mechanism is a follow-up plan)
- r2: (verifier) spawn prompt named the workstream file beyond tier, branch, base, stem (no change: one aside, prompt discipline noted)
- r3: (verifier) "never a subagent of another role's session" forbade a manager's workers and the verifier (fixed in subagents.md)
- r4: (verifier) Loop line listed "a fix" as another role's work, forbidding a builder's own review fix (fixed in .agents/harness/AGENTS.md)
- r5: (verifier) workstream `next:` named finished work (fixed in docs/handover/role-in-new-session.md)
- r6: (verifier) no acceptance check for the Goal (wontfix: same as r1)
- r7: (verifier) `agent: opus` vs haiku review tier (no change: fast lane reviews at haiku whatever `agent:` says)

## Blockers

None.

## Where to look

- `.agents/harness/AGENTS.md` Loop step 2 — role routing.
- `.claude/commands/orchestrate.md` `## Never` — "take a queue item yourself".
- `.agents/docs/subagents.md` `## Never` — "Standing in for session fan-out".
