---
workstream: scout-approval-by-comment
status: in-progress
branch: manage/scout-approval-by-comment
pr: none
plan: scout-approval-by-comment
issue: 461
session: https://claude.ai/code/session_017cwAYs3qgKcSgStGZVWrDU
agent: opus
updated: 2026-10-13
next: Run selftest revert check, ci, verify, verifier review, then retire and PR
---

## Goal

Scout proposals are approved by the reviewer's `approved` comment, read with
`issue_read get_comments`, not by the `approved` label event from the timeline
(#459, #461 item 2).

## Decisions

- Gate length: `awk '/^THE SCOUT GATE/,/^Then the AUTHOR GATE/' .claude/commands/clerk.md | wc -l` = 24 (2026-10-13; 46 on main).
- Unreadable comments skip that proposal only (`APPROVAL UNREADABLE: <error>`): the read is per issue, so one failure says nothing about the next.
- `scout: answer` also opens `scout:`, so it stales an approval too; accepted as fail-closed rather than adding an exception.
- Scout §5 recovery: a newest own `scout: revised` whose target text is not in the body yet = make that edit next pass (the comment already stated it, so an approval after it covered that text).
- `orchestrated.md` lines on the gx #645 run stay: they record history, not the rule.

## Rejected

- None yet.

## Review

- r0: placeholder until review runs (no change)

## Blockers

None.

## Where to look

- `.claude/commands/clerk.md` — THE SCOUT GATE.
