---
workstream: compact-carries-the-rules
status: in-progress
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: compact-carries-the-rules
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Read both compact branches and cmd_session_start before writing a line.
---

## Goal

At compaction the task state survives and the rules decay. The compact branch
of `handover-context.sh` restores the workstream file — the half that already
survives — and says nothing about the Loop, the boundary or the mode. The hook
is the channel re-injected fresh, so the hook carries them.

## Decisions

- This session was itself compacted, and the hook's compact output is in its
  own transcript: it named the branch, the workstream file and "the
  orientation is gone", and named no rule. First-hand confirmation of the
  gap, not a substitute for the measurement the plan cites.

## Rejected

- (nothing yet)

## Review

(no round yet)

## Blockers

None.

## Where to look

- `.agents/harness/handover-context.sh` — the two compact branches.
- `joharness.sh:cmd_session_start` — where the mode is resolved. Read it,
  never re-derive it (plan Trap).
- `.agents/harness/selftest/handover-context-rank.sh` — fixture style.
