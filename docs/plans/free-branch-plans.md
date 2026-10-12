---
plan: free-branch-plans
urgency: normal
agent: opus
effort: xhigh
needs: branch-plan-done-on-main
requirement: none
issue: 423
scope: shared:joharness.sh, .agents/harness/selftest/free.sh, shared:.agents/harness/selftest/janitor.sh, shared:.claude/commands/orchestrate.md, shared:.claude/commands/manage.md, shared:.agents/docs/orchestrated.md
---

## Goal

Issue #423, piece A plus the closer half of piece D. A plan filed on a branch whose author is gone never reaches the queue. `.agents/docs/orchestrated.md` lists "author gone" as "not answered — accepted gap". In `chrsctl/gx` that gap held 9 plans for up to 32 days, until a human typed "Free Plans". Getting a plan file onto main so the queue's own lint and `curate` can review it is a copy task. It is not a build, and the rule "never spawn on a branch plan" stays correct.

A second shape never closes either: an `edge work` branch whose only diff is a workstream file with `status: done, pr: none`. Dispatch prints it as "done and unmerged" forever, and it holds a slot.

Give both shapes a mechanical path to main.

## Scope

- **`joharness.sh free <branch>...`**, janitor-class and plan-only. Preconditions it checks itself, refusing with a reason otherwise:
  - the branch is unmerged;
  - its diff against the merge base touches only `docs/plans/`, `docs/product/`, `docs/research/`, `docs/findings/`, `docs/handover/`, `MANIFEST.md`, `docs/INDEX.md`;
  - its tip is older than `HANDOVER_STALE_SECONDS`. That is git's proxy for "author gone"; the caller still proves the session gone, as for `janitor --apply`.
  
  Then, on a new branch cut from fresh `origin/main`:
  - merge the owner branch with `--no-edit` (never take the owner's branch, never push to it);
  - delete every `docs/handover/*` it adds;
  - drop every added plan stem that `branch-plan-done-on-main`'s check reads as DONE ON MAIN;
  - run `curate --apply`, then `ci`;
  - push.
  
  It prints the `git show <sha>:<path>` lines that recover what it dropped, for the PR body.
- **The empty done branch.** A branch whose only diff is a workstream file reading `status: done, pr: none` qualifies for the same `free`. The result is a branch from main that merges it and deletes the file, which closes it. Make `janitor --apply` either call this path for such branches or print them for `free`; record which in `## Decisions`.
- **Who runs it.** Settle and record in `## Decisions` BEFORE code. Recommended: dispatch prints a `FREEABLE` verb on such rows and spawns a manager item `free <branch>`, the same pattern as `rescope <key>`. The manager runs `free`, opens the pull request and merges it under Loop step 7, so the orchestrator's "Never: merge a pull request" stays intact. Rejected unless you show otherwise: the orchestrator committing itself, because orchestrate.md lets it write only KILL/LOOP records.
- **`.claude/commands/orchestrate.md`** and **`.claude/commands/manage.md`**: the FREEABLE row and the `free <branch>` item kind, a few lines each.
- **`.agents/docs/orchestrated.md`**: replace the "author gone | not answered — accepted gap" row with the answer.
- **`.agents/harness/selftest/free.sh`** (new; register it wherever selftests register). Cases:
  - a stale plan-only branch frees: its plans are on the new branch and its workstream file is gone;
  - a branch touching a non-doc path is refused;
  - a fresh branch is refused;
  - a DONE ON MAIN stem is dropped;
  - an empty done branch closes.
  
  Add a janitor case in `.agents/harness/selftest/janitor.sh` if janitor changes.

## Out of scope

- Opening or merging the pull request from inside `free`. The script reads and writes git; GitHub belongs to the session.
- `JOHARNESS_PLAN_AUTOMERGE` or any conf switch. A conf line is the human's call, and `joharness.conf` is a core path.
- Spawning on a branch plan to BUILD it.
- The auto-mode classifier refusing `finish` (#423 point 5). That lives in the session environment, not in the harness.

## Acceptance

- `.agents/harness/selftest.sh`: all green, including the new `free.sh` cases.
- `./joharness.sh free` with no argument prints usage and exits non-zero. `./joharness.sh free <merged branch>` refuses.
- `grep -n "accepted gap" .agents/docs/orchestrated.md`: no hit on the author-gone row.
- `./joharness.sh ci`: `ci: pass`. SHIPS: consumers' `ci` runs the selftest.
- `./joharness.sh verify`: 0 failed.

## Where to look

- `joharness.sh:janitor_apply`, `joharness.sh:janitor_candidates`, `joharness.sh:cmd_janitor`: the precedent for a session-less mechanical repair.
- `joharness.sh:dispatch_branch_plans`: the rows `free` acts on.
- `joharness.sh:cmd_curate`: `--apply`.
- `.claude/commands/orchestrate.md`: "Report, every pass", the role table (`rescope <key>` row), "Never".
- `.claude/commands/manage.md`: step 2 carry, step 3 item kinds.
- `.agents/docs/orchestrated.md`: "A plan the queue cannot see".

## Traps

- Never `push -f`, never `checkout -B` over a pushed branch, never push to the owner's branch.
- Never delete branches (`git push --delete` is human-only). Closing means merged, not deleted.
- A test for a fix must FAIL without it.
- Protocol paths (`./joharness.sh protocol-paths`) are never touched.
- `joharness.sh` runs in every consumer: name no specific environment.
