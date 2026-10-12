---
plan: retired-stems-ledger
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: 423
scope: shared:joharness.sh, shared:.claude/commands/manage.md, shared:.agents/docs/orchestrated.md, docs/plans/RETIRED.md, .agents/harness/selftest/retired-ledger.sh
---

## Goal

Issue #423, piece B. A manager that carries a branch plan and finds it already done writes `status: done, pr: none` and exits. The plan was never on main, so there is no delete to land, and the retire outcome lives only on a branch. `.agents/docs/orchestrated.md` ("A spawn the human orders carries the plan") names the hazard: when the owner's branch later merges, the retired plan comes BACK. The docs leave the cleanup to the owner at reconcile, and in `chrsctl/gx` the owner was gone every time. One plan (`kanban-board-drag-move-persist`) returned that way and held a slot plus a HOLD.

Make a retire that cannot delete still land on main, and make `ci` refuse to re-add a retired stem.

## Scope

- **The ledger.** Pick the record in `## Decisions` BEFORE code. The issue proposes `docs/plans/RETIRED.md`, one stem per line plus the retiring sha or PR. Check first:
  - it does not trip the plan lint (`lint_plans_in_diff`), the queue hook or `dispatch`, which all read `docs/plans/*.md` as plans;
  - if it would, either exclude it the way `TEMPLATE.md` or `README.md` are excluded, or place it elsewhere.
  
  Whatever file you pick must be greppable from git alone.
- **`.claude/commands/manage.md` Finish.** When `status: done` and the plan is not on main (a carry), the manager's last act is a plan-only pull request appending the stem to the ledger, merged under step 7.
- **`ci`** (`joharness.sh`). A diff that ADDS `docs/plans/<stem>.md` whose stem the base's ledger lists fails with `already retired by <ref>`. Removing the ledger line is the human override; say so in the message.
- **`.agents/docs/orchestrated.md`.** The "Hazard" sentence under "A spawn the human orders carries the plan" names the ledger, not the owner, as the guard.
- **`.agents/harness/selftest/retired-ledger.sh`** (new; register it). Cases:
  - a branch adding a ledgered stem → `ci` red with the message;
  - a branch adding an unledgered stem → no ledger finding;
  - the ledger file itself does not lint as a plan.
  
  The first case must FAIL on `origin/main`'s script; record it in `## Review`.

## Out of scope

- Backfilling past retires into the ledger. Only new retires write to it.
- `free` dropping DONE ON MAIN stems (plan `free-branch-plans`) and dispatch's DONE ON MAIN reading (plan `branch-plan-done-on-main`). They may later read the ledger; do not wire that here.
- Any change to protocol paths.

## Acceptance

- `.agents/harness/selftest.sh`: all green; the red-on-ledgered-stem case fails on `origin/main`'s script, as recorded in `## Review`.
- `./joharness.sh curate` and `./joharness.sh dispatch` on this repo do not list the ledger file as a plan.
- `./joharness.sh ci`: `ci: pass`. SHIPS: consumers' `ci` gains the check at the next sync.
- `./joharness.sh verify`: 0 failed.

## Where to look

- `joharness.sh:lint_plans_in_diff`: where an added plan is linted in `ci`.
- `joharness.sh:lint_stem`: stem identity.
- `.agents/harness/queue-context.sh:stem`: the queue's plan reader; check which files it skips.
- `.claude/commands/manage.md`: step 2 carry; Finish ("retire the plan file and workstream file").
- `.agents/docs/orchestrated.md`: "A plan the queue cannot see".

## Traps

- A test for a fix must FAIL without it.
- `joharness.sh` runs in every consumer: name no specific environment.
- Never skip, disable or quarantine a test to get green.
