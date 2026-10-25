---
plan: one-release-command
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: shared:README.md, shared:joharness.sh, shared:.claude/commands/orchestrate.md, .claude/commands/manage.md, .agents/docs/manage-reference.md, shared:.agents/docs/orchestrated.md, shared:.agents/docs/orchestrate-reference.md, .agents/docs/handover/README.md, shared:.agents/harness/AGENTS.md, .agents/harness/handover-context.sh, shared:.agents/harness/selftest.sh, .agents/harness/selftest/janitor.sh, .agents/harness/selftest/halt.sh, .agents/harness/selftest/free.sh, .agents/harness/selftest/guard.sh, .agents/harness/selftest/dispatch.sh, .agents/harness/selftest/dispatch-branch-plans.sh, .agents/harness/selftest/dispatch-rescope.sh, .agents/harness/selftest/fast-lane.sh
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

- **`./joharness.sh release`, no argument: the report.** It prints every
  releasable branch, one per line:
  `release   : <branch>  <reason>  <detail>`. It takes over plain
  `janitor`'s report, keeping its per-claim detail: `holds:`, the session
  line, `pr:` exempt, and push age. Two reasons qualify:
  - `stale, session gone?`: janitor's test (`janitor_releasable` over
    `claim_branches`), including `plan: none`, fast-lane and branch-only
    plans. The caller still proves the session ARCHIVED or not found, as
    today.
  - `queue holds it by needs: <stem>`: today's `RELEASABLE` test.
- **`./joharness.sh release <branch>...`: the write.** It releases each
  branch the report lists, and refuses any other with the reason.
- **`./joharness.sh release --human <branch>...`: halt's path.** Any age,
  any status, `pr:` allowed, the edge-record restore, and the
  "already released" idempotence (exit 0 when the branch is gone on origin
  after guard).
- **Names that change:**
  - `halt <branch>` stays as an alias of `release --human`, because a human
    types it.
  - `janitor` and `janitor --apply` are removed.
  - The janitor report's leftovers and merged-still-standing sections move
    to `cleanup`'s report.
- **Commit subjects:**
  - `release: session gone` and `release: the queue holds <plan> by a
    needs: edge`;
  - `release: a human released the claim`, keeping halt's `next:` wording.
- **guard:** `guard release <branch> [--human] [--expect <sha>]`, where
  `--human` skips the `pr:` check, and `guard record <branch> [--expect
  <sha>]` for today's `kill`/`loop`. The other checks (not the base branch,
  live on origin, expected head) and the exit codes are unchanged.

**dispatch:**
- The `release   :` report lines replace the `janitor   :` line and the
  `RELEASABLE:` row flag.
- One tail line, `release DUE: <branches>`.
- The `freer DUE` and `FREEABLE` rows go.

**Removed:**

- `cmd_free`, `free_key`, `free_path_ok`, `free_owner_held`,
  `free_plan_claimed`, `dispatch_freeable` and `free_claimed_ever`.
- The `free-*` handling in rescope, the `n_freer` count, and the freer's
  terms in `role_will_spawn`.
- The freer's Lineup row and spawn-table row, and README.md's Freer row.
- manage.md's free route, manage-reference.md § Free (with its `ref §`
  pointer: `orchestrated.sh` pointer test), and
  `.agents/harness/selftest/free.sh`.

**Behaviour lost (record each in `## Decisions`). The freer never ran: no
merged `free-*` branch on origin/main.**

1. **A doc-only branch with a claim whose author left** is released, not
   merged. Its plans stay on the branch. The `release   :` line names them
   as `plans not landed: <stems>`, and a human re-files them.
2. **A `done` branch** (only diff: a `status: done, pr: none` workstream
   file) gains the release reason `done, no pull request`. Released, its
   plan is offered again, so the work is redone rather than landed.
3. **A doc-only branch with no claim** (a clerk branch that never opened
   its pull request) prints in the report as `no claim: plans not landed:
   <stems>`. Nothing is written: there is no claim to release, and deleting
   branches stays human-only.

**Docs:**

- Every janitor, halt, release, free and freer mention in orchestrate.md,
  orchestrated.md, orchestrate-reference.md (§GUARD, spawn table),
  handover/README.md, README.md, and the handover-context.sh comment.
- AGENTS.md: "orchestrate GUARD, janitor, halt, release" becomes
  "orchestrate GUARD, release".

**Tests:**

- Fold the janitor.sh and halt.sh cases into one release topic in the
  `selftest.sh` topic list. The report cases (`holds:`, `pr:` exempt,
  candidates) move to `./joharness.sh release` output.
- Rewrite the release, FREEABLE and janitor needles in dispatch.sh,
  dispatch-branch-plans.sh, dispatch-rescope.sh and fast-lane.sh.
- guard.sh keeps its cases, with the verbs renamed.

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
./joharness.sh dispatch | grep -c 'FREEABLE\|freer DUE\|^janitor   :\|RELEASABLE:'   # 0
./joharness.sh release --human no-such-branch; echo $?   # prints "no such branch on origin", 1
./joharness.sh halt no-such-branch; echo $?             # same output and exit as the line above
./joharness.sh ci       # ci: pass
./joharness.sh verify   # 0 failed
```

- Every janitor, halt and release case is kept under the new names. The
  report cases move to `release` with no argument. The pull request body
  states the counts before and after, and names each case removed with the
  behaviour it tested (`free`, freer).
- New cases, each failing on origin/main:
  - `release` refuses a stale claim that dispatch does not list;
  - `release --human` releases one at any age;
  - a stale `plan: none` claim is listed and released;
  - the report names `plans not landed:` for a doc-only branch, and `no
    claim:` for one without a workstream file;
  - a `done` branch is listed with `done, no pull request`;
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
