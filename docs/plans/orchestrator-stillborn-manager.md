---
plan: orchestrator-stillborn-manager
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: orchestrated-mode
scope: .claude/commands/orchestrate.md, .agents/docs/orchestrated.md
---

## Goal

A manager spawned by the orchestrator can come up never having run a turn:
no repository attached, no prompt processed, no branch, no claim. The
health table cannot name that state and the health pass never even looks
at it. Measured in consumer `chrsctl/gx` on 2026-09-07 — one opus manager
sat dead for at least 15 minutes while the item it was spawned for stayed
in dispatch's `spawn` list. Give the state a row, a discriminator that
holds, and a place in the pass that reaches it.

## The measurement

`manager: crm-ui-automation-rehearsal`, `session_018u6aNWHju2UJuRU83i1xev`,
spawned by `orchestrator: chrsctl/gx` at 10:13:29.630Z.

- `get_session` at 10:22Z, 10:23:4xZ and 10:26Z: byte-identical.
  `updated_at` frozen at 10:13:35.357Z — six seconds after `created_at`.
- No `external_metadata.last_served_model`. No `session_context.sources`.
  No `post_turn_summary`, no `task_summary`.
- `session_status: IDLE`, `status_bucket: REVIEW_READY`.
- `git fetch origin && git branch -r` at 10:23:36Z: no branch.
  `./joharness.sh dispatch` at 10:22Z and 10:23Z listed
  `docs/plans/crm-ui-automation-rehearsal.md (agent: opus)  wave 1` — free.

## Decisions

1. **The discriminator is two absent fields, not a token count.**
   `last_served_model` absent = no turn was ever served; `sources` absent
   = no repository was attached. In one `list_sessions` page at 10:28Z,
   eleven of twelve sessions carried both and only this one carried
   neither.
2. **`used_tokens` is refused as the discriminator**, and the refusal is
   written into the file, because it is the field a reader reaches for
   first. Same page, same minute: `DSGVO data export and auto-deletion
   flow` reads `RUNNING`, `WORKING`, a live `task_summary`, a pushed
   branch — and `context_usage.used_tokens: 0`. A rule keyed on it fires
   on a healthy manager.
3. **The row sits above the idle rows**, for the reason the crash rows do:
   one reading matches both, and the idle row's action is a nudge to a
   session with no context to read it and no branch to push.
4. **The pass has to reach it at all.** Step 2 walks "every manager in
   flight", which is dispatch's git view, and a manager that never claimed
   is in no row of it. The ledger is the only place it exists, so step 2
   gains the ledger's own stems.
5. **A stillborn is re-spawned, not RESPAWNED.** Nothing was claimed, so
   there is no branch, no handover owed and nothing to resume. It counts
   against `JOHARNESS_RESPAWN_LIMIT` anyway — a spawn that omits
   `source_url` repeats forever — and at the limit it is reported, because
   the "hand it to the human" write needs a branch and there is none.
6. **Step 3 gains a duplicate guard.** Once the row says "spawn it again",
   the item is in dispatch's `spawn` list AND in the ledger, and nothing
   in step 3 read the ledger. This half is reasoned, not observed: the
   10:24Z pass did not duplicate. It is in scope because decision 5
   creates the pressure.

## Out of scope

- `joharness.sh` and `dispatch`. Dispatch reads git; a session that cut no
  branch is correctly invisible to it, and the fix belongs where the
  control plane is read.
- Why the spawn attached no repository. The row names the field to check
  (`sources`) so an operator can see it; the cause is the runtime's.
- The gx copy. Canonical first, then the sync
  (`docs/product/README.md` § Reconciliation).

## Done when

- `.claude/commands/orchestrate.md` carries the row, the two field-table
  entries with the `used_tokens` counter-example, the third worked
  reading, the step 2 scope line and the step 3 guard.
- `.agents/docs/orchestrated.md` carries the matching word row and a Runs
  entry with the timestamps above.
- `./joharness.sh ci` green.
