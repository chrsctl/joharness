---
workstream: orchestrator-heartbeat-successor
status: in-progress
branch: claude/orchestrator-heartbeat-successor
pr: none
plan: orchestrator-heartbeat-successor
issue: none
session: https://claude.ai/code/session_01KyirxKSbmXU6prDj22WtaH
agent: opus
updated: 2026-10-16
next: ci and verify green, verifier review, PR shipping the heartbeat check; plan stays queued for the successor
---

## Goal

A fleet that lives indefinitely and stays cheap: the heartbeat Routine is the
durable piece, the orchestrator hand-off fires it instead of deepening
lineage with create_session.

## Decisions

- Human asked (2026-10-16): the protocol checks that the heartbeat Routine
  exists and is up to date. Built here as the plan's "heartbeat test"
  bullet, widened: orchestrate.md §0 step 5 names the Routine
  `heartbeat: <owner/repo>` (list_triggers shows no repository, so the
  name is the only per-repo key), and reports `disabled`, `bound`,
  `session-made`, `failing`, `prompt` drift, or duplicates. Report and push
  only: creating or editing stays the operator's (Out of scope).
- This PR does NOT retire the plan: the fire_trigger successor and the
  IDLE liveness rule still wait on the UI-created Routine's lineage
  reading. The plan file loses the delivered bullet and keeps the rest.

- Did not build ahead of the measurement: the plan makes depth d+1 a
  no-build outcome, so code before the reading may be thrown away.

## Rejected

- Routine created from a session (human said go, 2026-10-16):
  `create_trigger` cron `0 * * * *`, `create_new_session_on_fire`, prompt
  `/orchestrate`, id `trig_01DoRGxgQGtL4emWGRSiVbMW`, now PAUSED
  (`enabled: false`). `fire_trigger` once at 11:10Z returned the fired
  session's id (`session_011K3RWr1Ypfqu4z8XiW5CyX`). That session:
  `sources: []` (tag `config:no-git-repo`), no MCP connectors, no Claude
  Code Remote session tools (no `get_session`, `create_session`,
  `send_message`), no GitHub MCP, ran on the default model, and the auto
  mode classifier denied `./joharness.sh dispatch` on its own clone as
  "Code from External". It spawned nothing. Its record carries no
  `parent_session_id` and tag `config:routine-lineage-none` (depth 0
  likely, not read by `get_session` inside it). Cannot orchestrate: needs
  a UI-created Routine with the repo source and the remote tools.

## Review

- r1: (verifier) "never fire" ban contradicted the queued plan's fire_trigger successor (fixed: ban is create, edit, pause)
- r2: (verifier) orchestrated.md still said the heartbeat is made by create_trigger (fixed: made in the claude.ai UI)
- r3: (verifier) bootstrap heartbeat note named a renamed bullet and no Routine name; plan next: gave no name (fixed: bullet keeps "connector trap", note and plan name heartbeat: <owner/repo>)
- r4: (verifier) duplicates counted paused copies and hid the other checks (fixed: duplicated = two or more enabled; else check the enabled one)
- r5: (verifier) prompt check made the orchestrator read a design doc (fixed: spelled inline, exactly /orchestrate)
- r6: (verifier) failing and prompt checks used wrong field spellings (fixed: ends in FAILED, derived_state.prompt)
- r7: (verifier) docs disagreed on which lines push (fixed: stale and duplicated push, no heartbeat reports only, both docs)
- r8: (verifier) once per session pushes hourly, unsaid (fixed: said)
- r9: (verifier) step 3 exit reported a heartbeat line step 5 had not computed (fixed: step 3 runs step 5 before exit)
- r10: (verifier) UI-made created_via unread; recurring filter may hide paused ones (fixed: no filter; plan prerequisite reads created_via and drops session-made if meta_mcp)
- r11: (verifier) measurement overclaimed "stores no repository" without passing connectors (fixed: says what was passed and seen)
- r12: (verifier) measurement written as a dated story (fixed: cut to rule plus command and date)
- r13: (verifier) new clauses unpinned, /orchestrate needle prefix-matched (fixed: needles added, each fails with its clause removed)

## Blockers

- Prerequisite unmet (plan, "Prerequisite"): no heartbeat Routine exists.
  `list_triggers` (2026-10-16, this session) returned three Routines, none
  with a `cron_expression`: `Orchestrate pass 3` is a one-shot `run_once_at`
  reminder bound to a persistent session (`/orchestrate pass` wake, not a
  heartbeat); the other two are disabled (`auto_disabled_session_gone`).
  Creating a recurring Routine is the human's spend (Out of scope). This
  manager session reads `lineage` depth 2 (`get_session`), so it cannot
  stand in for a Routine-fired reading. Unblock: operator creates an hourly
  `/orchestrate` Routine; a manager then takes both readings and builds.

## Where to look

- `.claude/commands/orchestrate.md` — §0 step 3, §4 HAND-OFF, Tools table.
- `.agents/docs/orchestrated.md` — Heartbeat section.
