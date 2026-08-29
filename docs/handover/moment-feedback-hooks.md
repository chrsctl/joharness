---
workstream: moment-feedback-hooks
status: in-progress
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: moment-feedback-hooks
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Verify the PreToolUse output contract before writing the emitter.
---

## Goal

Stage 4 of the feedback loop — Prevent, the only stage that changes an
outcome — rides on the model remembering to ask. A PreToolUse hook injects a
file's recorded findings the moment a tool is about to edit it.

## Decisions

- (recounting the plan's figures first; the plan says not to trust them)

## Rejected

- (nothing yet)

## Review

(no round yet)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_feedback` — the report this serves; where the quiet
  shape lands.
- `joharness.sh:fb_collect` — the one history walk the cache answers.
- `.agents/harness/handover-guard.sh` — stdin handling and fail-open.
