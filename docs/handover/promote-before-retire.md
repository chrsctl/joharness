---
workstream: promote-before-retire
status: in-progress
branch: claude/promote-before-retire-k7q2
pr: none
plan: promote-before-retire
issue: none
session: https://claude.ai/code/session_019Xz6hcyWVbRopz1xES6Y8G
agent: sonnet
updated: 2026-10-06
next: Retire this file and the plan, open the pull request with the backtest script quoted
---

## Goal

Issue #258, option 2 (`docs/plans/promote-before-retire.md`): `finish` says,
at the one moment it is still reversible, how many recorded findings the
retire commit is about to destroy and how many promotion targets this diff
touches. Report-only.

## Decisions

- Own files = ADDED in a non-merge commit in base..HEAD, `--no-renames`,
  minus anything the merge base's tree carries (`joharness.sh:fin_own_ws`).
  Base commits are never in that range, so a reconcile merge cannot hand
  this branch another's file; a worker sub-branch's commits are, so its file
  counts. Added, not touched: editing an inherited file is not recording its
  findings.
- Count = `- r<N>:` bullets at column 0 (`lint_review_bullets` +
  `fb_keyable`), the ones `fb_fix_map` keys. Retired file read from history
  via `lint_ws_content`.
- Promotion targets = endpoint `git diff --name-only base HEAD` paths
  matching `(^|/)AGENTS\.md$` or `^\.agents/docs/`. Paths only, per the plan.
- Printed inside `cmd_finish` after the ADD section, before the plan-file
  note. Never touches `rc`.
- Backtest (script quoted whole in the pull request body, mirroring the
  final `fin_promote` walk; run 2026-10-06T00:09Z on origin/main at 3acfc69;
  50 = default `JOHARNESS_FEEDBACK_EDGES`): 50 edges, 43 recorded findings
  (509 total), 23 of those 43 touched a promotion target. Canonical caveat:
  here the harness IS the product, so editing `.agents/docs/` or an
  `AGENTS.md` is often the work itself, not a promotion — the second number
  overstates a habit. No threshold set from it.
- Proof: `.agents/harness/selftest.sh` 2026-10-05 — with the `fin_promote`
  call disabled, 2173 passed and 8 failed, all this topic's positive
  assertions. After review fixes, 2026-10-06T00:03Z: 2192 passed, 0 failed.
  Each review fix reverted: old walk + unfiltered diff + no zero-file guard
  = 9 failed (every new case but the rename count, whose fixture moved and
  rewrote in one commit — split into a pure move, then `--no-renames`
  removed alone = both rename cases red).

## Rejected

- `--first-parent` alone, copied from `fin_retired_own`: git >= 2.31 diffs a
  merge against its first parent under it, so a reconcile merge lists every
  base-brought file as added. Selftest caught it.
- `--first-parent --no-merges`: drops a sub-branch's file merged `--no-ff`
  (review r4).

## Review

- r1: (verifier) A DELETED or renamed-away AGENTS.md / `.agents/docs/` file counted as a promotion — `git diff --name-only` lists deletions. `--diff-filter=ACMR` now; selftest case deletes one. (fixed)
- r2: (verifier) Paths git quotes (non-ASCII) were dropped from both counts — `gr_docs` and the target regex never matched the quoted form. `-c core.quotepath=off` on the log and the diff; selftest case uses a non-ASCII name. (fixed)
- r3: (verifier) An inherited file `git rm`'d and re-added by the branch counted as its own. Own files now exclude anything the merge base's tree carries. (fixed)
- r4: `--first-parent --no-merges` dropped a workstream file a worker sub-branch added and the branch merged `--no-ff` — the `/manage` fan-out shape. Walk is now every non-merge commit in base..HEAD (a sub-branch's commits are in range, the base's never are), minus the base tree. (fixed)
- r5: A workstream file renamed within docs/handover was invisible to `--diff-filter=A` (default rename detection reports R). `--no-renames`; selftest case renames one. (fixed) Residue: findings written before the rename count under both names — rare, report-only, and the over-count errs toward naming the loss. (wontfix + why: exact attribution would need content reads the plan forbids)
- r6: The loss line listed own files with zero keyable findings. Only files contributing to N are named now. (fixed)
- r7: Selftest had no deleted-target, sub-branch, rename, mid-build (file present at HEAD) or re-added-inherited case. All added. (fixed)
- r8: Consumer layer's own `docs/` does not count as a promotion target. (wontfix + why: plan scopes targets to an AGENTS.md or `.agents/docs/`; `docs/` also holds plans and handover files, so a path match would count the work itself)
- r9: `fin_retired_own` has the reconcile-merge flaw `--first-parent` was meant to prevent — reproduced: two reconciles across another branch's add-then-retire list that file as this branch's retired one, which `lint_finding_markers` reds on. Sharing `fin_own_ws` would fix it. (wontfix + why: a red gate outside this plan's scope; flagged to the human as plan-worthy)
- r10: Count loop re-implements the iteration `lint_finding_ids` does. (wontfix + why: the rule itself is spelled once, `fb_keyable` + `lint_review_bullets`; what differs per caller is the action, and extracting it reshapes two gates outside scope)
- r11: Backtest cited a session-private script — a written number. Script now quoted whole in the pull request body with its run time. (fixed)
- r12: The new comment's "39 findings" lacked its command. Command added from the plan. (fixed)

## Blockers

None.

## Where to look

- `docs/plans/promote-before-retire.md` — scope, acceptance, traps.
