---
workstream: compact-reorient
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: compact-reorient
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: Settle the hook contract from evidence, then wire the compact-source path
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
- OPEN until the documentation answer lands: whether the SessionStart stdin
  payload names the source in a field this hook can read, and whether
  `compact` is among its values, versus needing a separate `PreCompact`
  event. Recorded here rather than assumed; the plan is explicit that a plan
  which guessed here shipped a hook nobody proved fires.

## Rejected

(pending)

## Review

(pending)

## Blockers

None.

## Where to look

- `.agents/harness/handover-guard.sh:39` — the working hook-stdin idiom to reuse.
- `joharness.sh:cmd_session_start` — prints the environment banner before
  delegating; a compact-time run must not reprint a provisioning banner.
- `.agents/harness/handover-context.sh` header — "never fails a session".
