---
plan: branch-plan-done-on-main
urgency: normal
agent: opus
effort: high
needs: retired-stems-ledger
requirement: none
issue: 423
scope: shared:joharness.sh, shared:.agents/harness/selftest/dispatch.sh, shared:.agents/docs/orchestrated.md, shared:.agents/docs/plans/README.md
---

## Goal

Issue #423, piece C and the age half of piece D.

In consumer `chrsctl/gx`, 9 plans sat in dispatch's `plans on a branch` block for up to 32 days. When a human freed them, 3 were already done: one merged as a carry, two retired on branches that never merged.

Dispatch cannot see either case today:
- `dispatch_branch_plans` marks a row `leftover` only when the BASE added and then retired the path.
- A carry that wrote `status: done, pr: none` leaves no delete on the base, whether or not its branch merges.
- No row carries an age, so a plan held 32 days looks the same as one filed 32 minutes ago.

Make each branch-plan row say whether the stem is already done and how long it has been held.

## Scope

- **`joharness.sh:dispatch_branch_plans`: DONE ON MAIN.** A stem counts as done when ANY of the following holds, read from git alone:
  1. the existing `leftover` test;
  2. the base's ledger `docs/plans/RETIRED.md` lists the stem (plan `retired-stems-ledger`);
  3. a workstream file names the stem in `plan:` with `status: done`. It may sit on the base's history, on a merged branch, OR on an unmerged branch other than the row's own. The unmerged case is the retire-on-branch the issue measured twice.
- **Guard the "older plan of that name" case** (signals 2 and 3). The existing `leftover` test already applies it: evidence that is already reachable from the row branch's merge base belongs to an older plan that reused the stem, and counts for nothing.
- **Do not use `cl_merged_claims`.**
  - It returns `plan:` stems only, never `status:`.
  - It is capped at `FB_LIMIT` (`JOHARNESS_FEEDBACK_EDGES`, default 50) first-parent merges. That is fewer than one month of merges in this repo, which is the window this plan exists for.
  - Bound the walk by the row branch's merge base instead.
- **Age.** Each row carries `held Nd`: days since the branch's commit that ADDED the plan path (`git log --diff-filter=A`). The tip time is wrong because a branch merged up from main after filing would under-read.
- **Row shape.** `cmd_dispatch` routes rows by field count:
  - `awk -F'\t' 'NF == 4'` feeds the `plans on a branch` block;
  - `awk -F'\t' 'NF == 5'` feeds the leftover rows.
  
  Adding fields breaks both readers. Pick one shape: for example, a fixed six-field row with an explicit kind field, `live|leftover|done`. Change both readers to match, and record the shape in `## Decisions`.
  - A DONE ON MAIN row prints in the `plans on a branch` block with its marker and the advice "drop it, never spawn on it".
  - The existing leftover rows keep their current text.
- **`.agents/docs/orchestrated.md`**, "A plan the queue cannot see": update the carried row, and the paragraph "Why the first row can fail, and why the reader cannot tell", one or two lines each.
- **`.agents/docs/plans/README.md`**, "What identifies a plan": the `dispatch_branch_plans` bullet says the row is "compared against nothing". Correct it.
- **`.agents/harness/selftest/dispatch.sh`.** Cases:
  - **(a)** A carrier branch, unmerged, holds a workstream file with `plan: p`, `status: done`, `pr: none`. The owner branch's `p` row prints DONE ON MAIN.
  - **(b)** The same carrier, merged with no plan file: DONE ON MAIN.
  - **(c)** The stem is in the ledger: DONE ON MAIN.
  - **(d)** A done workstream file for `p` that is already in the row branch's merge base: NOT done.
  - **(e)** The existing base-added-and-retired leftover still prints its leftover text.
  - **(f)** A live plan prints `held Nd` and no marker.
  
  Cases (a), (b) and (c) must FAIL on `origin/main`'s `joharness.sh`. Prove it:
  1. Run `git checkout origin/main -- joharness.sh`.
  2. Run the selftest.
  3. Record the result in `## Review`.
  4. Restore with `git checkout HEAD -- joharness.sh`.

## Out of scope

- Author liveness (`author: RUNNING|gone`). Dispatch reads git only, and session state lives in the remote API (`/who`). No network call from dispatch.
- Acting on the row by freeing or dropping it. That is plan `free-branch-plans`.
- Letting the orchestrator spawn on a branch plan. The rule in `orchestrate.md` "Report, every pass" stays.

## Acceptance

- `.agents/harness/selftest.sh`: all green. Cases (a), (b) and (c) fail on `origin/main`'s script, as recorded in `## Review`.
- `./joharness.sh dispatch` on this repo exits 0, and every `plans on a branch` row carries `held`.
- `./joharness.sh ci`: `ci: pass`. SHIPS: every consumer's `ci` runs the selftest after its next sync.
- `./joharness.sh verify`: 0 failed.

## Where to look

- `joharness.sh:dispatch_branch_plans`: the `retired` loop, its merge-base guard, and the fifth field.
- `joharness.sh:cmd_dispatch`: the `NF == 4` and `NF == 5` readers of `dispatch_branch_plans`.
- `joharness.sh:dispatch_rescope_merged`: precedent for walking deleted workstream files with `--full-history -m`.
- `joharness.sh:cl_merged_claims`: why it does not fit (no `status:`, `FB_LIMIT` cap).
- `.agents/docs/orchestrated.md`: "A plan the queue cannot see".
- `.claude/commands/manage.md`: §0 item 2, the carry rule.

## Traps

- A test for a fix must FAIL without it.
- `joharness.sh` runs in every consumer: name no specific environment.
- Dispatch reads git only. No GitHub call.
- `drained-names-a-due-role` and `clerk-cycle-reads-what-a-clerk-leaves` also edit `cmd_dispatch`. `curate` reports `.agents/harness/selftest/dispatch.sh` as claimed exclusively by `drained-names-a-due-role` and `sampling-conduct-reviewer`. Expect a reconcile at step 7, and add selftest cases rather than rewriting existing ones.
