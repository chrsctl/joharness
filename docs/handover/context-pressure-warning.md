---
workstream: context-pressure-warning
status: in-progress
branch: claude/context-pressure-warning-k7q2
pr: none
plan: context-pressure-warning
issue: none
session: https://claude.ai/code/session_01FmArP42iphRwRzXNj4HD4o
agent: opus
updated: 2026-10-23
next: Settle the design question (transcript_path + usage on PreToolUse), then build context-watch.sh
---

## Goal

Warn a long-lived session before compaction takes its rules: once context
crosses a threshold, the next Edit/Write or Bash tool call carries one
injected line telling it to write the workstream file, commit and push.

## Decisions

- (pending) design question: transcript_path on PreToolUse, usage on assistant entries.

## Rejected

None yet.

## Review

None yet.

## Blockers

None.

## Where to look

- `.agents/harness/pretool-feedback.sh:hook_key` — payload key reader, envelope.
- `.agents/harness/pretool-bash-guard.sh` — DENY path must not change.
