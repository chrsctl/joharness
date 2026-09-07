---
workstream: orchestrator-stillborn-manager
status: in-progress
branch: claude/check-manager-crm-ui-automation-br4cn4
pr: none
plan: orchestrator-stillborn-manager
issue: none
session: https://claude.ai/code/session_019pSQgotmS3gsHwKxhTmey4
agent: sonnet
updated: 2026-09-07
next: Edit .claude/commands/orchestrate.md and .agents/docs/orchestrated.md per the plan, run ci, review, retire both files.
---

## Goal

The human asked, after a health check on one manager found it dead on
arrival: can we fix it in the harness. The state the check found — a
spawned manager that never ran a turn — has no row in the health table and
no path in the health pass that reaches it. Give it both.

## Decisions

- The branch name is the session's, not the workstream's: this session was
  started as `Check manager: crm-ui-automation-rehearsal` and its branch
  was set for it. The workstream file is named for the work.
- Discriminator is `last_served_model` + `sources`, both absent, confirmed
  across the ledger's previous pass and this one. Not `used_tokens` — the
  plan carries the counter-example that refuses it.

## Rejected

- Keying the row on `context_usage.used_tokens == 0`. A live, working
  session read 0 in the same `list_sessions` page, minutes apart from the
  dead one (plan, decision 2). It is the obvious field and it is wrong.
- Keying on `external_metadata.current_branches` being absent. It is
  absent on healthy sessions too — this very session has branches in
  `session_context.outcomes` and no `current_branches` at 10:28Z.
- Nudging the stillborn manager from this session. Its orchestrator was
  `RUNNING` and mid-pass at 10:24:20Z with the item on its ledger; a
  second driver is the duplicate-manager cost Runs already prices.
- Editing the gx copy. Harness fixes land canonical first.

## Review

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` § 2 — "every manager in flight" is
  dispatch's git view, which is what makes an unclaimed manager invisible.
- `.claude/commands/orchestrate.md` § 3 — spawns off dispatch's list with
  no reference to the ledger.
