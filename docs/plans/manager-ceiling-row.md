---
plan: manager-ceiling-row
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
scope: shared:joharness.sh, shared:.agents/harness/selftest/dispatch.sh, shared:.claude/commands/orchestrate.md, shared:.agents/docs/orchestrated.md
---

## Goal

Issue #298, items 1 and 2. A consumer manager spent $48 over 5.5h and 8
commits with no pull request, and `dispatch` read it as healthy. It was
pushing, under the churn limit, and nothing measures time against the
item. Two other items were finished by a fresh session in about 5 minutes
for $0.88 and $1.89, after their first sessions had spent $46 and $19.
Add a git-only signal: hours since the claim with no pull request. Write
down what the orchestrator does with it. The issue does not claim the
right number. So this plan writes a default and flags it as the human's,
like `JOHARNESS_RESPAWN_LIMIT` ("no data; a written number until a run
counts one").

## Scope

- `joharness.sh:cmd_dispatch`:
  - read `JOHARNESS_MANAGER_HOURS` with `num_knob`, default `4`. `0` lifts it.
  - print it in the header block beside `respawns  :`, in the same style:
    `ceiling   : <N>h since the claim with no pr: = CEILING? (JOHARNESS_MANAGER_HOURS; 0 lifts it)`.
  - on a CLAIMED in-flight row (not an edge row, not a released row) whose
    status is `in-progress` and whose workstream `pr:` is empty or `none`:
    claim age = now − the committer time of the FIRST commit on the branch
    after the merge base (`git log --reverse --format=%ct <base>..<ref>`,
    first line, `</dev/null`). Age ≥ the knob → append to the row's flag:
    `  CEILING? <age> since the claim, no pr: — REPORT it with the control plane's cost (.claude/commands/orchestrate.md)`.
  - CEILING? does NOT set `cond`. It spawns no analyst, does not count
    as a stall, and does not change `n_stall`, `n_loop`, a verdict or the
    spawn list. Count it in a new `n_ceiling`, and add one tail line when
    > 0: `            <n> manager(s) past the ceiling with no pull request: report, never kill on this alone`.
- `joharness.sh`, the header comment listing `JOHARNESS_MAX_MANAGERS …
  JOHARNESS_RESPAWN_LIMIT=2` as the human's numbers: add
  `JOHARNESS_MANAGER_HOURS=4`.
- `.agents/docs/orchestrated.md`, `## The numbers are the human's` table:
  one row. `JOHARNESS_MANAGER_HOURS` | 4 | hours since a claim with no
  pull request = `CEILING?`, a report line; 0 lifts it | one consumer run
  (issue #298): $48 at 5.5h on one item, two items refreshed after $19 and
  $46. A written number until a run counts more.
- `.claude/commands/orchestrate.md`, step 2 health table: one row.
  `any` | any | `CEILING?` on the line | REPORT the row's age and the
  session's `cost_usd` as read this pass. Nothing else. Never kill,
  nudge or respawn on CEILING? alone. The STALL and LOOP rows still decide
  their own cases on the same row. A refresh (archive and respawn on the
  branch) is the human's call.
- `.agents/harness/selftest/dispatch.sh`: two fixtures.
  - A claimed `in-progress` branch, `pr: none`, first commit older than the
    knob, recent push → row carries `CEILING?`, the verdict is unchanged
    from the same fixture with `JOHARNESS_MANAGER_HOURS=0`.
  - The same branch with `pr: 12` → no `CEILING?`.

## Out of scope

- Cost. `dispatch` cannot see it (git view only). The orchestrator reads
  it from the control plane.
- An automatic refresh rule (#298 item 2 in full). It kills live work
  (archiving ends the container, the issue says so). A threshold for it is
  the human's. This plan writes only the report row.
- #298 item 3 (a time floor on a frozen-cost death test) and item 4 (a
  hand-over request). Item 3 is the research question named in
  `stall-rows-say-what-git-knows`' out-of-scope. Item 4: #298's own comment
  shows the route half-exists (`interrupt_session`), and what is missing is
  a stop-time gate.
- `.agents/scripts/conf-keys.sh`. Its dispatch knobs
  (`JOHARNESS_STALL_MINUTES`, `JOHARNESS_RESPAWN_LIMIT`) are not declared
  there today (`grep -c STALL_MINUTES .agents/scripts/conf-keys.sh` → 0).
  Follow that and do not add this one.

## Acceptance

- `bash .agents/harness/selftest/dispatch.sh` → 0 failed, both fixtures included.
- Revert the `joharness.sh` change only. The CEILING? fixture FAILS. Restore it.
- `JOHARNESS_MANAGER_HOURS=0 ./joharness.sh dispatch | grep -c "CEILING?"` → `0`.
- `./joharness.sh dispatch | grep "^ceiling"` → the header line.
- `./joharness.sh ci` → `ci: pass`. `./joharness.sh verify` → `0 failed`.
- SHIPS: `joharness.sh` reaches consumers. The consumer check is
  `./joharness.sh dispatch` in an orchestrated consumer with a manager
  older than 4h and no `pr:`.

## Where to look

- `joharness.sh:cmd_dispatch` — `respawn="$(num_knob JOHARNESS_RESPAWN_LIMIT 2)"`
  and its header printf; the claimed-row flag block (`STALL? no push for`,
  `LOOP?`, `cond=`); the tail lines after the verdict.
- `joharness.sh:dispatch_block_age_min` — a per-row git age read. The
  shape to copy.
- `.agents/docs/orchestrated.md:## The numbers are the human's` — the table.
- `.claude/commands/orchestrate.md:## 2. Health pass — before any spawn` — the table.

## Traps

- A claimed row's workstream `pr:` is branch-controlled text. Sanitise it
  the way the walk already sanitises fields before testing it.
- `stall-rows-say-what-git-knows`, `rescope-settled-by-merged-superset` and
  `plan-on-a-branch-visible` edit the same function, suite and table. All
  `shared:`. Reconcile at step 7.
- The numbers are the human's (`.agents/docs/orchestrated.md`). Say in the
  PR body that 4 is a written number, and ask the human to set it.
- Test written for the fix must fail without it.
