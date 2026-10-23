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

- r1: (verifier) `ok` line forgeable: every field came from `list_triggers` or was the one passing title (fixed: carries `session_status` and `updated_at`, only `get_session` returns them)
- r2: (verifier) `get_session` erroring had no reason and no REPLACE rule (fixed: `keeper-unread`, stale line, never REPLACE on it alone)
- r3: (verifier) "never none" broke on report-only, cap-spent-with-no-Routine and no-`list_triggers` runs (fixed: both suppressed REGISTERs print `heartbeat not registered: <why>`; none only without `list_triggers`)
- r4: (verifier) "REPLACE restores it" overclaimed past REGISTER's once-per-session cap (fixed: says once per session)
- r5: (verifier) REPLACE left a `⚡` bound session unarchived (fixed: archives the bound session, keeper or `⚡`)
- r6: (verifier) orchestrated.md sentence was a dated incident count, against caveman.md Status quo (fixed: states the mechanism)
- r7: (verifier) `plan: none` without the copy/sync exemption (wontfix: direct ask in a human-attended session, protocol-text fix to one check; flagged for the human in the pull request)
- r8: (verifier) "Run now" platform claim not checkable from the checkout (no change: control-plane readings 2026-10-23, `force_run_trigger` sessions `cse_01YPLgGoQ5BhmpXWrhdHr8ay` and `cse_01HQ7Cx4shudK6Dd5i5kjjiN`)

## Blockers

None.

## Where to look

- `.agents/docs/orchestrate-reference.md` "## 0. Start" step 5.
- `.agents/docs/orchestrated.md` "Bound, not fresh, by measurement".
