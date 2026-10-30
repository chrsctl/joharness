---
workstream: orchestrator-swap-stall
status: in-progress
branch: orchestrator-swap-stall
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01J1YMK3QQkaEaufEDXwCr5n
agent: sonnet
updated: 2026-10-30
next: Run ci and verify, open the pull request, merge on finish
---

## Goal

gx stalled 2026-10-30 03:46Z to 07:30Z with no orchestrator running. The
keeper's SWAP started successor `pass=1` while the retiring session's
`pass=7 retire=yes` wake was still pending. The successor read that other
session's wake as superseding it and stood down. The retired session's wake
then did nothing. Every hourly keeper after that called the stood-down
successor LIVE on its title alone, though it was IDLE with no wake pending.

## Decisions

- Superseded check compares only this session's own wakes. Another session's
  pending wake is Duplicate's matter, which reads LIVE and so skips a retired
  title.
- keeper step 2: a `🎼` title that is neither RUNNING nor PENDING and holds no
  wake is NOT LIVE. This is what the reference's step 3 definition already
  says. The keeper (haiku) misread the dense sentence, so it is now spelled
  out.

## Review

- r1: edge review clean: both rules now match ref "## 0. Start" step 3 LIVE;
  new needles fail on origin/main (no change)

## Blockers

None.

## Where to look

- `.claude/commands/orchestrator.md` Pass entry, Superseded.
- `.claude/commands/keeper.md` step 2.
