---
plan: defect-block-resumes
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: defect-to-fix-loop
issue: none
scope: shared:joharness.sh, shared:.claude/commands/manage.md, .agents/docs/manage-reference.md, .agents/docs/feedback.md, shared:.claude/commands/clerk.md, shared:.agents/docs/orchestrated.md, shared:.agents/harness/selftest/dispatch.sh
---

## Goal

`docs/product/defect-to-fix-loop.md`, clause 2, the manager's half. A
manager blocked by an agent-fixable defect outside its plan's scope has two
paths today. § Defect (`.agents/docs/manage-reference.md`) files the issue
with `human-review` and says never block. A human reason (manage.md §3)
blocks and notifies. Neither gets the defect fixed without a human. The
requester decided on 2026-10-23 that a BLOCKING defect skips the hold:

- *Blocking* means the item cannot meet its own Acceptance while the defect
  stands.
- A blocking defect is filed without `human-review` and the clerk plans it
  urgent. `defect-resume` resumes the item.
- Every other defect keeps § Defect unchanged.

## Scope

- **manage-reference.md § Defect**: a branch after step 2. Does this defect
  stop your item meeting its Acceptance?
  - **No:** steps 3–5 as today.
  - **Yes, and step 2 found issue M:** park on M (below). If M carries
    `human-review`, say so in `next:`. `defect-resume`'s UNPLANNED row then
    reaches the human.
  - **Yes, nothing found:** file the issue as step 3 does, with NO labels,
    then park.
  - **Park** = `status: blocked`, `next:` = `defect: #<n>: <one line>`,
    push, exit.
  - `issue_write` fails: block with `github: defect not filed: <error>`,
    issue text under `## Blockers`. A human reason, today's path.
  - The closing sentence ("The label holds the issue…") applies to
    non-blocking defects only.
- **manage.md §3**: `defect:` named as the one block reason that is not a
  human's. The "apply `human-review`" sentence does not apply to it: no
  label on the pull request, none on the plan's issue.
- **feedback.md** § "Where a consumer's OWN findings go": the "held by
  `human-review`" line gets the same split.
- **`joharness.sh:block_reason_ok`** accepts `defect:`.
- **clerk.md §3**: an issue titled `defect:` without `human-review` is
  planned `urgency: urgent`. Author gate and scout gate unchanged.
- **orchestrated.md** "The one stop": the reason list gains `defect`.
- **Selftest** (`dispatch.sh`): `block_reason_ok` accepts `defect: #9: x`
  and dispatch prints no `INVALID BLOCK?` for it. It must fail without the
  change.

## Out of scope

- How dispatch shows, resumes or escalates a parked item
  (`defect-resume`). Until that merges, a `defect:` block reads as BLOCKED
  and notifies, which is today's behaviour and safe.
- Lifting the hold on non-blocking defects: the requester declined that.

## Acceptance

- `./joharness.sh ci`: `ci: pass`, the selftest listed.
- `./joharness.sh verify`: `0 failed`.
- `grep -n 'defect:' .agents/docs/manage-reference.md .claude/commands/manage.md .claude/commands/clerk.md`:
  the park step, the §3 exception and the urgent rule are present.
- Consumer side, after the sync reaches chrsctl/gx: gx's `./joharness.sh
  ci` stays green.

## Where to look

- `.agents/docs/manage-reference.md` § Defect,
  `.agents/docs/feedback.md` § "Where a consumer's OWN findings go".
- `.claude/commands/manage.md` §3–§4, `.claude/commands/clerk.md` §2–§3.
- `joharness.sh:block_reason_ok`.

## Traps

- A `defect:` block never carries `human-review`, on its issue or its pull
  request. On resume, manage.md §4 reads the label and would re-block.
