---
workstream: compact-reorient
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: compact-reorient
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: Adversarial review, then finish
---

## Goal

Plan `docs/plans/compact-reorient.md`: three moments change what a session
knows; the harness hooks session start and turn end. Compaction is the third
and is unhooked — and the only one the session does not choose. It fires
mid-work and takes the orientation Loop step 1 established, leaving a session
still on a claimed branch, still editing, no longer holding the workstream
file it read at minute zero.

## Decisions

- The plan's open question is which event to hang this on, answered by
  evidence rather than guess. Evidence gathered BEFORE writing either line:
  see Hook contract below.

## Hook contract (the plan's acceptance asks for this explicitly)

- PROVEN, from this repo: Claude Code delivers JSON on a hook's stdin, and a
  harness hook already consumes it. `.agents/harness/handover-guard.sh:39`
  reads `input="$(cat 2>/dev/null || true)"` and branches on
  `stop_hook_active` from that payload. So the stdin channel is not a
  hypothesis here; only the SessionStart field names are.
- PROVEN, from this session's own transcript: this client fires SessionStart
  with a distinguishable source. The transcript carries both
  `SessionStart:startup hook success` and `SessionStart:resume hook success`
  for the same registered hook, so the client both re-fires the event and
  labels which kind of start it was.
- SETTLED from the Claude Code hook documentation: `SessionStart` delivers a
  `source` field whose values are `startup`, `resume`, `clear`, `compact`,
  `fork`, and its stdout reaches the model on exit 0. `PreCompact` exists but
  its stdout does NOT reach the model — it goes to the debug log — so a
  re-orientation message hung there would be written for nobody. Hence
  SessionStart, and hence NO new event and no `.claude/settings.json` change:
  the registered entry carries no matcher, so it already fires for every
  source including `compact`. The plan's scope said "one more hook entry",
  written before the question was answered; its own conditional ("if
  SessionStart already fires with source=compact, the fix belongs there and
  no new event is needed") is the branch the evidence took.
- Documented-versus-inferred, kept apart because the plan asks for it: the
  `source` values, the matcher syntax and SessionStart stdout reaching the
  model are documented guarantees; "PreCompact stdout is discarded" is
  inferred from its omission from the list of events whose stdout is
  injected, not from a sentence saying so.

## Rejected

- `PreCompact`. It fires at the right moment but its stdout never reaches the
  model, so the message would exist only in a debug log.
- A second `SessionStart` entry with `matcher: "compact"`. The existing entry
  has no matcher and so already fires on every source; adding a matched one
  would run BOTH on compaction and print the state twice. Branching inside
  the command keeps one output and matches the plan's "same git facts,
  different lead line".
- Reading stdin with a plain `cat`, the idiom the Stop guard uses. Correct
  there, wrong here: `cat` blocks until stdin closes, and a human running
  `./joharness.sh session-start` by hand has a terminal nobody closes — the
  hook meant to orient sessions would have hung them. Caught by a selftest
  run that never finished. Now bounded and skipped entirely for a TTY.

## Review

(pending)

## Blockers

None.

## Where to look

- `.agents/harness/handover-guard.sh:39` — the working hook-stdin idiom to reuse.
- `joharness.sh:cmd_session_start` — prints the environment banner before
  delegating; a compact-time run must not reprint a provisioning banner.
- `.agents/harness/handover-context.sh` header — "never fails a session".
