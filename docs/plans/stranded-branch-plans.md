---
plan: stranded-branch-plans
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: shared:joharness.sh, shared:.claude/commands/orchestrator.md, shared:.agents/docs/orchestrated.md, .agents/harness/selftest/dispatch-branch-plans.sh
---

## Goal

A plan file filed on a branch that never opened a pull request has no
owner: dispatch lists it under `plans on a branch` ("visible, counted
nowhere"), the orchestrator only prints the block, the clerk reads other
branches only to skip their issues, and no manager takes it. The
`release   : <branch>  no claim:` line (`release_noclaim_rows`) reports a
never-claimed docs-only branch only past `HANDOVER_STALE_SECONDS` (6 days
from its last push) and notifies nobody; the mark below is the earlier,
plan-age clock on the plans block, and the one the orchestrator notifies on. On chrsctl/gx four plans sat 3 days on two
`claude/*` branches (one commit each, no PR) until a human noticed. Worse,
the clerk skips any issue a branch plan's `issue:` names, so a stranded plan
also blocks the clerk from re-planning its issue. Keep the human as the only
one who lets a branch plan into the queue, but make sure the human is told.

## Scope

- `joharness.sh:dispatch_branch_plans` and its printer — a `live` row whose
  branch adds only files under `docs/plans/` (nothing else in the diff
  against its merge base), never added a workstream file under
  `docs/handover/` since its merge base (`log --diff-filter=A`, as
  `release_noclaim_rows` reads it: an edge that retired its claim is
  driven), and whose held days are at least
  `JOHARNESS_STRANDED_DAYS` (new knob, default 2; 0 = off) gets the mark
  `STRANDED <n>d`, a suffix after `held <n>d`. A printed line (one per
  stem) carries it when any of its branches is stranded, `<n>` the largest
  held days among those, and names those branches (`STRANDED <n>d on
  <branch>`). The verdict block counts the marked lines: `<k> stranded branch plan(s): a human carries or closes them`.
- `joharness.sh` knob table — declare `JOHARNESS_STRANDED_DAYS` the way
  `JOHARNESS_EDGE_SLOT_HOURS` is declared (scope `dispatch`), plus its row
  in `.agents/docs/orchestrated.md`'s knob table (`knobs-declared.sh`).
- `.claude/commands/orchestrator.md` — one sentence after the Report
  paragraph naming the `plans on a branch` block: a `STRANDED` row =
  `PushNotification` once carrying branch, stems and held days; ledger
  entry `bp:<branch> notified=bp:<branch>` (a branch, never an item: no
  head, no spawn), added to the ledger grammar; else report only. Never
  spawn on it, never edit the branch.
- `.agents/docs/orchestrated.md` — "A plan the queue cannot see" table: a
  fourth row, `plan-only branch, no pull request, no workstream file` →
  `STRANDED` mark, human notified once.
- `.agents/harness/selftest/dispatch-branch-plans.sh` — cases: a plan-only
  branch with no workstream file held 3 days → `STRANDED 3d`; the same held
  1 day → no mark; a branch with a workstream file or with a non-plan file →
  no mark; knob 0 → no mark.

## Assumptions

- A1: held days are already computed per row — evidence:
  `joharness.sh:dispatch_branch_plans` header comment (`<held days>`) —
  confidence: high
- A2: the branch's own workstream files are already read in that function
  (`own`, `wfs`) — confidence: high
- A3: dispatch cannot see pull requests, so "no workstream file + only plan
  files" is the git-only proxy for "nobody is driving it" — evidence:
  `.agents/docs/orchestrated.md` "the scheduler cannot see a pull request"
  — confidence: high
- A4: adding a knob needs the knob-declared selftest to pass — evidence:
  `.agents/harness/selftest/knobs-declared.sh` — confidence: medium

## Out of scope

- Letting the clerk, dispatch or any role carry, merge or queue a branch
  plan on its own: a branch must never authorise itself into the queue.
- Changing the clerk's `planned` skip.
- Editing `joharness.conf` (core path): the knob default lives in
  `joharness.sh`.

## Acceptance

- `./joharness.sh ci` — `ci: pass`; the 3-day case FAILS on `origin/main`
  without the change: the branch's selftest run with `origin/main`'s
  `joharness.sh` reds `a plan-only branch with no workstream file held 3
  days is STRANDED`.
- `./joharness.sh verify` — `0 failed`.
- `./joharness.sh dispatch` on this repo — a `STRANDED <n>d` mark on
  exactly the rows whose branch is plan-only, never claimed and held past
  the knob (at filing: `plan/core-only-spawns-manager`, held 13d); paste
  the block in the PR body. Failure: a mark on a claimed or code-carrying
  branch, or none on that one.

## Where to look

- `joharness.sh:dispatch_branch_plans` — the reader.
- `joharness.sh:plans on a branch, not in the queue until it merges` — the printer.
- `.agents/docs/orchestrated.md:A plan the queue cannot see` — the table.
- `.agents/docs/orchestrator-reference.md:The \`URGENT\` row` — the report rule.
- `.claude/commands/clerk.md:any unmerged branch` — why stranding blocks the clerk.

## Traps

- NEVER skip, disable or quarantine a test to get green.
- Shares `joharness.sh`, `orchestrator.md` and `orchestrated.md` (its
  knob table) with `retired-edge-stall-window`, `orchestrator.md` with
  `heartbeat-read-cheaper`: reconcile, do not overwrite.
- Dispatch reads git only: no GitHub API from `joharness.sh`.
