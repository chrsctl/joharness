---
plan: heartbeat-check-each-pass
urgency: urgent
agent: sonnet
effort: medium
needs: none
requirement: none
issue: none
scope: shared:.agents/docs/orchestrate-reference.md, shared:.agents/docs/orchestrated.md, shared:.claude/commands/orchestrate.md, shared:.agents/harness/selftest/orchestrated.sh
---

## Goal

The joharness heartbeat broke while an orchestrator was live, and nothing
in the fleet noticed. Measured 2026-10-23: keeper
`session_0156C8AxDDvM99AE2QiQKgs1` read `ARCHIVED` at 13:36Z; a manual
"Run now" on the Routine at 13:37Z (`triggerFireReason: manual`, origin
`force_run_trigger`) rebound `persistent_session_id` to a fresh session
titled `⚡ heartbeat: chrsctl/joharness` with no repository
(`config:no-git-repo`), which answered "the /orchestrate command isn't
installed" and did nothing. The Routine still read `enabled: true` and
`last_run` `SUCCEEDED`. The heartbeat check runs only at "## 0. Start"
step 5, and the live orchestrator had passed it at 13:3xZ, so the
`keeper-gone` reason would surface only when the next orchestrator
starts — which is what the dead keeper was supposed to cause.

## Scope

- Run the heartbeat check (step 5's reasons, REPLACE included) on every
  `/orchestrate pass`, not only at start. Cost: one `list_triggers` (the
  pass already reads it for the duplicate check — reuse that answer) plus
  one `get_session` on the bound keeper.
- `.agents/docs/orchestrated.md`, Heartbeat: record the measured fact above in the
  "Bound, not fresh" paragraph (manual "Run now" on a Routine whose keeper
  is archived binds a fresh repo-less session; `last_run` stays
  `SUCCEEDED`). Status-quo wording; no incident narrative beyond the
  measurement line.
- `.agents/harness/selftest/orchestrated.sh`: a needle for the per-pass check.

## Out of scope

- Changing REGISTER, the cadence, the keeper's model, or the Routine name.
- Any check run by the keeper itself (a repo-less keeper cannot run it).
- Emoji titles (plan `role-title-emoji`).

## Acceptance

- `grep -n "every pass\|each pass" .agents/docs/orchestrate-reference.md`
  names the heartbeat check.
- `./joharness.sh ci` — `ci: pass`, the new needle among the pins.
- `./joharness.sh verify` — 0 failed.
- Consumer side (this ships): in a consumer synced with the change,
  `./joharness.sh ci` — `ci: pass`; its orchestrator's pass report carries
  the heartbeat line on a pass after the first.

## Where to look

- `.agents/docs/orchestrate-reference.md` — "## 0. Start" step 5, REGISTER,
  "## Duplicate" (already reads `list_triggers` each pass).
- `.claude/commands/orchestrate.md` — the pass loop.
- `.agents/docs/orchestrated.md` — "Bound, not fresh, by measurement".

## Traps

- Never enable, edit or delete a Routine a human paused or made in the UI.
- Docs state status quo; dates only on measured numbers.
