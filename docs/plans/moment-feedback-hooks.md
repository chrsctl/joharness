---
plan: moment-feedback-hooks
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: .agents/harness/, .claude/settings.json, joharness.sh
---

## Goal

joharness detects and records review findings, then serves them only
when model asks (`./joharness.sh feedback <path>`, Loop step 4) or in
the `review` printout. Stage 4 of the loop — Prevent, the only stage
that changes an outcome (`.agents/docs/feedback.md`) — rides on model
discipline. Close that: a PreToolUse hook injects a file's recorded
findings the moment a tool is about to edit it, no ask needed. Mechanism
adapted from basemode (github.com/ChristopherKahler/base, reviewed at
22e8b8c) pre-tool triggers + once-per-session dedup. Pattern only, no
code — basemode is PolyForm Noncommercial licensed.

## Scope

- `.agents/harness/pretool-feedback.sh` — new PreToolUse hook. Reads
  hook JSON on stdin; extracts `tool_name`, `tool_input.file_path`,
  `session_id` by grep/sed, one key each, no JSON parser
  (handover-guard.sh precedent). Fires on Edit, Write, NotebookEdit
  ONLY — never Read, never Bash. Path with recorded findings: print
  `feedback <path>` report to stdout. No findings, any error, any
  unexpected input: silent exit 0.
- Dedup + cache in session scratch, keyed by `session_id` (for example
  `${TMPDIR:-/tmp}/joharness-pretool-<session_id>/`): one injection per
  file per session; `fb_collect` result cached once per session so a
  per-tool-call hook never re-walks merged history (walk "costs a couple
  of seconds" — `joharness.sh:fb_collect` comment). Scratch dies with
  container. Nothing under the repo.
- `.claude/settings.json` — register the PreToolUse hook.
- `joharness.sh` — only if `cmd_feedback` needs a quiet shape for hook
  use (no header, empty = no output, exit 0). Reuse `fb_` machinery,
  duplicate nothing.
- `.agents/harness/selftest.sh` — cases: garbage stdin exits 0 silent;
  Read event prints nothing; second event same file same session prints
  nothing; hook file registered in settings.json.
- Sync: register the new file wherever harness files reach consumers
  (`.agents/scripts/sync-to-consumer.sh`).

## Out of scope

- Env-layer md injection at PreToolUse — rejected pending a measured
  miss (workstream base-review-adaptions, Rejected).
- PostToolUse nudges, UserPromptSubmit injection, depletion-aware
  re-serving — separate questions, not filed.
- Any stored findings index in the repo — graph.md forbids; scratch
  cache only.
- Blocking or gating any tool call. This hook informs, never denies.

## Acceptance

- `printf '{"session_id":"s1","tool_name":"Edit","tool_input":{"file_path":"<path feedback reports findings for>"}}' | .agents/harness/pretool-feedback.sh`
  — prints that path's findings. Same command again — no output, exit 0.
- Same event with `"tool_name":"Read"` — no output, exit 0.
- `printf 'garbage' | .agents/harness/pretool-feedback.sh` — no output,
  exit 0.
- Event for a path `feedback` knows nothing about — no output, exit 0.
- `./joharness.sh ci` — pass.
- `./joharness.sh verify` — 0 failed.

## Where to look

- `joharness.sh:cmd_feedback` — the per-path report this serves.
- `joharness.sh:fb_collect` — one history walk, globals, cost comment.
- `.agents/harness/handover-guard.sh` — stdin handling and fail-open
  doctrine to copy exactly.
- `.claude/settings.json` — existing SessionStart + Stop registration.
- `.agents/scripts/sync-to-consumer.sh` — consumer reach.

## Traps

- Hook NEVER blocks a session: any failure = exit 0, no output
  (handover-guard doctrine). A harness that wedges tool calls is worse
  than no harness.
- No repo state: dedup and cache are session scratch, never committed
  (graph.md Rules — derived state = second copy, rots).
- `.agents/harness/` names no environment layer (Part 2 carve-out rule).
- Hook output is paid on every fire: caveman, findings only, no banner.
- Never fire on Read — inject before production, not consumption; a
  per-Read injection is noise the dedup cannot save.
