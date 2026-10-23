---
plan: defect-block-resumes
urgency: normal
agent: opus
effort: high
needs: none
requirement: defect-to-fix-loop
issue: none
scope: shared:joharness.sh, shared:.claude/commands/manage.md, .agents/docs/manage-reference.md, shared:.agents/docs/feedback.md, shared:.claude/commands/clerk.md, shared:.claude/commands/orchestrate.md, shared:.agents/docs/orchestrated.md, shared:.agents/docs/orchestrate-reference.md, shared:.agents/harness/selftest/dispatch.sh
---

## Goal

`docs/product/defect-to-fix-loop.md`, clause 1. A manager blocked by an
agent-fixable defect outside its plan's scope can do one of two things
today. § Defect (`.agents/docs/manage-reference.md`) files the issue with
`human-review` and says never block. A human reason (manage.md §3) blocks
and notifies. Neither gets the defect fixed without a human. The requester
decided on 2026-10-23 that a **blocking** defect skips the hold:

- *Blocking* means the item cannot meet its own Acceptance while the defect
  stands. Example: the plan must show a suite green and the suite is red on
  the base branch for a reason outside the plan's scope.
- A blocking defect is filed without `human-review`, the clerk plans it
  urgent, and the item resumes when the fix merges.
- Every other defect keeps § Defect unchanged.

## Scope

- **manage-reference.md § Defect**: a step before step 3. Does this defect
  stop your item meeting its Acceptance?
  - **No:** steps 3–5 as today.
  - **Yes:** file the issue as step 3 does but with NO labels, then push
    `status: blocked`, `next:` = `defect: #<n>: <one line>`, and exit.
  - `issue_write` fails: block with `github: defect not filed: <error>`,
    issue text under `## Blockers`. A human reason, today's path.
  - The closing sentence ("The label holds the issue…") applies to
    non-blocking defects only.
- **manage.md §3**: `defect:` named beside the human reasons as the one
  reason that is not a human's. The "Before pushing `status: blocked`, apply
  `human-review`" sentence does not apply to a `defect:` block: no label on
  the pull request, none on the plan's issue.
- **feedback.md** § "Where a consumer's OWN findings go": the "held by
  `human-review`" line gets the same split.
- **`joharness.sh:block_reason_ok`** accepts `defect:`. `cmd_dispatch` and
  `analysis_one` print a `defect:` block as `PARKED #<n>`. `PARKED`
  avoids the existing `WAIT` / `n_wait`. A PARKED item:
  - holds no slot, is not counted in `n_wait`, and does not stop DRAINED.
    The DRAINED line names the parked items.
  - prints `RESUME` when BOTH hold:
    1. a plan whose `issue:` is `<n>` was deleted on the base branch's
       first parent AFTER the commit that wrote this `next:` line. Read
       with renames detected, so a rename is not a retirement.
    2. no plan on the base branch, and none on an unmerged branch
       (`dispatch_branch_plans`), names `issue: <n>` now.
  - prints `PARKED #<n> UNPLANNED` when no plan has named `<n>` within
    `JOHARNESS_DEFECT_PLAN_HOURS` (new knob, default 48, knob table row) of
    the block commit. A clerk verdict that plans nothing (HUMAN, DUPLICATE,
    DOES NOT HOLD) ends here.
- **orchestrate.md** role table and **orchestrate-reference.md**:
  - `PARKED` → report only: no notify, no respawn.
  - `PARKED … UNPLANNED` → notify once, as for a human block today.
  - `RESUME` → the § Relay mechanics: write `status: in-progress` and
    `next:` = `Resume: the fix for #<n> merged (<retired plan>); re-run
    your Acceptance`, commit, push, then respawn as Relay does (counted).
  - The "Never respawn a `blocked` item" line names RESUME as its one
    exception.
- **orchestrated.md** "The one stop": the reason list gains `defect`, and
  `PARKED` is described.
- **clerk.md §3**: an issue titled `defect:` with no `human-review` is
  planned `urgency: urgent`. Author gate and scout gate unchanged.
- **Selftests** (`.agents/harness/selftest/dispatch.sh`), each failing
  without the change:
  - `block_reason_ok` accepts `defect:`;
  - PARKED, not counted in `n_wait`;
  - no RESUME while a second plan still names the issue;
  - no RESUME for a rename;
  - no RESUME for a retirement older than the block commit;
  - RESUME after a fresh retirement with no plan left naming it;
  - UNPLANNED after the knob's hours.

## Out of scope

- Fixing the defect from the blocked manager's session (one item per
  session).
- Any GitHub API read from a harness command.
- The escape analysis (`defect-escape-acceptance`).
- Lifting the hold on non-blocking defects: the requester declined that.

## Acceptance

- `./joharness.sh ci`: `ci: pass`, with the selftests above listed.
- `./joharness.sh verify`: `0 failed`.
- `grep -n 'defect' .claude/commands/orchestrate.md`: PARKED, UNPLANNED
  and RESUME rows present, and the never-respawn line names RESUME.
- Consumer side, after the sync reaches chrsctl/gx: `./joharness.sh
  dispatch` there prints a `defect:` block as `PARKED`. gx's `run-all.sh`
  and `./joharness.sh ci` stay green.

## Where to look

- `.agents/docs/manage-reference.md` § Defect,
  `.agents/docs/feedback.md` § "Where a consumer's OWN findings go".
- `joharness.sh:block_reason_ok`, `cmd_dispatch` (`n_wait`, DRAINED),
  `analysis_one`, `dispatch_branch_plans`.
- `.claude/commands/orchestrate.md` (the status-blocked row, Never),
  `.agents/docs/orchestrate-reference.md` § Relay.

## Traps

- A `defect:` block never carries `human-review`, on its issue or its pull
  request. On resume, manage.md §4 reads the label and would re-block.
- RESUME reads git, never an issue's state.
