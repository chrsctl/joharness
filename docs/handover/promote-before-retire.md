---
workstream: promote-before-retire
status: in-progress
branch: claude/promote-before-retire-k7q2
pr: none
plan: promote-before-retire
issue: none
session: https://claude.ai/code/session_019Xz6hcyWVbRopz1xES6Y8G
agent: sonnet
updated: 2026-10-05
next: Suite green, then verifier review at sonnet+ and the retire commit
---

## Goal

Issue #258, option 2 (`docs/plans/promote-before-retire.md`): `finish` says,
at the one moment it is still reversible, how many recorded findings the
retire commit is about to destroy and how many promotion targets this diff
touches. Report-only.

## Decisions

- Own files = ADDED by this branch, first-parent AND `--no-merges`
  (`joharness.sh:fin_own_ws`). Added, not touched: editing an inherited file
  is not recording its findings. `--no-merges` because git >= 2.31 diffs a
  merge against its first parent under `--first-parent`, so a reconcile merge
  lists every base-brought file as added — the selftest's merged-in case
  failed on exactly that before the flag.
- Count = `- r<N>:` bullets at column 0 (`lint_review_bullets` +
  `fb_keyable`), the ones `fb_fix_map` keys. Retired file read from history
  via `lint_ws_content`.
- Promotion targets = endpoint `git diff --name-only base HEAD` paths
  matching `(^|/)AGENTS\.md$` or `^\.agents/docs/`. Paths only, per the plan.
- Printed inside `cmd_finish` after the ADD section, before the plan-file
  note. Never touches `rc`.
- Backtest (`scratchpad backtest.sh 50` mirroring `fin_promote`, run
  2026-10-05T23:13Z on origin/main c96088a.. window, 50 = default
  `JOHARNESS_FEEDBACK_EDGES`): 50 edges, 42 recorded findings (466 total),
  23 of those 42 touched a promotion target. Canonical caveat: here the
  harness IS the product, so editing `.agents/docs/` or an `AGENTS.md` is
  often the work itself, not a promotion — the second number overstates a
  habit. No threshold set from it.
- Proof: `.agents/harness/selftest.sh` 2026-10-05 — 2181 passed, 0 failed
  with the stage; with the `fin_promote` call disabled, 2173 passed and 8
  failed, all eight this topic's positive assertions.

## Rejected

- `--first-parent` alone, copied from `fin_retired_own`: lists a reconcile
  merge's brought-in files as added (see Decisions).

## Review

## Blockers

None.

## Where to look

- `docs/plans/promote-before-retire.md` — scope, acceptance, traps.
