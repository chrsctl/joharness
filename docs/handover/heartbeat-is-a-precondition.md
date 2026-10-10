---
workstream: heartbeat-is-a-precondition
status: in-progress
branch: claude/heartbeat-is-a-precondition
pr: none
plan: heartbeat-is-a-precondition
issue: none
session: https://claude.ai/code/session_017wdZSYpjKWnZwmXDVRzDq7
agent: sonnet
updated: 2026-10-10
next: Read orchestrate.md step 0, section 4, orchestrated.md Heartbeat; make the three edits
---

## Goal

Plan heartbeat-is-a-precondition: orchestrate.md names the heartbeat as the durability mechanism, adds the frozen-but-RUNNING branch.

## Decisions

- Plan says protocol text is core/supervised-only. Checked: `protocol-paths` lists only joharness.conf, .claude/settings.json, .github; unsupervised.md Bounds says protocol text is NOT core since 2026-10-08. Proceed.

## Rejected

## Review

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` step 0, section 4
- `.agents/docs/orchestrated.md` Heartbeat
