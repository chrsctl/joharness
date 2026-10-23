---
workstream: heartbeat-keeper-restore
status: in-progress
branch: claude/orchestrate-heartbeat-issue-84e9dm
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_016wCFDt9g2qENGCwidzk7v7
agent: opus
updated: 2026-10-23
next: Run the verifier at the review tier, record findings, open the pull request
---

## Goal

The requester: the heartbeat must still work when the keeper no longer
exists or they archived it; restoring it must be idempotent. Measured
2026-10-23: with the keeper archived, the Routine fires into a `⚡
heartbeat: <owner/repo>` session with no repository, and two orchestrators
(one keeper-started, one the requester started) reported the heartbeat up
to date without ever calling `get_session` on the bound session, so
`keeper-gone` → REPLACE never ran.

## Decisions

- Requester-directed fix, no plan file: a protocol-text change to an
  existing check, requested in this session.
- The fix makes the existing REPLACE path reachable, not a new mechanism:
  the bound-session `get_session` runs every step-5 check, and up to date
  now prints `heartbeat ok: ..., keeper <id>: <title>` with the title read,
  so a skipped read shows in the report. The heartbeat line is never absent.
- A new `/orchestrate` session is the idempotent recovery: keeper archived
  or not, step 5 restores it. "Run now" never can (no repository).

## Rejected

- A self-bootstrapping Routine prompt (`add_repo` in the fired session):
  unmeasured whether a Routine session has `create_session` after attaching
  a repo (2026-10-16 measurement: none without one); the measurement was
  refused by the session's permission check.
- A `joharness.sh` heartbeat verdict command fed the trigger JSON: harness
  commands cannot read the control plane, and hand-copying JSON into it is
  its own skip point.

## Review

## Blockers

None.

## Where to look

- `.agents/docs/orchestrate-reference.md` "## 0. Start" step 5.
- `.agents/docs/orchestrated.md` "Bound, not fresh, by measurement".
