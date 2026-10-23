---
plan: context-pressure-warning
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: none
issue: none
scope: .agents/harness/context-watch.sh, .agents/harness/selftest/context-watch.sh, shared:.agents/harness/selftest.sh, shared:joharness.sh
---

## Goal

A manager is a long-lived session, and nothing tells it that its context is
filling until compaction takes its rules. GSD Core
(github.com/open-gsd/gsd-core, `hooks/gsd-context-monitor.js`) injects a
warning at about 35% context remaining ("wrap up") and again at about 25%
("stop, pause"). Port the idea. Once the session's context crosses a
threshold, the next tool call carries one injected line: write the
workstream file, commit and push now. The handover then exists before
compaction, not after.

## Scope

Re-scoped on the branch (the orchestrator, on the human's delegation): every
registered hook runs from the working tree, so editing one changes the hook on
the building session's own calls, and auto mode refuses that.

- `.agents/harness/context-watch.sh` (new), a standalone PreToolUse hook that
  prints its own `additionalContext` envelope. It reads the payload's
  `transcript_path`, takes the last main-thread assistant `usage` in a
  bounded tail (input + cache read + cache creation tokens), and computes a
  percentage of `JOHARNESS_CONTEXT_WINDOW`. At or above
  `JOHARNESS_CONTEXT_WARN` it prints a WARN line, at or above
  `JOHARNESS_CONTEXT_CRIT` a CRIT line, each at most once per session (a
  marker in the session's scratch directory). Nothing below the warning.
- `joharness.sh` knob table: `JOHARNESS_CONTEXT_WINDOW` (1000000),
  `JOHARNESS_CONTEXT_WARN` (65), `JOHARNESS_CONTEXT_CRIT` (80), scope
  `session`; 0 switches a level off.
- `.agents/harness/selftest/context-watch.sh` (new topic), registered in
  `.agents/harness/selftest.sh`.
- Registration: one PreToolUse entry in `.claude/settings.json` (matcher
  `Edit|Write|NotebookEdit|Bash`), a core edit, in a
  `human/context-pressure-warning` pull request labelled `human-review`. The
  human's merge is when it first runs live.

## Out of scope

- Any edit, wrapper or probe of `pretool-feedback.sh`,
  `pretool-bash-guard.sh`, `handover-guard.sh` or the session-start path.
- A live-payload probe: `transcript_path` is a documented common hook input,
  and its absence prints nothing.
- Writing or pushing the handover itself. Blocking a tool call.

## Acceptance

- `./joharness.sh ci`: `ci: pass`, and the selftest prints the new topic's
  cases, including: 70% gives one WARN and a second call nothing; 85% gives
  CRIT once; a missing, unreadable or malformed transcript gives no output
  and exit 0.
- `./joharness.sh verify`: 0 failed.
- `./joharness.sh conf` lists the three knobs with their defaults.

## Where to look

- `.agents/harness/pretool-feedback.sh:hook_key` — reads one key from the payload without a JSON parser; the envelope it prints is the injection channel.
- `.agents/harness/pretool-bash-guard.sh` — header: fails open; the hook reader this one copies.
- `.agents/docs/handover/README.md` — section "Compaction: task state survives, the rules decay".
- `joharness.sh:num_knob` — how a numeric knob is read.

## Traps

- The hook runs before EVERY matching tool call in every consumer repo. A
  crash, a slow read or a deny on confusion is worse than no hook: fail
  open, and read only the transcript's tail (bounded `tail -c`), never the
  whole file.
- A test for the once-per-session marker must FAIL without the marker.
- Never `pgrep -f` a pattern your own command line carries. The selftest
  measures files, not processes.
