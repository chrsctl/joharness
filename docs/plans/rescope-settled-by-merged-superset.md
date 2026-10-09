---
plan: rescope-settled-by-merged-superset
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
scope: shared:joharness.sh, shared:.agents/harness/selftest/dispatch.sh, shared:.claude/commands/orchestrate.md
---

## Goal

Issue #300. `dispatch` printed `OVERLAP-BOUND` for a held plan. A surveyor
narrowed it, merged, and wrote the rest down: the remaining collision "is
genuine and stays serialized". Eight minutes after that merge, `dispatch`
asked for a SECOND surveyor on the same plan and the same file. The cause:
the rescope key is the HOLDER set. Two of three holders merged, so the key
changed, and the ledger's `rescoped=<key>` no longer matched. In code there
is a second cause: `rescope_settled` reads only UNMERGED rescope branches
(`dispatch_rescope_branches` skips merged refs), so a merged `done` rescope
settles nothing. A surveyor is beyond the cap, so a second one is the
human's money spent on a conclusion already on `main`.

## Scope

- `joharness.sh:cmd_dispatch`, the overlap-bound block:
  - In-flight rows: today `done | blocked` settles only when
    `rk = rescope_key`. Change it to: settles when the CURRENT holder set
    is a subset of `rk`'s holder set (split both on `+`). An equal key is
    a subset, so today's case still settles.
  - Merged rescopes: add a helper `dispatch_rescope_merged`. It lists
    retire commits on `origin/<base>` that DELETE a
    `docs/handover/rescope-*.md` file:
    `git log --diff-filter=D --name-only --format=%H origin/<base> -- docs/handover`.
    Do NOT use `--first-parent`: the file was added and deleted on the
    rescope's own branch, so only that branch's commits show the delete.
    For each, read the frontmatter at `<sha>^:<path>`. Identity is the
    in-flight scan's: `workstream: rescope-<key>`, `plan: none`. Keep only
    `status: done`. A `blocked` record is a human's, already reported, and
    is not this fix. Emit `<sha>\t<key>`.
  - A merged record settles the current key when BOTH hold:
    (a) the current holder set is a subset of the record's key; and
    (b) no held plan's file changed on `origin/<base>` since that commit:
    `git log --format=%H -1 <sha>..origin/<base> -- docs/plans/<held>.md`
    is empty for every held plan. A changed `scope:` line is new
    information and re-earns a rescope (#300 fix 3).
  - Run the helper ONLY inside the overlap-bound block, which runs only when
    `n_hold > 0`, slots are free, and nothing else is spawnable. It costs
    nothing on a normal pass.
  - The settled verdict's text is unchanged. It already says `a rescope for
    this key is done or blocked … the holds are genuine`. Add the merged
    record's sha to the `rescope :` block, one line:
    `            settled by merged rescope <short-sha> (key <key>): holds genuine`.
- `.claude/commands/orchestrate.md`, step 3, the `OVERLAP-BOUND` bullet:
  add one sentence. A ledger `rescoped=<K>` also covers any later key
  whose holders are all in K. A smaller holder set is the same collision
  with fewer holders.
- `.agents/harness/selftest/dispatch.sh`: fixtures, built as the real shape
  (rescope branch adds then deletes its workstream file, merged with a
  merge commit):
  - merged `done` rescope on key `a+b+c`, current holders `b` → settled,
    no spawn line;
  - the same, then a commit on `main` editing the held plan's file → NOT
    settled, spawn line printed;
  - merged `done` rescope on key `a+b`, current holders `b+d` → NOT settled.

## Out of scope

- Changing what the key IS, or the `rescope :` block's other lines.
- `blocked` merged rescopes.
- The surveyor's own role text (`.claude/commands/manage.md`, rescope).

## Acceptance

- `bash .agents/harness/selftest/dispatch.sh` → 0 failed, three fixtures included.
- Revert the `joharness.sh` change only. The first fixture FAILS (a spawn
  line prints). Restore it.
- `bash .agents/harness/selftest/perf.sh` → passes.
- `./joharness.sh ci` → `ci: pass`. `./joharness.sh verify` → `0 failed`.
- SHIPS: `joharness.sh` reaches consumers. The consumer check is
  `./joharness.sh dispatch` in a consumer after a surveyor merged `done`
  and one of its holders merged.

## Where to look

- `joharness.sh:cmd_dispatch` — `rescope_key`, `rescope_settled`, the
  `case "$rstat" in done | blocked)` line and its long comment (why ACTIVE
  ignores the key and SETTLED does not).
- `joharness.sh:dispatch_rescope_branches` — identity test and the stdin
  rule. Copy both.
- `.claude/commands/orchestrate.md:## 3. Spawn` — the `OVERLAP-BOUND` bullet.

## Traps

- The existing comment says why SETTLED is key-specific: "a done rescope on
  an OLD key must not settle a genuinely new holder set". A subset is not a
  new holder set. A set with a holder the record never saw IS new. The third
  fixture pins that.
- Process substitution, not `"$(...)"` read back through `<<<`. The comment
  in that block records the race.
- `stall-rows-say-what-git-knows`, `manager-ceiling-row` and
  `plan-on-a-branch-visible` edit the same function, suite and file. All
  `shared:`. Reconcile at step 7.
- Test written for the fix must fail without it.
