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
next: Decided by the orchestrator on the human's delegation: re-scope (see Decisions, re-scope) so no edit touches a live hook; then build
---

## Goal

Warn a long-lived session before compaction takes its rules: once context
crosses a threshold, the next Edit/Write or Bash tool call carries one
injected line telling it to write the workstream file, commit and push.

## Decisions

- Re-scope, decided by the orchestrator on the human's delegation
  (2026-10-23). Every hook in `.claude/settings.json` runs straight from
  the working tree (`$CLAUDE_PROJECT_DIR/...`), so editing
  `pretool-feedback.sh` or `pretool-bash-guard.sh`, even a probe, changes
  the hook running on this session's own calls. That edit is what auto mode
  refused. New shape:
  1. `context-watch.sh` is a standalone hook script that prints its own
     PreToolUse `additionalContext` envelope. Nothing registers it while
     you build it, so it never runs on your own calls. Test it only through
     the selftest, by piping fixture payloads and transcripts to it.
  2. Never write, wrap or probe `pretool-feedback.sh`,
     `pretool-bash-guard.sh`, `handover-guard.sh` or the session-start
     path. The plan's edits to the two pretool hooks are dropped, and so is
     its bash-guard case. The knob rows in `joharness.sh` stay, since
     ordinary branches edit that file.
  3. The live-payload probe is dropped. `transcript_path` is a documented
     common hook input. A payload without it, or a transcript with no
     usage, prints nothing and exits 0, and a fixture case pins that.
  4. Registration is a core edit. Add one PreToolUse entry to
     `.claude/settings.json` (matcher `Edit|Write|NotebookEdit|Bash`,
     command `"$CLAUDE_PROJECT_DIR"/.agents/harness/context-watch.sh || exit 0`,
     a short `timeout`). It goes in a `human/context-pressure-warning` pull
     request labelled `human-review`, per manage.md §2. The human merges
     it, and that merge is when it first runs live.
  Rewrite the plan's Scope, Out of scope and Acceptance on this branch to
  match, and flag the re-scope in the pull request body.
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

- Editing the two registered pretool hooks to call the watcher: they run on
  the building session's own calls, so auto mode refuses the edit.

## Review

None yet.

## Blockers

None. Auto mode refused the live-hook probe and edit as Self-Modification.
The re-scope in Decisions removes every edit to a live hook. If it refuses
again on the new shape, block with `credentials:` and quote the refusal.

## Where to look

- `.agents/harness/pretool-feedback.sh:hook_key` — payload key reader, envelope.
- `.agents/harness/pretool-bash-guard.sh` — DENY path must not change.
