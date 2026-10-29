---
workstream: scout-issue-ownership
status: in-progress
branch: claude/scout-issue-ownership
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01J1YMK7Zb1rr3yFQJLNX8RP
agent: sonnet
updated: 2026-10-29
next: Edit .claude/commands/scout.md for the three fixes, then ci, verify, review, finish
---

## Goal

A review of the last scout runs (chrsctl/gx, 2026-10-29, gx#1060) found three
defects in `.claude/commands/scout.md`. The reviewer said "Fix all".

1. The GitHub MCP issue tool strips the attribution footer from issue bodies
   (comments keep it). The YOURS rule asks for a body ending in `cost:` line
   then footer, so no filed proposal is ever the scout's own: §4 can never
   revise it.
2. The `Feature` type set at filing did not stick on gx#1060 and the claim's
   review record said it was set. The report must state the type read back.
3. The scout's verifier prompt told the verifier what to check, against
   `.agents/docs/subagents.md` "What a stranger's spawn prompt carries".

## Decisions

## Review
