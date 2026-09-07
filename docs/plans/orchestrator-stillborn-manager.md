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

A manager the orchestrator spawns can come up never having run a turn: no
repository attached, no prompt processed, no branch, no claim. Nothing in
the role can name that state, and the health pass never even reaches it —
it walks `dispatch`'s in-flight list, which is derived from git, and a
manager that never claimed cut no branch. Measured in consumer
`chrsctl/gx` on 2026-09-07: one opus manager was observed frozen from
10:13:35.357Z to the 10:28Z session page — 14m30s from its `created_at` of
10:13:29.630Z, and still frozen when this plan was written — while the item
it was spawned for stayed in `dispatch`'s `spawn` list as `wave 1`.

## The measurement

`manager: crm-ui-automation-rehearsal`, `session_018u6aNWHju2UJuRU83i1xev`,
spawned by `orchestrator: chrsctl/gx` at 10:13:29.630Z.

- `get_session` at 10:22Z, 10:23Z and 10:26Z: `updated_at` unchanged at
  10:13:35.357Z each time — six seconds after `created_at`. Not
  whole-record identity; the field.
- No `external_metadata.last_served_model`. No `session_context.sources`.
  No `post_turn_summary`, no `task_summary`.
- `session_status: SESSION_STATUS_IDLE`,
  `status_bucket: SESSION_STATUS_BUCKET_REVIEW_READY`.
- `git fetch origin && git branch -r` at 10:23:36Z: no branch.
  `./joharness.sh dispatch` at 10:22Z and 10:23Z listed
  `docs/plans/crm-ui-automation-rehearsal.md (agent: opus)  wave 1`.
- The discriminator, counted over one `list_sessions` call (limit 40,
  mine, 10:22Z): 37 of 40 carried both fields, 3 lacked
  `last_served_model`, 1 lacked `sources`, and exactly one lacked both.
  The two other sessions missing `last_served_model` are `ARCHIVED`, a
  state the row does not reach. Either field alone is weaker than the
  pair. This is control-plane data and no checkout can recount it; the
  call and its minute are what the number carries.

## Scope

- `.claude/commands/orchestrate.md` — step 0.2, step 0.4, step 2's scope
  paragraph, the field table, four rows above the idle rows, a third
  worked reading, RESPAWN, step 3, step 4's ledger grammar, the
  optional-tools row for `archive_session`.
- `.agents/docs/orchestrated.md` — the `stillborn` and `unclaimed` word
  rows, the heading, the Runs note.

## Out of scope

- `joharness.sh` and `dispatch`. Dispatch reads git; a session that cut no
  branch is correctly invisible to it, and the fix belongs where the
  control plane is read.
- Why the spawn attached no repository. The rows name the field to check
  (`sources`); the cause is the runtime's.
- The gx copy. Canonical first, then the sync
  (`docs/product/README.md` § Reconciliation).
- Nudging or respawning the gx manager. Its orchestrator was `RUNNING` and
  mid-pass; a second driver is the duplicate this mode already priced. That
  orchestrator's own wake message did carry
  `crm-ui-automation-rehearsal@new next=just spawned wave1` — it wrote the
  entry on its own initiative. What is missing is the INSTRUCTION: nothing
  prescribed that entry, and nothing told the health pass to walk a stem
  that appears only there.

## Acceptance

`ci` cannot establish any of this — it reads no health-table text and is
green whether a row is right, wrong or unreachable. That is the shape
`PR226 r9` recorded in this same file, and its remedy is the discrimination
read, repeated here:

1. `./joharness.sh ci` — pass. Necessary, not sufficient; it proves the
   glossary, the anchors and the budgets, nothing about the rows.
2. **The rows discriminate.** Delete the three worked readings from a
   scratch copy of `.claude/commands/orchestrate.md` — a reader who answers
   from an example has not read a row — then walk each record below down
   the table from the top and write the FIRST row that matches:

   | record | must land on |
   | --- | --- |
   | `IDLE`, bucket `..._REVIEW_READY`, no `last_served_model`, no `sources`, entry `new`, `seen=` recorded a pass ago and `updated_at` unchanged | the STILLBORN row |
   | the same record on its FIRST look, no `seen=` recorded | the UNCLAIMED first-look row — `seen=` and nothing else |
   | `IDLE`, bucket `..._COMPLETED`, both fields present, branch pushed | the existing idle NUDGE row, never a new one |
   | `RUNNING`, bucket `..._WORKING`, live `task_summary`, branch pushed, `used_tokens: 0` | `working. Nothing.` — the row that proves the count was not keyed on tokens |
   | `ARCHIVED`, bucket `..._FAILED`, both fields present | the CRASHED row, unchanged by this plan |
   | entry `new`, `last_served_model` PRESENT, `updated_at` unchanged | the report-only row — never a respawn |

   A record landing on a different row is the defect; a table where two
   records land on the same row has stopped discriminating.
3. **No path spawns without step 2.** `grep -n "step 3" .claude/commands/orchestrate.md`
   and read every hit: the only spawn of a ledger-named item is the one
   this pass's health pass ordered.

## Where to look

- `.claude/commands/orchestrate.md:Health pass` — "every manager in flight" is
  dispatch's git view, which is what makes an unclaimed manager invisible.
- `.claude/commands/orchestrate.md:Spawn` — spawns off dispatch's list, which
  still holds an item whose manager has not claimed.
- `.agents/docs/orchestrated.md:Health` — the word table the command file's
  rows must agree with.

## Traps

- **A condition that can never match.** `PR226 r3`, this file: a row keyed
  on the ledger while step 0.4 defined the ledger as items *in flight*.
  Anything this plan keys on the ledger must be something step 3 and step 4
  are told to write.
- **One reading is not two.** The GONE rule is `ARCHIVED`, not found, a
  FAILED bucket confirmed twice, or no movement across two reads — never
  `IDLE` alone. A ledger write is not a read of the session record.
- **Row order decides.** Rows are act-on-first-match, so a new row is only
  where it sits (`PR226 r1`, `PR226 r5`).
- **One owner per measurement.** `PR233 r10`: the same consumer number in
  four places. The reading belongs to the worked example, run-level numbers
  to Runs.
- **Written numbers.** A number that carries no command and no minute is a
  written number, whatever produced it.
