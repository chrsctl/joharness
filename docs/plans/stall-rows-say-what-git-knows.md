---
plan: stall-rows-say-what-git-knows
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
scope: shared:joharness.sh, shared:.agents/harness/selftest/dispatch.sh, shared:.claude/commands/orchestrate.md
---

## Goal

Issue #283. An orchestrator came back after an 18-day suspension.
`dispatch` reported three live managers as stalled for 434h. For two rows
it printed `respawn on the branch to FINISH it`. All three were RUNNING,
mid-step-7. Push age cannot tell a stopped fleet from dead managers: the
git view is frozen for both. Two rows also said `PR in flight` when no pull
request existed. `dispatch` is git-only and never read one. Fix the three
statements `dispatch` makes without evidence. Keep it a git-view tool.

## Scope

- `joharness.sh:cmd_dispatch`, retired-edge rows (`dispatch_retired_edges`
  consumer, the `edge_rows` text):
  - Row text `PR in flight, no claim file: step 7 retired …` becomes
    `retired, no claim file — a pull request is expected; this reader cannot see one: step 7 retired …`.
    Keep the rest of the sentence.
  - The STALL? edge row that names an item: cut the clause from
    `Gone — ARCHIVED, …` to the end. In its place:
    `the verdict is the health table's (.claude/commands/orchestrate.md, step 2), never this row's`.
    The row keeps `cross-check the control plane by TITLE (manager: <stem>)`.
- `joharness.sh:cmd_dispatch`, one new line after the verdict's tail lines.
  It prints only when ALL hold:
  - `n_stall` > 0;
  - every in-flight row that is not BLOCKED is a STALL? row
    (`n_stall` = `n_inflight` − `n_blocked`);
  - the newest commit on `origin/<base>` (`git log -1 --format=%ct`) is
    older than 24 stall windows (`stall * 24`, the multiple the leftovers
    rule in the same function already uses). Not 1x: with one manager in
    flight, `main` moves only when it merges, so a 1x test would fire on
    every ordinary stall. #283 option 3 asks for "some large multiple".

  Line: `            every manager in flight is silent and <base> has not moved in <age>: suspect a stopped fleet (a suspension), not <n> dead managers — read the control plane for EACH before any respawn`.
  One `git log -1` call, made only when the first two conditions hold.
- `.claude/commands/orchestrate.md`, step 2 health table:
  - The row keyed on `` row says `PR in flight, no claim file` `` must
    match the new text. Key it on `retired, no claim file`.
  - One sentence under the table: the stopped-fleet line decides nothing.
    It says push age is the fleet's, not the manager's. Read the control
    plane for each row, and let the table's rows decide as written.
- `.agents/harness/selftest/dispatch.sh`:
  - update the `expect` `"which says what the row is"` to the new text;
  - update the `expect` `"naming the respawn as the merge, not a restart"`
    (needle `respawn on the branch to FINISH it, never to restart the item`).
    This plan removes that text. Repoint it at the new clause
    `the verdict is the health table's`;
  - add a `refute` that no edge row prints `respawn on the branch`;
  - add one fixture: one claimed branch past the stall window, `main`'s
    newest commit older than the window → the stopped-fleet line prints;
  - add a second fixture: the same, with a fresh commit on `main` → the
    line does not print.

## Out of scope

- Reading GitHub (pull requests, checks) from `joharness.sh`. It stays
  git-only (#283: "Nothing here argues for widening what dispatch reads").
- `cost_usd` as a liveness discriminator, or a time floor on it (#283
  option 2, #298 item 3). `orchestrate.md`'s field table records a RUNNING
  manager frozen on EVERY field, cost included, for 172.273s, and #283's
  own comment records live managers with cost frozen 19–31 minutes. The
  measurements disagree on what cost proves. That is a research question,
  not a rule to write here. Name it in the PR body.
- Claimed (non-edge) STALL? rows. They already say only
  `cross-check the control plane`.
- Any change to `JOHARNESS_STALL_MINUTES` or what counts as a stall.

## Acceptance

- `bash .agents/harness/selftest/dispatch.sh` → 0 failed, new fixtures included.
- Revert the `joharness.sh` change only. The stopped-fleet fixture and the
  updated `expect` FAIL. Restore it.
- `grep -c "PR in flight" joharness.sh .claude/commands/orchestrate.md .agents/harness/selftest/dispatch.sh` → `0` in each.
- `grep -n "respawn on the branch to FINISH it" joharness.sh` → no output.
- `./joharness.sh dispatch` in this repo → runs, verdict line present.
- `./joharness.sh ci` → `ci: pass`. `./joharness.sh verify` → `0 failed`.
- SHIPS: `joharness.sh` and `.claude/commands/` reach consumers. The
  consumer check is `./joharness.sh dispatch` in a consumer with a
  retired-edge row: the row says `retired, no claim file`.

## Where to look

- `joharness.sh:cmd_dispatch` — the `edge_rows` assignments (grep
  `PR in flight` and `respawn on the branch to FINISH`), the verdict block,
  the tail lines after it (`past the stall window: health pass FIRST`).
- `joharness.sh:dispatch_retired_edges` — what makes a row an edge row.
- `.claude/commands/orchestrate.md:## 2. Health pass — before any spawn` —
  the row `at step 7, merging. Nothing.` and the row `gone at the edge.
  RESPAWN on that branch to FINISH the merge`. The second row keeps the
  respawn instruction. It is the health table's verdict, which is where it
  belongs.
- `.agents/harness/selftest/dispatch.sh` — `"which says what the row is"`.

## Traps

- `orchestrate.md`'s table matches on dispatch's row text. Change both in
  the SAME commit, or a pass between them matches no row.
- `manager-ceiling-row`, `rescope-settled-by-merged-superset` and
  `plan-on-a-branch-visible` also edit `cmd_dispatch`,
  `.agents/harness/selftest/dispatch.sh` and `orchestrate.md`. All mark
  them `shared:`. Reconcile at step 7.
- Every inner git in a ref walk reads `</dev/null`
  (`dispatch_rescope_branches`' comment says why).
- Test written for the fix must fail without it.
