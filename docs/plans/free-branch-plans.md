---
plan: free-branch-plans
urgency: normal
agent: opus
effort: xhigh
needs: branch-plan-done-on-main
requirement: none
issue: 423
scope: shared:joharness.sh, .agents/harness/selftest/free.sh, shared:.agents/harness/selftest.sh, shared:.agents/harness/selftest/dispatch.sh, shared:.claude/commands/orchestrate.md, shared:.claude/commands/manage.md, shared:.agents/docs/orchestrated.md
---

## Goal

Issue #423, piece A plus the closer half of piece D.

**The plan nobody frees.** A plan filed on a branch whose author is gone never reaches the queue. `.agents/docs/orchestrated.md` lists "author gone" as "not answered — accepted gap". In `chrsctl/gx` that gap held 9 plans for up to 32 days, until a human typed "Free Plans".

Getting a plan file onto main, where the queue's lint and `curate` can review it, is a copy task. It is not a build. The rule "never spawn on a branch plan to build it" stays correct.

**The branch nobody closes.** An `edge work` branch whose only diff is a workstream file with `status: done, pr: none` never closes either. Dispatch prints it as "done and unmerged" forever, and it holds a slot.

Give both shapes a mechanical path to main, run by a manager under the existing rules.

## Scope

- **`joharness.sh free <branch>`.** It works on the CURRENT branch, which the manager has already cut from fresh `origin/main` and claimed. It cuts no second branch. Before acting, it refuses with a reason unless all of these hold:
  - the owner branch is unmerged;
  - its diff against the merge base touches only `docs/plans/`, `docs/product/`, `docs/research/` and `docs/handover/`. These are the harness's own doc trees; consumer-specific indexes are out of scope;
  - the current branch is 0 behind `origin/main`.
- **What `free` then does, in order:**
  1. Merge the owner branch with `--no-edit`. Never push to the owner's branch.
  2. Delete every `docs/handover/*` the owner branch adds. Keep the manager's own workstream file.
  3. Drop every added plan stem that `branch-plan-done-on-main` reads as DONE ON MAIN. That reading includes the ledger, so a retired stem never reaches `ci`'s ledger check.
  4. Run `curate --apply`, then `ci`.
- **When `free` fails.** A merge conflict, or `ci` still red after `curate --apply`, ends the run non-zero with the merge aborted or the tree reset, and nothing committed. The manager fixes it by hand, inside a plan-only diff, or blocks with `conflict:`.
- **When `free` succeeds.** It commits and prints the `git show <sha>:<path>` lines that recover every dropped file, for the PR body. It never pushes, opens or merges a PR: that is the manager's Loop step 7.
- **The empty done branch.** A branch whose only diff is a workstream file reading `status: done, pr: none` qualifies for the same `free`. The merge brings the file in, step 2 deletes it, and the owner branch becomes merged.
  - `janitor` is NOT changed. The orchestrator runs `janitor --apply` itself, and `orchestrate.md` "Never" forbids it from editing plans or committing.
- **Dispatch.**
  - A `plans on a branch` row whose plans are all live or DONE ON MAIN, on a branch passing the path check and older than `HANDOVER_STALE_SECONDS`, prints the verb `FREEABLE` and becomes a spawnable item `free <branch>`.
  - An empty done branch gets the same verb with no age wait. Its own `status: done` says the session finished.
  - Follow the `rescope <key>` pattern in the orchestrator's role table, at sonnet.
  - The orchestrator proves the owner's session is not RUNNING (`/who`) before spawning, as it does for `janitor`.
- **`.claude/commands/orchestrate.md`**: the FREEABLE row in the role table and "Report, every pass", a few lines.
- **`.claude/commands/manage.md`.**
  - §0 item 3: the `free <branch>` item kind.
  - §R's title "the one kind that edits OTHER plans" becomes accurate again. A free manager's `curate --apply` touches only the plans it brings in. Say so.
- **`.agents/docs/orchestrated.md`**: replace the "author gone | not answered — accepted gap" row with the answer.
- **`.agents/harness/selftest/free.sh`.** New. Register it in `SELFTEST_TOPICS` in `.agents/harness/selftest.sh`. Cases:
  - a stale plan-only branch frees: its plans are on the current branch and its workstream file is gone;
  - a non-doc path is refused;
  - a DONE ON MAIN stem, including a ledgered one, is dropped;
  - an empty done branch closes;
  - a merge conflict exits non-zero with the tree clean.
- **`.agents/harness/selftest/dispatch.sh`.** Two cases: a FREEABLE row, and a fresh plan branch that is not FREEABLE.

## Out of scope

- Opening or merging the PR from inside `free`. The script handles git; the session handles GitHub.
- `JOHARNESS_PLAN_AUTOMERGE` or any conf switch. A conf line is the human's call, and `joharness.conf` is a core path.
- Spawning on a branch plan to BUILD it.
- The auto-mode classifier refusing `finish` (#423 point 5). That is the session environment, not the harness.
- Consumer-specific index files the issue's consumer keeps (`MANIFEST.md`, `docs/INDEX.md`, `docs/findings/`). A branch touching them is refused. Widening the list is a later plan or a knob, and that is the human's call.

## Acceptance

- `.agents/harness/selftest.sh`: all green, including the new cases.
- `./joharness.sh free` with no argument prints usage and exits non-zero. `./joharness.sh free <merged branch>` refuses.
- `grep -n "accepted gap" .agents/docs/orchestrated.md`: no hit on the author-gone row.
- `./joharness.sh ci`: `ci: pass`. SHIPS: every consumer's `ci` runs the selftest.
- `./joharness.sh verify`: 0 failed.

## Where to look

- `joharness.sh:janitor_apply` and `joharness.sh:cmd_janitor`: the precedent for a mechanical repair, and its refusals.
- `joharness.sh:dispatch_branch_plans` and `joharness.sh:cmd_dispatch`: the rows and where the verbs print.
- `joharness.sh:cmd_curate`: `--apply`.
- `.claude/commands/orchestrate.md`: the role table's `rescope <key>` row, "Report, every pass", and "Never".
- `.claude/commands/manage.md`: §0 items 2 and 3, and §R.
- `.agents/docs/orchestrated.md`: "A plan the queue cannot see".

## Traps

- Never `push -f`, never `checkout -B` over a pushed branch, and never push to the owner's branch.
- Never delete branches (`git push --delete` is human-only). "Closing" means merged, not deleted.
- A test for a fix must FAIL without it.
- Protocol paths (`./joharness.sh protocol-paths`) are never touched.
- `joharness.sh` runs in every consumer: name no specific environment and no consumer's file layout.
