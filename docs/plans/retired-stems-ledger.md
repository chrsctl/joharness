---
plan: retired-stems-ledger
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: 423
scope: shared:joharness.sh, shared:.agents/harness/queue-context.sh, shared:.claude/commands/manage.md, shared:.agents/docs/orchestrated.md, docs/plans/RETIRED.md, .agents/harness/selftest/retired-ledger.sh, shared:.agents/harness/selftest.sh
---

## Goal

Issue #423, piece B.

**The gap.** A manager that carries a branch plan and finds it already done writes `status: done, pr: none` and exits. The plan was never on main, so the manager has nothing to delete, and the retire outcome lives only on a branch.

**The hazard.** `.agents/docs/orchestrated.md` ("A spawn the human orders carries the plan") names it: when the owner's branch later merges, the retired plan comes BACK. The docs leave the cleanup to the owner at reconcile, but in consumer `chrsctl/gx` the owner was gone every time. One plan, `kanban-board-drag-move-persist`, came back that way and held a slot and a HOLD.

**The fix.** Make a retire that cannot delete still land on main, and make `ci` refuse to re-add a retired stem. Plan `branch-plan-done-on-main` reads this ledger next.

## Scope

- **The ledger is `docs/plans/RETIRED.md`.**
  - One line per stem: the stem, then the PR or commit that retired it. Settle the exact line shape in `## Decisions`.
  - **Every reader that walks `docs/plans/*.md` must skip it, the way it skips `TEMPLATE.md` and `README.md`.** Today each reader excludes only those, so `RETIRED.md` would read as a plan. Readers to change:
    - `joharness.sh`: `gr_docs`, `plans_in_diff`, `lint_nodes`, and the plan walk near `lint_stem`'s other callers;
    - `.agents/harness/queue-context.sh`: its plan globs.
  - `grep -n "TEMPLATE" joharness.sh .agents/harness/queue-context.sh` finds every site. Change all of them.
- **`.claude/commands/manage.md` §0, item 2 (the carry rule), and §4 Finish.**
  - When `status: done` and the plan is not on main (a carry), the manager's finish is a pull request that appends the stem to the ledger and deletes the workstream file.
  - It merges under Loop step 7.
- **`ci`, in `joharness.sh`.**
  - A diff that ADDS `docs/plans/<stem>.md` fails when the base's ledger lists that stem.
  - The message reads `already retired by <ref>`, and says that removing the ledger line is the human override.
- **`.agents/docs/orchestrated.md`.** The "Hazard" sentence under "A spawn the human orders carries the plan" names the ledger as the guard, not the owner.
- **`.agents/harness/selftest/retired-ledger.sh`.** New. Register it in `SELFTEST_TOPICS` in `.agents/harness/selftest.sh`; an unlisted topic is fatal. Cases:
  - **(a)** A branch adds a ledgered stem. Expect `ci` red with the message.
  - **(b)** A branch adds an unledgered stem. Expect no ledger finding.
  - **(c)** With `RETIRED.md` present, `dispatch`, the queue hook and the plan lint list it as no plan.
  
  Cases (a) and (c) must FAIL on `origin/main`'s scripts:
  1. Run `git checkout origin/main -- joharness.sh .agents/harness/queue-context.sh`.
  2. Run the selftest.
  3. Record the result in `## Review`.
  4. Restore with `git checkout HEAD -- joharness.sh .agents/harness/queue-context.sh`.

## Out of scope

- Backfilling past retires. Only new retires write to the ledger.
- Dispatch reading the ledger (plan `branch-plan-done-on-main`) and `free` acting on it (plan `free-branch-plans`).
- Any protocol path.

## Acceptance

- `.agents/harness/selftest.sh`: all green. Cases (a) and (c) fail on `origin/main`'s scripts, as recorded in `## Review`.
- `./joharness.sh curate` and `./joharness.sh dispatch` on this repo, with a one-line `RETIRED.md` present: neither lists `RETIRED` as a plan.
- `./joharness.sh ci`: `ci: pass`. SHIPS: every consumer's `ci` gains the check at its next sync.
- `./joharness.sh verify`: 0 failed.

## Where to look

- `joharness.sh:plans_in_diff` and `joharness.sh:lint_plans_in_diff`: where `ci` lints an added plan.
- `joharness.sh:gr_docs` and `joharness.sh:lint_nodes`: the plan walks that exclude `TEMPLATE|README`.
- `.agents/harness/queue-context.sh:stem`: the queue's plan identity.
- `.agents/harness/selftest.sh:SELFTEST_TOPICS`: where topics register.
- `.claude/commands/manage.md`: §0 item 2 (carry) and §4 Finish.
- `.agents/docs/orchestrated.md`: "A plan the queue cannot see".

## Traps

- A test for a fix must FAIL without it.
- `joharness.sh` runs in every consumer: name no specific environment.
- Never skip, disable or quarantine a test to get green.
