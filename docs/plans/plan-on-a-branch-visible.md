---
plan: plan-on-a-branch-visible
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
scope: shared:joharness.sh, shared:.agents/harness/selftest/dispatch.sh, shared:.claude/commands/orchestrate.md, shared:.claude/commands/manage.md
---

## Goal

Issue #297 and its comment. `dispatch` reads `docs/plans/` on the base
branch only. A plan on an open pull request branch has no row: not free,
not held, not in flight. In a consumer, an `urgent`, `effort: low` fix for
a red `main` sat on a plan-only PR for 6h09m. The orchestrator could only
write "merge PR #469 — human's" each pass. An hour later a second plan,
riding on a product PR, caused a duplicate spawn for the same failure,
because the orchestrator could not see the plan. Make the plan visible,
and make the filer merge its own plan-only PR.

## Scope

- `joharness.sh` — new helper `dispatch_branch_plans`. Walk unmerged
  `origin/*` refs, the same walk as `dispatch_rescope_branches`. For each,
  list `docs/plans/*.md` files ADDED in the net diff against the merge base
  (`--diff-filter=A`) and absent from `origin/<base>`. Drop a plan that the
  same branch's own workstream file names in `plan:`: that plan is the
  branch's own same-session plan, already in flight. Read each plan's
  `urgency` and `agent` at the branch (`git show <ref>:<path>`, `gr_fields`).
  Sanitise every field with `tr -cd`, like the other walks. Emit
  `<branch>\t<stem>\t<urgency>\t<agent>`.
- `joharness.sh:cmd_dispatch` — print the rows as a block after the spawn
  list, before the verdict:
  ```
  plans on a branch, not in the queue until it merges:
    <stem> (urgency: <u>, agent: <a>)  on <branch>
  ```
  An `urgent` row starts with `URGENT `. Print nothing when there are no
  rows. These rows are never free, never counted, and never change the
  verdict or `n_free`.
- `.claude/commands/orchestrate.md`, `## Report, every pass`: one bullet.
  Print the `plans on a branch` block. An `URGENT` row is the report's
  FIRST line, with its branch: the human merges it, or tells you to spawn
  on it. Never spawn on a branch plan on your own: the plan has not been
  reviewed into the queue.
- `.claude/commands/manage.md`, `## 4. Finish`: one sentence. A follow-up
  plan you filed as its own plan-only pull request is your own pull
  request. Drive it to merged before you exit (`./joharness.sh ci` green,
  `./joharness.sh finish` green). A plan-only diff changes only the queue.
- `.agents/harness/selftest/dispatch.sh` — fixtures:
  - unmerged branch adding `docs/plans/x.md` (`urgency: urgent`), no
    workstream file → block lists `URGENT x`; the verdict and the free count
    equal the same fixture without the branch;
  - a manager branch whose workstream file says `plan: y` and which adds
    `docs/plans/y.md` → `y` is NOT listed.

## Out of scope

- Spawning from a PR branch (#297 option 3). That is an orchestrator acting
  on an unreviewed plan, and it is the human's call. The report asks.
- Reading GitHub pull requests. A branch IS what git can see. The block
  says "on a branch", never "on a PR".
- `.agents/harness/queue-context.sh` and the session-start queue view.
  `dispatch` is the orchestrator's read. The hook is a different reader.

## Acceptance

- `bash .agents/harness/selftest/dispatch.sh` → 0 failed, both fixtures included.
- Revert the `joharness.sh` change only. The first fixture FAILS. Restore it.
- `./joharness.sh dispatch` in this repo → runs. Any branch carrying a new
  plan shows up in the block. Check one by hand:
  `git diff --name-only --diff-filter=A $(git merge-base origin/main origin/<branch>) origin/<branch> -- docs/plans`.
- `bash .agents/harness/selftest/perf.sh` → passes.
- `./joharness.sh ci` → `ci: pass`. `./joharness.sh verify` → `0 failed`.
- SHIPS: `joharness.sh` and `.claude/commands/` reach consumers. The
  consumer check is `./joharness.sh dispatch` in a consumer with an open
  plan-only PR branch.

## Where to look

- `joharness.sh:dispatch_rescope_branches` — the ref walk, the stdin rule,
  the net-diff filter. Copy it.
- `joharness.sh:cmd_dispatch` — the spawn-list printf and the verdict block.
- `.claude/commands/orchestrate.md:## Report, every pass`.
- `.claude/commands/manage.md:## 4. Finish`.
- `docs/plans/issue-triager-role.md` — its triager also merges its own
  plan-only PR. Same rule, a different role. No conflict.

## Traps

- A manager branch carrying its own same-session plan is the normal shape,
  not a hidden plan. Key the exclusion on the branch's own workstream
  `plan:`, read at the branch, never at the base.
- Diff, never tree: a branch inherits every plan the base carries
  (`.agents/harness/AGENTS.md` step 4).
- `stall-rows-say-what-git-knows`, `manager-ceiling-row`,
  `rescope-settled-by-merged-superset`, `role-files-say-it-first`,
  `ledger-losses-named`, `orchestrated-only` and `issue-triager-role` touch
  the same files. All `shared:`. Reconcile at step 7.
- Test written for the fix must fail without it.
