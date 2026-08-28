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
when the model asks (`./joharness.sh feedback <path>`, Loop step 4) or
in the `review` printout. Stage 4 of the loop — Prevent, the only stage
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
  ONLY — never Read, never Bash. Path with recorded findings: emit the
  findings. No findings, any error, any unexpected input: silent
  exit 0.
- Emit through the JSON envelope, NOT plain stdout. PreToolUse feeds the
  model only via `hookSpecificOutput.additionalContext`; plain stdout is
  transcript-only, so a hook that prints looks right in the transcript
  and reaches nothing. (SessionStart's plain-stdout precedent in this
  repo is the trap — a different event with a different contract.)
  Verify against the installed Claude Code build before writing the
  emitter, and pin the check in selftest.
- `joharness.sh` — quiet shape for `cmd_feedback <path>`, REQUIRED, not
  optional: today a path with nothing recorded still prints a header
  plus `no merged edge recorded a finding whose fix touched this file`
  (measured `./joharness.sh feedback docs/nope-nothing-here.md`,
  2026-08-28). Piped raw, the hook injects that banner before every
  edit. Quiet shape = no header, no output at all when there is nothing
  to say, exit 0. Reuse the `fb_` machinery, duplicate nothing.
- Dedup + cache in session scratch, keyed by a SANITIZED `session_id`
  (strip to `[A-Za-z0-9_-]`, refuse anything else — an id straight from
  hook JSON into a path is a traversal): one injection per file per
  session, and the `fb_collect` walk cached once per session. The cache
  is load-bearing, not an optimization: `./joharness.sh feedback <path>`
  measured 3802 / 3942 / 3783 ms over three runs in a remote container,
  2026-08-28, at 61 edges with 50 read. Uncached, that is a ~4s stall
  before every Edit and Write. Scratch dies with the container; nothing
  under the repo.
- `.claude/settings.json` — register the PreToolUse hook. Note this
  file is in the sync `FILES` list: registering here ships the hook to
  every consumer, where it fires on every edit against that repo's own
  merged history. Intended (stage 4 has to reach consumers) — but the
  ~4s figure above is why the cache lands in the same PR as the hook,
  never after.
- `.agents/harness/selftest.sh` — cases: garbage stdin exits 0 silent;
  Read event emits nothing; second event, same file same session, emits
  nothing; a path with no recorded findings emits nothing; emission uses
  the `additionalContext` envelope; hook registered in settings.json.

## Out of scope

- Env-layer md injection at PreToolUse — rejected pending a measured
  miss (workstream base-review-adaptions, Rejected).
- PostToolUse nudges, UserPromptSubmit injection, depletion-aware
  re-serving — separate questions, not filed.
- Any stored findings index in the repo — graph.md forbids; scratch
  cache only.
- Blocking or gating any tool call. This hook informs, never denies.
- Sync registration. `.agents/harness` ships to consumers as a whole
  DIRS tree (`.agents/scripts/sync-to-consumer.sh`) — a new file there
  needs no entry, and editing that script is not this plan's work.

## Acceptance

- `printf '{"session_id":"s1","tool_name":"Edit","tool_input":{"file_path":"<path feedback reports findings for>"}}' | .agents/harness/pretool-feedback.sh`
  — emits that path's findings inside an `additionalContext` envelope.
  Same command again — no output, exit 0.
- Same event with `"tool_name":"Read"` — no output, exit 0.
- `printf 'garbage' | .agents/harness/pretool-feedback.sh` — no output,
  exit 0.
- Event for a path `feedback` knows nothing about — no output, exit 0.
- Event whose `session_id` carries `../` — no write outside the scratch
  dir; hook still exits 0.
- Second invocation for the same session does not re-walk history
  (measure both: first call vs second, same command as the Scope figure).
- `./joharness.sh ci` — pass.
- `./joharness.sh verify` — 0 failed.

## Where to look

- `joharness.sh:cmd_feedback` — the per-path report this serves, and
  where the quiet shape lands.
- `joharness.sh:fb_collect` — one history walk, globals, the cost the
  cache answers.
- `.agents/harness/handover-guard.sh` — stdin handling and fail-open
  doctrine to copy exactly.
- `.claude/settings.json` — existing SessionStart + Stop registration.
- `.agents/scripts/sync-to-consumer.sh` — `DIRS` / `FILES` lists; read
  to confirm no registration is owed, not to edit.

## Traps

- Hook NEVER blocks a session: any failure = exit 0, no output
  (handover-guard doctrine). A harness that wedges tool calls is worse
  than no harness.
- Plain stdout on PreToolUse reaches the transcript, not the model. A
  hook that "works" when eyeballed and injects nothing is the default
  failure here.
- No repo state: dedup and cache are session scratch, never committed
  (graph.md Rules — derived state = second copy, rots).
- `.agents/harness/` names no environment layer (Part 2 carve-out rule).
- Hook output is paid on every fire: caveman, findings only, no banner.
- Never fire on Read — inject before production, not consumption; a
  per-Read injection is noise the dedup cannot save.
- This plan touches the repo's two hottest files: `./joharness.sh
  feedback` on 2026-08-28 ranked `.agents/harness/selftest.sh` at 19
  edges and `joharness.sh` at 16. Run `./joharness.sh feedback <path>`
  on both before editing either — recount, do not trust these numbers.
