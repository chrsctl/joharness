---
workstream: idle-analysis
status: in-progress
branch: claude/worker-idle-detection-l3v9m3
pr: none
plan: idle-analysis
issue: 266
session: https://claude.ai/code/session_01TsLnukcKvuRKLXcJ34BLhg
agent: opus
updated: 2026-09-17
next: Implement docs/plans/idle-analysis.md, file by file, selftest first-class
---

## Goal

Issue #266, requester's ask: second env-gated mechanism beside
`JOHARNESS_UPSTREAM_FEEDBACK`, off by default, enabled in a child repo,
detecting and reporting WHY a manager idles or takes too long. Orchestrator
spawns an ANALYST for it. Child repo files the finding as a GitHub issue on
joharness (requester, this session).

## Decisions

- Plan first, same-session plan on this branch (`.agents/docs/plans/README.md`,
  Lifecycle). Direct human ask, so nothing builds unplanned.
- Artifact is a GitHub ISSUE on the canonical, not the reporter's research-node
  pull request. Requester said issue; and the subject is fleet behaviour at run
  time, not a finding attached to a merged diff — often no fix to assert.
- Analysed unit is the MANAGER, never the worker subagent. Requester's word is
  "worker"; the roles table spells the thing with a branch and a session
  `manager` (`.agents/docs/orchestrated.md`, Roles). Follow the table.
- No new threshold knob. Triggers are the marks `dispatch` already computes:
  `blocked`, `STALL?`, `LOOP?`. A fourth written number buys nothing.
- Block AGE stays with `docs/plans/unowned-block-age.md` (issue #254). This
  work anchors on the commit that last restated the cause, which needs no
  `git log -S` and no threshold.

## Rejected

- `needs: unowned-block-age`. Would block this plan behind that one for a
  timestamp this work can read itself, and the two readings answer different
  questions (how long has it stood / has config moved since).

## Review

Nothing yet.

## Blockers

None.

## Where to look

- `joharness.sh:upstream_mode` — the switch shape this one copies.
- `joharness.sh:cmd_dispatch` — where the `analysis :` line and the `ANALYSE?`
  mark land.
- `.claude/commands/upstream-report.md` — the spawned-role command file shape.
