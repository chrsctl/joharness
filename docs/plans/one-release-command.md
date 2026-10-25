---
plan: one-release-command
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: joharness.sh, .claude/commands/orchestrate.md, .claude/commands/manage.md, .agents/docs/manage-reference.md, .agents/docs/orchestrated.md, .agents/docs/orchestrate-reference.md, .agents/docs/handover/README.md, .agents/harness/AGENTS.md, .agents/harness/handover-context.sh, .agents/harness/selftest.sh, .agents/harness/selftest/janitor.sh, .agents/harness/selftest/halt.sh, .agents/harness/selftest/free.sh, .agents/harness/selftest/guard.sh, .agents/harness/selftest/dispatch.sh, .agents/harness/selftest/dispatch-branch-plans.sh, .agents/harness/selftest/dispatch-rescope.sh, .agents/harness/selftest/fast-lane.sh
---

## Goal

The user asked to simplify the commands that unstick abandoned work.
Today:

- **`janitor --apply`** releases a stale claim whose session is gone.
- **`halt`** releases any claim on a human's order.
- **`release`** releases a parked claim that dispatch prints `RELEASABLE`.
- **`free`** merges a doc-only branch whose author is gone, run by a freer
  role that has never run.

The first three write the same thing through the same path: `guard`, a
`status: abandoned` commit from `release_rewrite`, and a lease push. They
differ only in who may ask and what makes a branch eligible. Make them ONE
command, and remove `free` and the freer role.

## Scope

**Interface (fixed here):**

- `./joharness.sh release <branch>...` releases each named claim that
  dispatch lists as releasable on this read. Otherwise it refuses with the
  reason. Two reasons qualify:
  - `stale, session gone`, which is janitor's eligibility. The caller still
    proves the session ARCHIVED or not found, as today.
  - `queue holds it by needs: <stem>`, which is today's `RELEASABLE`.
- `./joharness.sh release --human <branch>...` is halt's path: any age, any
  status, `pr:` allowed, the edge-record restore, and "already released"
  idempotence.
- `halt <branch>` stays as an alias of `release --human`, because a human
  types it. `janitor --apply` is removed. Plain `janitor` (report) is
  removed: its stale-claim rows already print in dispatch, and its
  leftovers and merged-still-standing sections move to `cleanup`'s report.
- Commit subjects become `release: <reason>`, and the `next:` text keeps
  `release_why`.
- `guard` verbs become `release` (checks `pr:` unless `--human`) and
  `record` (today's `kill` and `loop`, no `pr:` check). Its checks 1-4 and
  exit codes are unchanged.

**dispatch:** one row flag, `RELEASE: <reason>`, and one tail line,
`release DUE: <branches>`. These replace the `janitor   :` stale-claim line,
the `RELEASABLE:` flag and the `freer DUE` / `FREEABLE` rows.

**Removed:**

- `cmd_free`, `free_key`, `free_path_ok`, `free_owner_held`,
  `free_plan_claimed`, `dispatch_freeable`, `free_claimed_ever`;
- the `free-*` handling in rescope, and the `n_freer` count;
- the freer's Lineup row and spawn-table row;
- manage.md's free route and manage-reference.md § Free;
- `selftest/free.sh`.

Each manage-reference section must keep a `ref §` pointer, so drop
§ Free's pointer with it (`orchestrated.sh` pointer test).

**Accepted loss, record it in `## Decisions`:** a doc-only branch whose
author left now gets released, not merged. Its plans stay on the branch,
and dispatch's `RELEASE:` row names them: `plans not landed: <stems>`. A
human or the clerk re-files them. The freer never ran (no merged `free-*`
branch on origin/main).

**Docs:** every janitor, halt, release, free and freer mention in
orchestrate.md, orchestrated.md, orchestrate-reference.md (§GUARD, spawn
table), handover/README.md, AGENTS.md (`--force-with-lease` only in
"orchestrate GUARD, janitor, halt" becomes "orchestrate GUARD, release"),
and the handover-context.sh comment.

**Tests:** fold janitor.sh and halt.sh cases into one release topic
(`selftest.sh` topic list). Rewrite the release, FREEABLE and janitor
needles in dispatch.sh, dispatch-branch-plans.sh, dispatch-rescope.sh and
fast-lane.sh. guard.sh keeps its cases, with the verbs renamed.

## Assumptions

- A1: janitor, halt and release share `release_rewrite`, `release_why`,
  `cmd_guard` and a lease push — evidence: `joharness.sh:release_rewrite`,
  `joharness.sh:janitor_apply`, `joharness.sh:cmd_halt`,
  `joharness.sh:cmd_release` — confidence: high.
- A2: free is a merge on the caller's own branch, never a release —
  evidence: `joharness.sh:cmd_free` — confidence: high.
- A3: `guard kill|loop` have no in-script caller, only the orchestrator's
  records — evidence: `grep -n 'guard kill\|guard loop'
  .agents/docs/orchestrate-reference.md joharness.sh` — confidence: medium.
- A4: a role branch with no claim (e.g. `clerk-<date>-b`) is none of these
  commands' business. `JOHARNESS_CLERK_STALE_HOURS` (24) already stops it
  holding the clerk — evidence: `joharness.sh` KNOBS row — confidence: high.

## Out of scope

- Deleting branches: `git push --delete` stays human-only.
- Role branches with no claim (A4).
- Changing who proves a session gone (the orchestrator, by `/who`).
- Core paths.

## Acceptance

```bash
./joharness.sh help | grep -cE '^#?\s+(janitor|free) '   # 0
./joharness.sh dispatch | grep -c 'FREEABLE\|freer DUE\|^janitor   :'   # 0
./joharness.sh release --human no-such-branch; echo $?   # non-zero, names the branch as gone on origin
./joharness.sh halt no-such-branch; echo $?             # same output and exit as the line above
./joharness.sh ci       # ci: pass
./joharness.sh verify   # 0 failed
```

- Every janitor, halt and release behaviour case is kept under the new
  names, and its count is stated in the pull request body (before → after).
- New cases, each failing on origin/main:
  - `release` refuses a stale claim that dispatch does not list;
  - `release --human` releases one at any age;
  - `RELEASE:` names `plans not landed:` for a doc-only branch;
  - `halt` and `release --human` print the same output.
- Consumer side (SHIPS): after its next sync a consumer runs
  `./joharness.sh ci` → `ci: pass`.

## Where to look

- `joharness.sh:release_rewrite`, `joharness.sh:release_why`: the shared
  write.
- `joharness.sh:janitor_apply`, `joharness.sh:cmd_halt`,
  `joharness.sh:cmd_release`: the three releasers.
- `joharness.sh:cmd_guard`: checks 1-4.
- `joharness.sh:cmd_free`, `joharness.sh:dispatch_freeable`: what goes.
- `.agents/docs/orchestrate-reference.md:GUARD`: the orchestrator's use.

## Traps

- Pinned needles quote these commands' output in the test files listed in
  `scope:`. Rewrite each needle with its text; never skip one.
- Plan retro-audit-and-trace also edits joharness.sh and the orchestration
  docs. dispatch holds overlapping plans apart; reconcile by merge if both
  are open.
- Never skip, disable or quarantine a test to get green.
- Glossary lint bans `handover file`, `model tier`, `env layer`, `rescope
  manager`, `bare role title`.
