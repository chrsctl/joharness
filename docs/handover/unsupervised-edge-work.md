---
workstream: unsupervised-edge-work
status: in-progress
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: unsupervised-edge-work
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Read queue-context.sh's two edge paths and the no-plans branch against the plan's claims before writing code.
---

## Goal

`docs/plans/unsupervised-edge-work.md`. Under supervised the queue edge is
where a session stops and asks. Under unsupervised it is where work begins:
research the repo against a CLOSED source list, write plan files, open a
pull request. Unless the sweep is dry, which is where the mode stops.

## Decisions

- Claimed at the plan's own tier (opus). No escalation needed.
- Checked every remote branch for a competing claim before cutting. Free.

## Rejected

- Nothing yet.

## Review

Not yet run: no edge, no pull request open.

## Blockers

None. `needs: unsupervised-sources` cleared when #120 merged and deleted
that plan file — file existence IS the edge, so the block is gone.

## Where to look

- `.agents/harness/queue-context.sh` — the two edge paths and the no-plans
  branch whose unplanned-requirements arm must keep winning.
- `joharness.sh:cmd_sources` — the sweep this reads, shipped in #120.
