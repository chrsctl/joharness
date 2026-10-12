---
plan: branch-plan-done-on-main
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: 423
scope: shared:joharness.sh, shared:.agents/harness/selftest/dispatch.sh, shared:.agents/docs/orchestrated.md
---

## Goal

Issue #423, piece C plus the age half of piece D. In consumer `chrsctl/gx`, 9 plans sat in dispatch's `plans on a branch` block for up to 32 days. By the time a human freed them, 3 of the 9 had already been built and retired on main through a carry. Dispatch cannot tell that today:

- `dispatch_branch_plans` marks a row `leftover` only when the base itself ADDED and then RETIRED the path (`git log --full-history -m --diff-filter=D` on the base).
- A carried plan retired on the carrier's own branch, with `status: done, pr: none` and no plan file ever reaching main, leaves no delete on the base. Its row therefore reads like a live plan.
- The row also carries no age, so 32 days and 32 minutes look the same.

Make each branch-plan row say whether main already finished the stem, and how long the branch has held it.

## Scope

- **`joharness.sh:dispatch_branch_plans`: DONE ON MAIN.** A stem counts as done on the base when ANY of these holds, read from git alone:
  1. the existing `leftover` test (the base added and retired the path);
  2. a workstream file on the base's history, or on any merged branch, names the stem in `plan:` with `status: done`. Reuse `cl_merged_claims` or `fb_edges` where they fit; do not write a third walker;
  3. a merged carry. The carry rule (`manage.md` step 2) says the carry PR body names the owner branch, but bodies are not in git. Use only what git holds, and record in the workstream file's `## Decisions` which git signal you chose and why.
  
  Print it as a distinct marker in the row, e.g. `DONE ON MAIN`. Keep the existing four-field rows' readers working: the fifth field already carries `leftover`. Extend that field and do not add a sixth unless a reader needs one.
- **Age.** Each branch-plan row carries `held Nd`, the days since the branch's tip commit. Use the same clock source `dispatch_age_min` uses.
- **`cmd_dispatch`**, where the block prints: show both markers. A DONE ON MAIN row says the human or `free` (plan `free-branch-plans`) should drop it, not spawn on it.
- **`.agents/docs/orchestrated.md`**, "A plan the queue cannot see": the table row "carried … built and retired" and the paragraph "Why the first row can fail, and why the reader cannot tell" must describe the new reading. One or two lines each.
- **`.agents/harness/selftest/dispatch.sh`.** Cases:
  - (a) a branch adds plan `p`; another branch carries `p`, its workstream file says `plan: p`, `status: done`, `pr: none`, and that carrier merges to main with no plan file. Expect the row to print DONE ON MAIN;
  - (b) the existing base-added-and-retired leftover still prints;
  - (c) a branch plan nothing finished prints neither marker and carries `held Nd`.
  
  Case (a) must FAIL on `origin/main`'s `joharness.sh` (`git checkout origin/main -- joharness.sh`, run the selftest, record the result in `## Review`, `git checkout HEAD -- joharness.sh`).

## Out of scope

- Author liveness (`author: RUNNING|gone`). Dispatch reads git only, and session state lives in the remote API (`/who`). Do not make dispatch call a network API.
- Acting on the row: freeing, dropping or spawning. That is plan `free-branch-plans`.
- The retired-stems ledger (plan `retired-stems-ledger`).
- Letting the orchestrator spawn on a branch plan. The rule in `orchestrate.md` "Report, every pass" stays.

## Acceptance

- `.agents/harness/selftest.sh`: all green; case (a) fails on `origin/main`'s script, as recorded in `## Review`.
- `./joharness.sh dispatch` on this repo prints, with no error, a `plans on a branch` block (or none).
- `./joharness.sh ci`: `ci: pass`. SHIPS: `ci` runs the selftest in every consumer after its next sync.
- `./joharness.sh verify`: 0 failed.

## Where to look

- `joharness.sh:dispatch_branch_plans`: the `retired` loop and the fifth `leftover` field.
- `joharness.sh:cl_merged_claims`: merged workstream files' `plan:` stems.
- `joharness.sh:dispatch_age_min`: the age clock.
- `joharness.sh:cmd_dispatch`: where `plans on a branch` prints.
- `.agents/docs/orchestrated.md`: "A plan the queue cannot see".
- `.claude/commands/manage.md`: step 2, "Carry the plan, never take the branch".

## Traps

- A test for a fix must FAIL without it.
- `joharness.sh` runs in every consumer: name no specific environment.
- Dispatch reads git only. No GitHub call.
- `drained-names-a-due-role` and `clerk-cycle-reads-what-a-clerk-leaves` also edit `cmd_dispatch`: a reconcile is expected at step 7.
