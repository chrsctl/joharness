---
workstream: cleanup-audit
status: review
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: cleanup-audit
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Spawn the verifier, fold the round into ## Review, then retire and open the PR.
---

## Goal

Four findings the verifier returned against `cleanup` in PR54's replay were
never checked against today's tree. Carry them: reproduce or close each with
evidence, fix the ones that survive, and leave a regression case per fix.

`cleanup --apply` is the subcommand that deletes tracked files, and the one
whose mistake removes a live claim.

## Decisions

- Running at opus against a `sonnet` plan. Escalation is allowed and
  downgrade is not; the reason is that three of the four findings turn on
  what a command does in a state nobody normally builds (detached HEAD, a
  failed `git rm`, an unpushed live claim), and building those states
  correctly is where a wrong reading gets recorded as a verdict.
- **All four verdicts: REPRODUCES.** The plan required a verdict per finding
  and no silence, so each was rebuilt from scratch on `main` at `f603f87`,
  2026-08-29, one state per scratch repo — not four states in one, which is
  how a stale probe reads as a fresh measurement.
  1. A `status: in-progress` file merged to `main`, no branch carrying it:
     reported `stale`, and `cleanup --apply` staged its deletion
     (`git status` after: `D  docs/handover/live-part2.md`). `status:` was
     read nowhere in the file.
  2. A leftover with local modifications: `git rm` refused, the run warned,
     then printed `none — the ritual ran` and exited **0**, with the file
     still on disk. Every counter missed it.
  3. `git rev-parse --abbrev-ref HEAD` prints the literal `HEAD` when
     detached. On branch `main` the base-branch warning fired once; detached
     at the same commit, zero times.
  4. The plans section tested `[ -f "${ROOT}/docs/plans/${p}.md" ]` under a
     heading that says `plans on <ref>`. Deleting the plan in the working
     tree only, with it still on `origin/main`, turned `ask
     docs/plans/keepme.md` into `none`.
- **Finding 2's fix changes an exit code, and that is deliberate.** Counting
  the failure stops the `none — the ritual ran` line, but a caller reading
  `$?` would still have seen success for work that did not happen.
  `--apply` now returns 1 when a removal was refused; the report-only path
  still exits 0, because nothing was attempted there so nothing failed.
  Checked before changing it: nothing in `ci` calls `cleanup`, so no gate
  turns red on this.
- **Finding 3's fix changes the warning's wording**, from "on the base
  branch" to "no branch to carry these deletions" — the condition is no
  longer "which branch is this" but "is there a branch at all". Two existing
  selftest assertions read that string: one would have gone red and the
  other, a `refute`, would have gone vacuously green. Both updated.

## Rejected

- **Widening `cl_inflight` to notice the unpushed part-2 session.** It is
  the shape that suggests itself for finding 1 and the plan names it as a
  Trap: `853f551` paid for that filter, and the tree-vs-diff rule graduated
  out of the class. `cl_inflight` answers "does an unmerged branch carry
  this", which is a different question from "does this file say it is
  finished". Reading `status:` off the ref answers the second one without
  touching the first.

## Review

(no round yet)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_cleanup` — all four live here or in what it calls.
- `joharness.sh:cl_inflight`, `decide_ref` — the two helpers the already-fixed
  findings landed in. `853f551` paid for `cl_inflight`'s filter; do not widen
  it (plan Traps).
- `.agents/docs/handover/README.md` — the `status:` values finding 1 turns on.
