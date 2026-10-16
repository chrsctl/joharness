---
workstream: orchestrator-hand-off-lineage-cap
status: in-progress
branch: claude/orchestrator-hand-off-lineage-cap
pr: none
plan: orchestrator-hand-off-lineage-cap
issue: none
session: https://claude.ai/code/session_01NAJQNsQCP5ob8fkWYjKsVg
agent: opus
updated: 2026-10-16
next: ci, verify, verifier review, then retire and open the pull request
---

## Goal

Settle `docs/research/orchestrator-hand-off-lineage-cap.md`: can §4 HAND-OFF
strand the fleet at the control plane's lineage cap; graduate the guard into
`.claude/commands/orchestrate.md`.

## Decisions

- Second context = this manager session's own `get_session` calls: own
  record carries `lineage` depth 1 limit 8 (parent = orchestrator, origin
  ios); parent record carries no `lineage`; all nine gx ids walked, linear
  chain, root has no `parent_session_id`, created_at matches the table.
- Guard threshold `depth + 1 < limit`: the successor must stay below the
  cap to spawn and arm; its managers may sit AT the cap, since no role
  command calls `create_session` or `send_later`.
- §0 check placed after the Lineup (step 5), not before step 3: no
  renumbering of the many `"## 0. Start" step 3` references; a stopped
  session reads IDLE so its title blocks nobody.
- Push on the capped hand-off only at `pass=` = passes + 1: once, no new
  ledger key.
- Heartbeat depth left as a stated unmeasured operator reading: creating a
  Routine is recurring spend, operator only.

## Rejected

- A new ledger key for the once-only push: the pass number already says it.

## Review

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` — §0 Start, §4 HAND-OFF.
- `.agents/docs/orchestrated.md` — "Start each run fresh", Heartbeat.
