---
workstream: graduate-scorecard-finding
status: in-progress
branch: claude/graduate-scorecard-finding
pr: none
plan: scorecard-without-gaming
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-30
next: Graduate the Goodhart finding into .agents/docs/agent-selection.md, then retire the research file
---

## Goal

`docs/research/scorecard-without-gaming.md` is answered and verified and has
not graduated. The plan it judged, `process-scorecard`, has since merged and
retired, so the finding now describes a command that exists — which makes
graduating it more urgent, not less: the reasoning that should govern the
shipped `scorecard` lives only in a research node scheduled for deletion.

## Decisions

- Picked over `fanout-live-run`, which `drain` names first and which stays
  unclaimable: its precondition is a wave of two or more, and it is now the
  only free plan. It also wants an explicit human go-ahead.
- Edge branch NOT taken. Its session went IDLE, not gone, and it is
  review_ready with no pull request open. Step 7 gives this session its own
  pull requests and no others, so this is a flag to the human, not a merge.

## Rejected

- None yet.

## Review

None yet.

## Blockers

None.

## Where to look

- `docs/research/scorecard-without-gaming.md` — the finding to graduate.
- `.agents/docs/agent-selection.md` — where it lands.
- `joharness.sh:cmd_scorecard` — the command the finding now governs.
