---
research: knobs-to-constants
urgency: normal
agent: sonnet
effort: medium
graduates: .agents/docs/orchestrated.md
---

## Question

Which of the `JOHARNESS_*` knobs no repository overrides, and can become
fixed constants without changing behaviour for any consumer?

## Echo

`joharness.sh` declares 49 (the file said 50; `grep -c` counts 49) `JOHARNESS_*` knobs in its KNOBS table
(`sed -n '/# KNOBS-BEGIN/,/# KNOBS-END/p' joharness.sh`), with defaults and
scopes. This repository's `joharness.conf` sets 6 of them. Counted by
`grep -rqw <key> .claude .agents/docs .agents/harness/AGENTS.md`: 14 appear
in no doc at all, and 30 appear only in a markdown table row. Each knob costs a
table row, a doc row and, for conf-scoped knobs, lines in
`bootstrap-consumer.sh` and `conf-keys.sh`.

Some knobs must stay knobs:
- a knob any consumer sets;
- a knob a test sets to reach a branch, unless the test can reach it
  another way;
- a session or environment knob a human needs, for example
  `JOHARNESS_CHECKS`.

A plan cutting the rest rests on this answer.

## Sweep

comprehensive: every row of the KNOBS table, each classified.

## What would settle it

A table of every knob. Each row gives:
- set by this repository's conf (yes/no);
- set by each known consumer's conf, which needs read access. gx is the
  known one; name each consumer read;
- set by a selftest (the file);
- named in a doc as something a human changes;
- verdict: KEEP, CONSTANT, or UNKNOWN (with what blocks it).

UNKNOWN is allowed when a consumer cannot be read. It is never guessed
CONSTANT.

## Method

Second context, named up front: each consumer's `joharness.conf`, read with
the GitHub MCP `get_file_contents` on that repository (gx: `chrsctl/gx`,
which needs `add_repo` read access). A consumer that cannot be read is
named, and its knobs stay UNKNOWN. The rest is pending: the researching
session fills it.

## Findings

Table of the 49 rows `sed -n '/# KNOBS-BEGIN/,/# KNOBS-END/p' joharness.sh`
holds (the Echo said 50; `grep -c` of the rows counts 49). Columns: this conf
= `joharness.conf`; seeded = named in `.agents/scripts/conf-keys.sh` (every
consumer conf carries it); selftest sets = files under
`.agents/harness/selftest/` and `selftest.sh` that assign it.

| knob | scope | this conf | seeded in consumer conf | selftest sets (file count) | doc outside the table | verdict |
|---|---|---|---|---|---|---|
| `JOHARNESS_ENV` | conf | yes | yes | 29 | - | KEEP (consumer conf carries it) |
| `JOHARNESS_ENV_SETUP` | conf | yes | yes | 2 | - | KEEP (consumer conf carries it) |
| `JOHARNESS_ENV_MD` | conf | yes | yes | 2 | - | KEEP (consumer conf carries it) |
| `JOHARNESS_REVIEW` | conf | yes | yes | 4 | README.md,agent-selection.md | KEEP (consumer conf carries it) |
| `JOHARNESS_CHECKS` | session | no | no | 1 | consumer-repos.md | KEEP (human/session knob) |
| `JOHARNESS_LOCAL_CHECK_MINUTES` | session | no | no | 1 | consumer-repos.md | KEEP (human/session knob) |
| `JOHARNESS_MAX_MANAGERS` | dispatch | yes | no | 11 | agent-selection.md,orchestrate.md | KEEP (this conf and a selftest set it; not seeded) |
| `JOHARNESS_STALL_MINUTES` | dispatch | no | no | 4 | manage.md,orchestrate-reference.md | KEEP (selftest sets it) |
| `JOHARNESS_HEALTH_MINUTES` | dispatch | no | no | 1 | agent-selection.md,orchestrate.md | KEEP (selftest sets it) |
| `JOHARNESS_RESPAWN_LIMIT` | dispatch | no | no | 0 | orchestrate-reference.md,orchestrate.md | UNKNOWN (gx conf unread; no test or conf here sets it) |
| `JOHARNESS_ORCHESTRATOR_PASSES` | dispatch | no | no | 1 | orchestrate-reference.md,orchestrate.md | KEEP (selftest sets it) |
| `JOHARNESS_MANAGER_HOURS` | dispatch | no | no | 1 | - | KEEP (selftest sets it) |
| `JOHARNESS_CHURN_THRESHOLD` | dispatch | no | no | 4 | agent-selection.md | KEEP (selftest sets it) |
| `JOHARNESS_CHURN_LIMIT` | dispatch | no | no | 4 | agent-selection.md | KEEP (selftest sets it) |
| `JOHARNESS_CURATE_REGISTRY` | dispatch | no | no | 1 | - | KEEP (selftest sets it) |
| `JOHARNESS_CURATE_SPLIT` | dispatch | no | no | 1 | - | KEEP (selftest sets it) |
| `JOHARNESS_CURATE_LAYERS` | dispatch | no | no | 1 | - | KEEP (selftest sets it) |
| `JOHARNESS_CLERK_HOURS` | dispatch | no | yes | 3 | - | KEEP (consumer conf carries it) |
| `JOHARNESS_CLERK_BATCH` | dispatch | no | yes | 1 | clerk.md | KEEP (consumer conf carries it) |
| `JOHARNESS_CLERK_STALE_HOURS` | dispatch | no | no | 1 | clerk.md | KEEP (selftest sets it) |
| `JOHARNESS_SCOUT_READS` | dispatch | no | yes | 1 | - | KEEP (consumer conf carries it) |
| `JOHARNESS_CONDUCT_HOURS` | dispatch | no | yes | 2 | - | KEEP (consumer conf carries it) |
| `JOHARNESS_CONDUCT_SAMPLE` | dispatch | no | yes | 1 | - | KEEP (consumer conf carries it) |
| `JOHARNESS_RETRO_HOURS` | dispatch | no | no | 1 | - | KEEP (selftest sets it) |
| `JOHARNESS_RETRO_SAMPLE` | dispatch | no | no | 1 | - | KEEP (selftest sets it) |
| `JOHARNESS_RETRO_EVENTS` | dispatch | no | no | 0 | retro.md | UNKNOWN (gx conf unread; no test or conf here sets it) |
| `JOHARNESS_DEFECT_PLAN_HOURS` | dispatch | no | no | 1 | - | KEEP (selftest sets it) |
| `JOHARNESS_DEFECT_FIX_HOURS` | dispatch | no | no | 1 | - | KEEP (selftest sets it) |
| `JOHARNESS_DEFECT_RECHECK_HOURS` | dispatch | no | no | 1 | orchestrate-reference.md | KEEP (selftest sets it) |
| `JOHARNESS_SCOUT_REVIEWER` | base-conf | no | yes | 4 | - | KEEP (consumer conf carries it) |
| `JOHARNESS_SCOUT_RESEARCH` | base-conf | no | yes | 1 | - | KEEP (consumer conf carries it) |
| `JOHARNESS_CANONICAL` | session | yes | no | 11 | clerk.md,consumer-repos.md | KEEP (this conf and a selftest set it; not seeded) |
| `JOHARNESS_CONF` | session | no | no | 42 | - | KEEP (human/session knob) |
| `JOHARNESS_VERBOSE` | session | no | no | 5 | - | KEEP (human/session knob) |
| `JOHARNESS_SELFTEST` | session | no | no | 2 | - | KEEP (human/session knob) |
| `JOHARNESS_SELFTEST_GIT_PER_CASE` | session | no | no | 1 | - | KEEP (selftest sets it) |
| `JOHARNESS_SELFTEST_JOBS` | session | no | no | 0 | - | KEEP (human/session knob) |
| `JOHARNESS_SESSION_SOURCE` | session | no | no | 1 | - | KEEP (selftest sets it) |
| `JOHARNESS_FORCE_SETUP` | session | no | no | 0 | - | KEEP (human/session knob) |
| `JOHARNESS_SHIP` | session | no | no | 1 | README.md | KEEP (selftest sets it) |
| `JOHARNESS_UPGRADE_IN_SESSION` | session | no | no | 1 | consumer-repos.md | KEEP (human/session knob) |
| `JOHARNESS_FEEDBACK_CACHE` | session | no | no | 2 | - | KEEP (human/session knob) |
| `JOHARNESS_FEEDBACK_EDGES` | session | no | no | 2 | feedback.md | KEEP (selftest sets it) |
| `JOHARNESS_RECURRENCE_WINDOW` | session | no | no | 2 | feedback.md | KEEP (selftest sets it) |
| `JOHARNESS_CONTEXT_WINDOW` | session | no | no | 1 | - | KEEP (selftest sets it) |
| `JOHARNESS_CONTEXT_WARN` | session | no | no | 1 | - | KEEP (selftest sets it) |
| `JOHARNESS_CONTEXT_CRIT` | session | no | no | 1 | - | KEEP (selftest sets it) |
| `JOHARNESS_PENDING_SPAWNS` | session | no | no | 2 | orchestrate.md | KEEP (selftest sets it) |
| `HANDOVER_STALE_SECONDS` | session | no | no | 4 | README.md | KEEP (selftest sets it) |

Totals: 47 KEEP, 0 CONSTANT, 2 UNKNOWN.

- Consumer read: `chrsctl/gx` was NOT read. `add_repo` on it was denied in
  this session, so no `get_file_contents` call was made. Every knob a consumer
  conf can answer (`num_knob` reads env, then conf, for all of `dispatch`)
  stays UNKNOWN or KEEP; none is CONSTANT. (UNGROUNDED for gx.)
- KEEP rests on a command here, not a guess: the seeded and this-conf columns
  are `conf-keys_rows` and `joharness.conf`; the selftest column is the grep
  above. Whether a selftest could reach its branch without the knob is a
  design question this file did not settle; a plan cutting a KEEP row must.
- The only two knobs no selftest assigns and no conf here sets (RESPAWN_LIMIT is only a commented template line in joharness.conf and an unset in selftest.sh; RETRO_EVENTS is only named in a retro.sh header assertion): `JOHARNESS_RESPAWN_LIMIT`
  (`joharness.sh` `num_knob` at the dispatch print) and
  `JOHARNESS_RETRO_EVENTS` (`num_knob` in the retro header). Both are
  consumer-conf-readable, so they are candidates once gx is read, not
  CONSTANTs. The `retro` selftest asserts the header names the knob, so
  constanting it edits that expectation.
- The Echo's 14 + 30 counts do not decide anything: absence from docs does
  not mean no setter. 45 of the 49 rows are set by a selftest (the other four: RESPAWN_LIMIT, RETRO_EVENTS, SELFTEST_JOBS, FORCE_SETUP).

## Consequence for the queue

No plan turning knobs into constants is justified yet. File one only after
`chrsctl/gx`'s `joharness.conf` is read by a session granted that repository:
it then settles `JOHARNESS_RESPAWN_LIMIT` and `JOHARNESS_RETRO_EVENTS`. Cutting
any KEEP row first needs the test-reach question answered.

## Verification

A verifier (second context) re-takes the table's columns from this checkout.
