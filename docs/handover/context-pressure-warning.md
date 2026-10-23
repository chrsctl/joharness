---
workstream: context-pressure-warning
status: blocked
branch: claude/context-pressure-warning-k7q2
pr: none
plan: context-pressure-warning
issue: none
session: https://claude.ai/code/session_01FmArP42iphRwRzXNj4HD4o
agent: opus
updated: 2026-10-23
next: credentials: the auto-mode classifier denies this item as Self-Modification (it edits hooks that run on the session's own tool calls); will a human allow it, or run it in a session with that permission?
---

## Goal

Warn a long-lived session before compaction takes its rules: once context
crosses a threshold, the next Edit/Write or Bash tool call carries one
injected line telling it to write the workstream file, commit and push.

## Decisions

- Design question, half settled. `usage` on assistant entries: CONFIRMED
  live, this session's transcript, 2026-10-23: `input_tokens`,
  `cache_creation_input_tokens`, `cache_read_input_tokens` present; nested
  `output_tokens_details:{...}` follows, so read each key alone, not
  `"usage":{[^}]*}`. `transcript_path` on PreToolUse: documented as a common
  hook input field, NOT captured live — the probe (tee stdin in the
  working-tree pretool-feedback.sh, then one Edit) was refused, see Blockers.
- Bash guard: its header says NO FORKS per call. Plan to call
  context-watch.sh only on the allow path (EXIT trap on status 0, so a
  denied call never burns the once-per-session marker), and only when the
  payload carries `transcript_path` and a level is still unfired (builtin
  `[ -e ]` checks). Measure the cost before merging.

## Rejected

None yet.

## Review

None yet.

## Blockers

- Claude Code auto mode refused, as [Self-Modification], first the live
  payload probe, then plain reads (`sed`, `grep` of joharness.sh and the
  selftests). This item edits PreToolUse hooks that run on the session's own
  tool calls, so the classifier blocks it whole. Unblock: a human allows it
  (a Bash permission rule, or a session not in auto mode), or builds it. No
  code was written; the tree holds only this file.

## Where to look

- `.agents/harness/pretool-feedback.sh:hook_key` — payload key reader, envelope.
- `.agents/harness/pretool-bash-guard.sh` — DENY path must not change.
