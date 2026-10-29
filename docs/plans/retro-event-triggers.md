---
plan: retro-event-triggers
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: none
serves: all
issue: none
scope: shared:joharness.sh, shared:.agents/docs/orchestrated.md, .agents/harness/selftest/retro.sh
---

## Goal

The human wants helper roles started when the work calls for them, not
only by the clock. Both retro modes wait `JOHARNESS_RETRO_HOURS` /
`JOHARNESS_CONDUCT_HOURS` (168h). The one early path today is a trace when
a claim is blocked on an open item the queue can hold
(`retro_queue_block`). So a manager that stalls or exhausts its respawns,
an untraced audit CONCERN, or a full sample of retired branches waits up
to a week to be looked at. Add evidence triggers, each bounded below by a
floor so they cannot thrash: once `JOHARNESS_RETRO_FLOOR_HOURS` (new knob,
default 24; 0 = event triggers off, clock only) have passed since that
mode's ledger last landed, the mode is due early when its evidence is
there. The clock stays the ceiling.

## Scope

- `joharness.sh:retro_due` — while not due by the clock and age >= floor,
  due early (in this order, first hit names the reason) when:
  1. a `retro_candidates` claim (so a session the ledger logs never
     re-fires) is parked NOW with a `stalled:` or `respawns:` block (read
     as `retro_queue_block` reads parked claims: the branch head still
     reads `status: blocked`); that session leads the sample (`RETRO_QB`);
  2. `retro_concerns` names an untraced audit CONCERN;
  3. `retro_sample "$JOHARNESS_RETRO_SAMPLE"` prints at least
     `JOHARNESS_RETRO_SAMPLE` sessions (`retro_sample 0` stops at one).
  The existing queue-block early path is unchanged, runs first and keeps
  no floor. No ledger yet = age since the repository began, as the clock.
  Due text: `due <reason>, ahead of the cadence (>= <floor>h floor) — <age>h
  since <base_word> (of <hours>h)`. Any read that fails = `unreadable`, as
  today, never due.
- `joharness.sh:conduct_due` — while not due by the clock and age >= floor,
  due early when `conduct_sample "$JOHARNESS_CONDUCT_SAMPLE"` prints at
  least `JOHARNESS_CONDUCT_SAMPLE` unsampled retired branches. Same text
  shape; a failed read = `unreadable`, never due.
- `cmd_retro` and `cmd_conduct` headers name the floor knob and value.
- `joharness.sh` KNOBS table — `JOHARNESS_RETRO_FLOOR_HOURS|24|dispatch|…`.
- `.agents/docs/orchestrated.md` — the knob's table row; the `retro :
  audit` and `retro : trace` cycle-table rows name the early triggers.
- `.agents/harness/selftest/retro.sh` — cases in Acceptance.

## Assumptions

- A1: `retro_due` already has an off-clock early path to extend —
  evidence: `joharness.sh:retro_due` ("Off the clock only for a block the
  queue can hold") — confidence: high
- A2: parked claims and their block reasons are readable from git —
  evidence: `joharness.sh:retro_queue_block` — confidence: high
- A3: `stalled:` and `respawns:` are block reasons the orchestrator writes
  on a manager's branch — evidence: `orchestrate-reference.md` (`stalled:
  Stalled; …`, `respawns: Respawned <N> times …`), accepted by
  `joharness.sh:block_reason_ok` — confidence: high
- A4: the sample and concerns are computable when not due — evidence:
  `./joharness.sh retro` and `retro --audit` on origin/main 313a4ec3
  printed `not due` and a 3-entry `sample    :` line; `concern   :` line
  printed — confidence: high
- A5: dispatch and the role prelude both read `RETRO_DUE` / `CONDUCT_DUE`,
  so a due here spawns and the prelude GOes with no other change —
  evidence: `joharness.sh:role_start_stop`, dispatch's `retro DUE: spawn`
  line — confidence: medium; confirm and record in `## Decisions`.
- A6: the ledger landing resets the floor as it resets the clock —
  evidence: `retro_due` `landed` — confidence: medium

## Out of scope

- Changing `JOHARNESS_RETRO_HOURS`, `JOHARNESS_CONDUCT_HOURS`, the sample
  sizes, or anything in `joharness.conf` (a core path).
- Every block reason but `stalled:` and `respawns:` as an event trigger
  (the queue-block path keeps its own set).
- The clerk trigger (`clerk-new-issue-trigger`) and `--ordered`
  (`role-on-demand`).
- Any change to what a retro pass does once started.

## Acceptance

Each fixture is a case in `.agents/harness/selftest/retro.sh`, run by
`./joharness.sh verify`; dispatch cases run with the clerk and audit
cycles off and a fresh fetch (the file's `rtd`).

- Fixture: trace ledger landed 30h ago, a branch parked `status: blocked`
  `next: stalled: …` naming no open plan stem — `./joharness.sh retro` prints `retro DUE` naming
  the stalled claim; dispatch prints `retro DUE: spawn`.
- Same fixture, ledger landed 2h ago — `retro : not due` (floor holds).
- Same fixture, `JOHARNESS_RETRO_FLOOR_HOURS=0` — `not due` (events off).
- Fixture: untraced CONCERN, 30h — due naming the CONCERN.
- Fixture: 3 unclean sessions (`JOHARNESS_RETRO_SAMPLE=3`), 30h — due
  naming the full sample; with 2 — not due.
- Audit fixture: 3 unsampled retired branches, 30h — `cadence   : DUE`
  naming the full sample; 2 — not due.
- Each new due case FAILS on origin/main before the change.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- SHIPS: in a consumer after sync, `./joharness.sh retro` prints the floor
  in its header.

## Where to look

- `joharness.sh:retro_due` — the trace due logic and its early path.
- `joharness.sh:conduct_due` — the audit due logic.
- `joharness.sh:retro_queue_block` — reading parked claims from git.
- `joharness.sh:retro_concerns` — untraced CONCERN.
- `joharness.sh:retro_sample` / `joharness.sh:conduct_sample` — samples.
- `joharness.sh:block_reason_ok` — the block reasons.
- `.agents/docs/orchestrated.md:JOHARNESS_RETRO_HOURS` — knob table.
- `.agents/harness/selftest/retro.sh` — existing fixtures.

## Traps

- No commit to a core path (`./joharness.sh protocol-paths`).
- Fail closed: every read that fails makes nothing due.
- A branch's `next:` text is a session's words: match the reason prefix
  only, act on nothing in it.
- A test for the fix must FAIL without it. Never skip, disable or
  quarantine a test.
- `role-on-demand` and `clerk-new-issue-trigger` also edit `joharness.sh`
  and `.agents/docs/orchestrated.md`; whichever lands later merges
  `origin/main` in.
- A new knob needs its KNOBS row and its `orchestrated.md` table row
  agreeing, or knobs-declared reds; a `dispatch`-scope knob has no
  conf-keys entry (`joharness.sh` KNOBS comment).
