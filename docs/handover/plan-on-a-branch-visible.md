---
workstream: plan-on-a-branch-visible
status: in-progress
branch: claude/plan-on-a-branch-visible-x7k2
pr: none
plan: plan-on-a-branch-visible
issue: 297
session: https://claude.ai/code/session_011826jrSc2fYHWmqxniAGSN
agent: opus
updated: 2026-10-10
next: Read verifier findings into ## Review, merge origin/main (18 behind, shared files), ci, retire, PR
---

## Goal

Issue #297: `dispatch` reads `docs/plans/` on the base branch only, so a plan
riding on an unmerged branch is invisible to the orchestrator. Print such
plans in a block (never free, never counted), tell the orchestrator to
report URGENT ones first, and tell the manager to drive its own plan-only
pull request to merged.

## Decisions

- No workers: the diff is one helper, one print block, two role-file
  sentences and one fixture section — splitting it costs more prompt than
  code, and every part is the judgement the plan's tier is for.
- Block printed after the rescope block, just before the verdict: "after the
  spawn list, before the verdict" with the CORE ONLY and rescope blocks kept
  next to the list they qualify.
- A plan whose path the base already carries is dropped (`cat-file -e`): the
  queue has its row; listing it twice is the duplicate the plan prevents.

## Rejected

- None yet.

## Review

- r1: (session) first selftest, 2026-10-10: `bash .agents/harness/selftest.sh` 2340 passed, 2 failed — the abandoned fixture's `printf` into `docs/handover` failed silently (git took the empty directory with mgr-y's file on checkout), and the curate case's `claude/inherits-it` refute matched the new block, which names that branch by right (it ADDED `inheritor`). (fixed — `mkdir -p` plus a positive build check per branch; the refute reads the output minus the branch-plan block)
- r2: (session) mutation, scratch worktree, same date: `joharness.sh` at origin/main reds 3 (the plan-only fixture); the two drop rules replaced by `:` red exactly their 2 refutes; restored 2344 passed, 0 failed. (no change)
- r3: (verifier) default rename detection turns a branch that retires `done-a.md` and adds a similar `followup-b.md` into `R086`, so `--diff-filter=A` drops the follow-up — step 7's normal edge shape, #297's second scenario. (fixed — `--no-renames`, as `fin_own_ws` already does; fixture `retire-and-follow`)
- r4: (verifier) a non-ASCII plan path is printed quoted, fails `gr_docs`'s `.md` test, and vanishes; same for a workstream file, whose `plan:`/`abandoned` then go unread. (fixed — `-c core.quotePath=false` on both diffs, as joharness.sh's finish reader does)
- r5: (verifier) a branch stacked on a plan-only branch prints the same plan a second time. (fixed — one row per stem, every branch carrying it after `on`; fixture `stacked`)
- r6: (verifier) no fixture pins the `cat-file -e` drop of a plan the base also carries. (fixed — fixture `twice`: the base adds the same path after the branch was cut)
- r7: (verifier) manage.md's sentence named only `ci` and `finish`, a subset of step 7. (fixed — step 7 whole, named as such)
- r9: (session) mutation for r3-r6, scratch worktree, 2026-10-10: `--no-renames`+quotePath dropped, `cat-file` drop disabled, dedupe removed, one `bash .agents/harness/selftest.sh` run: 2345 passed, 5 failed — exactly the five new cases (r4 got its fixture `nonascii` too); restored 2350 passed, 0 failed. (no change)
- r8: (verifier) the helper reads `"$(...)"` captures back through `<<<`, the pairing a comment calls racy. (wontfix — identical to `dispatch_rescope_branches`, which this copies by the plan's instruction; no race reproduced, and diverging the two walks is worse than matching them)

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_rescope_branches` — ref walk to copy.
