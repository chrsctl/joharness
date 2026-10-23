---
plan: defect-resume
urgency: normal
agent: opus
effort: high
needs: defect-block-resumes
requirement: defect-to-fix-loop
issue: none
scope: shared:joharness.sh, .claude/commands/orchestrate.md, .agents/docs/orchestrate-reference.md, shared:.agents/docs/orchestrated.md, shared:.agents/harness/selftest/dispatch.sh
---

## Goal

`docs/product/defect-to-fix-loop.md`, clause 2, the control plane's half.
`defect-block-resumes` lets a manager park on a blocking defect (`next:` =
`defect: #<n>: …`). This plan makes dispatch and the orchestrator do three
things with that block:

- not treat it as a human's;
- resume the item once the fix is retired;
- reach the human only when nothing is fixing it.

## Scope

- **dispatch row**: `cmd_dispatch` and `analysis_one` print a `defect:`
  block as `PARKED #<n>`, a word unused by today's `WAIT` / `n_wait`. A
  PARKED item:
  - holds no slot, is not counted in `n_wait`, and leaves the verdict line
    unchanged. Parked items are listed on their own lines under the
    verdict, as the core-only wait is.
  - is `RESUME` when all three hold. Live rows are the only branch rows
    read (`dispatch_branch_plans` kind `live`), so a stale twin-clerk
    branch never holds an item:
    1. the commit that wrote this `next:` line is found;
    2. a plan whose `issue:` is `<n>` was deleted on the base branch's
       first parent after that commit, read with renames detected;
    3. no plan on the base branch, and no `live` branch row, names
       `issue: <n>` now.
  - is `PARKED #<n> UNPLANNED` when no plan has named `<n>` within
    `JOHARNESS_DEFECT_PLAN_HOURS` (new knob, default 48) of the block
    commit.
  - is `PARKED #<n> STUCK` when a plan named `<n>` but none retired within
    `JOHARNESS_DEFECT_FIX_HOURS` (new knob, default 72).
  - is `PARKED UNREADABLE` when the block commit is not found, and RESUME
    fails closed.
  - Both knobs get knob-table rows.
- **The verdict with a RESUME row** is never `DRAINED … exit`. A RESUME
  is work, and the run continues while a resumed item is in flight.
- **orchestrate.md** role table and **orchestrate-reference.md**:
  - `PARKED` → report only.
  - `UNPLANNED`, `STUCK`, `UNREADABLE` → notify once, as for a human block
    today.
  - `RESUME` → only when a slot is free under `JOHARNESS_MAX_MANAGERS`
    (otherwise wait for the next pass). Then the § Relay mechanics: write
    `status: in-progress` and `next:` = `Resume: the fix for #<n> merged
    (<retired plan>); re-run your Acceptance`, commit, push, respawn as
    Relay does (counted).
  - The "Never respawn a `blocked` item" line names RESUME as its one
    exception.
- **orchestrated.md** "The one stop": PARKED described.
- **Selftests** (`dispatch.sh`), each failing without the change:
  - PARKED is not counted in `n_wait`;
  - no RESUME while a live branch plan still names the issue;
  - RESUME despite a non-live (stale) branch naming it;
  - no RESUME for a rename;
  - no RESUME for a retirement older than the block commit;
  - RESUME after a fresh retirement;
  - UNPLANNED and STUCK at their knob hours;
  - UNREADABLE fails closed;
  - a pass with a RESUME row does not print `DRAINED`.

## Out of scope

- The manager's and the clerk's side (`defect-block-resumes`).
- Any GitHub API read from a harness command: issue state is never read.

## Acceptance

- `./joharness.sh ci`: `ci: pass`, the selftests listed, the knob rows
  declared.
- `./joharness.sh verify`: `0 failed`.
- `grep -n 'PARKED\|RESUME' .claude/commands/orchestrate.md`: the rows
  and the never-respawn exception are present.
- Consumer side, after the sync reaches chrsctl/gx: gx's `dispatch` prints
  a `defect:` block as `PARKED`.

## Where to look

- `joharness.sh:cmd_dispatch` (`n_wait`, `n_blocked`, the verdict branch,
  the core-only wait lines), `analysis_one`, `dispatch_branch_plans`, the
  knob table.
- `.claude/commands/orchestrate.md` (the status-blocked row, RUN END,
  Never), `.agents/docs/orchestrate-reference.md` § Relay.

## Traps

- RUN END matches the verdict text. Never append to the DRAINED line.
- RESUME reads git, never an issue's state.
