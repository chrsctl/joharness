---
plan: context-pressure-warning
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: none
issue: none
scope: .agents/harness/context-watch.sh, .agents/harness/pretool-feedback.sh, .agents/harness/pretool-bash-guard.sh, .agents/harness/selftest/context-watch.sh, shared:.agents/harness/selftest.sh, shared:joharness.sh
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

- `.agents/harness/context-watch.sh` (new). It reads the hook payload's
  `transcript_path` and takes the most recent assistant `usage` entry
  (input + cache read + cache creation tokens). It computes a percentage
  of `JOHARNESS_CONTEXT_WINDOW`. At or above `JOHARNESS_CONTEXT_WARN`
  percent it prints a WARN line, and at or above `JOHARNESS_CONTEXT_CRIT`
  it prints a CRIT line. Each level fires at most once per session,
  tracked by a marker under the session's tmp area, the same way
  pretool-feedback.sh keeps its once-per-file state. Prints nothing below
  the warning level.
- `.agents/harness/pretool-feedback.sh` and
  `.agents/harness/pretool-bash-guard.sh`: call context-watch.sh, and on
  any output merge its line into the `additionalContext` envelope these
  hooks already emit, or emit one. They are already registered for
  Edit|Write|NotebookEdit and Bash in `.claude/settings.json`, so no core
  path changes.
- `joharness.sh` knob table: `JOHARNESS_CONTEXT_WINDOW` (default 1000000),
  `JOHARNESS_CONTEXT_WARN` (65), `JOHARNESS_CONTEXT_CRIT` (80), scope
  `session`. Setting either percentage to 0 switches that level off.
- `.agents/harness/selftest/context-watch.sh` (new topic), registered in
  `.agents/harness/selftest.sh`.

## Out of scope

- Any edit to `.claude/settings.json` (a core path), including a
  statusLine or a PostToolUse/PreCompact registration. The point of riding
  the two registered hooks is to need none of these.
- Writing or pushing the handover itself. The hook only says to; the
  session acts on it.
- Blocking a tool call. This hook only warns, never denies.

## Acceptance

- First, settle the design question and record it in `## Decisions`. Use a
  live hook payload to check that `transcript_path` is present on
  PreToolUse in this runtime and that the transcript carries `usage` on
  assistant entries. If either is absent, block with
  `design: <what is missing>` and build nothing.
- `./joharness.sh ci` — `ci: pass`, and the selftest prints the new topic's
  cases, including:
  - a transcript fixture at 70% gives one WARN, and a second call gives
    nothing;
  - at 85% it gives CRIT once;
  - a missing, unreadable or malformed transcript gives no output and
    exit 0;
  - the bash guard still exits 2 on an unbounded wait, with its reason on
    stderr unchanged, even when the context is over the threshold.
- `./joharness.sh verify` — 0 failed.
- `./joharness.sh conf` lists the three knobs with their defaults.

## Where to look

- `.agents/harness/pretool-feedback.sh:hook_key` — reads one key from the payload without a JSON parser; the envelope it prints is the injection channel.
- `.agents/harness/pretool-bash-guard.sh` — header: fails open, DENY = exit 2 on stderr, parse-guarded registration.
- `.agents/docs/handover/README.md` — section "Compaction: task state survives, the rules decay".
- `joharness.sh:num_knob` — how a numeric knob is read.

## Traps

- Both hooks run before EVERY matching tool call in every consumer repo. A
  crash, a slow read or a deny on confusion is worse than no hook: fail
  open, and read only the transcript's tail (bounded `tail -c`), never the
  whole file.
- The bash guard's DENY path must not change. Adding output to its
  allow path is the only edit there.
- A test for the once-per-session marker must FAIL without the marker.
- Never `pgrep -f` a pattern your own command line carries. The selftest
  measures files, not processes.
