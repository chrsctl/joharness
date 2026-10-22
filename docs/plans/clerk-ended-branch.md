---
plan: clerk-ended-branch
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: shared:joharness.sh, .agents/harness/selftest/clerk.sh, shared:.claude/commands/clerk.md
---

## Goal

A clerk pass that writes a plan, pushes its branch (`.claude/commands/clerk.md`
§1: push after the first plan commit), then drops that plan and ends with the
no-op record (§4) leaves its `clerk-<date>` branch pushed with no net change.
`clerk_walk` counts every unmerged clerk branch younger than
`JOHARNESS_CLERK_STALE_HOURS` (24) as `in-flight`, so the finished pass holds
the clerk cycle for a day. Seen 2026-10-22: `clerk-2026-10-22` (plan for #512
written at 07:35, dropped at 07:38, `clerk-noop-20261022T073839Z` pushed)
read `IN FLIGHT` 9 h later. Branches are never deleted by a session, so the
reader must recognise a pass that ended. This plan adds that recognition,
failing closed: anything short of proof keeps today's `in-flight`.

## Scope

- `joharness.sh:clerk_walk` — a third row state, `ended` (word exact). An
  unmerged clerk branch is `ended` only when BOTH hold:
  1. no net change: `git diff --quiet "$(git merge-base <base_id> <tip>)"
     <tip>` exits 0. Any git error = not proven = keep the current
     `in-flight`/`abandoned` decision.
  2. a merged `clerk-noop-<stamp>` ref (same set `clerk_noop` reads) whose
     `clerk_stamp_ts` is greater than or equal to the branch tip's committer
     time.
  Both checks run only for rows that would otherwise be `in-flight`.
  Update the comment above `clerk_walk` to name the third state.
- `joharness.sh:scout_branches` — drop `ended` rows exactly as it drops
  `abandoned` ones (the `[ "$s" = abandoned ] && continue` line). Check every
  other reader of `clerk_walk` rows (`grep -n clerk_walk joharness.sh`) and
  treat `ended` like `abandoned` wherever `abandoned` is matched.
- `.agents/harness/selftest/clerk.sh` — new cases beside (b)/(c), using the
  existing `clerk_branch`, `clerk_commit`, `clerk_ago` helpers:
  - (e) branch adds a plan then a second commit removes it, then a merged
    `clerk-noop-<stamp>` dated after the tip → output does NOT contain
    `IN FLIGHT`, cadence follows the no-op clock.
  - same branch, no no-op ref → `tip-0h  in-flight` (still holds).
  - same branch, no-op stamped BEFORE the tip → `in-flight`.
  - a branch with a net change (plan kept) and a later no-op → `in-flight`.
  The first case must FAIL on `main` before the change.
- `.claude/commands/clerk.md` §1 — the sentence "your unmerged branch reads
  IN FLIGHT until its tip is `JOHARNESS_CLERK_STALE_HOURS` old … then
  abandoned" gains: "or until a later no-op record lands while it carries no
  net change (`ended`)". Status quo wording, no history.

## Out of scope

- Deleting, renaming or force-pushing any branch (`git push --delete` is
  human-only). `clerk-2026-10-22` stays.
- Changing the clerk's own procedure (pushing earlier or later, deleting its
  branch). The reader adapts; the role text only describes it.
- The same idea for scout, conduct or curate branches.
- A new knob.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- `./joharness.sh clerk` on this repo (after `git fetch origin`), while
  `origin/clerk-2026-10-22` is younger than 24 h — its row reads
  `clerk-2026-10-22  tip-<N>h  ended` and the cadence line does not say
  `IN FLIGHT` for it. Older than 24 h, it is `abandoned` as today; say which
  one you saw, with the time, in the PR body.
- The new selftest cases pass, and case (e) is red with the `clerk_walk`
  change reverted (show the red line in the workstream file's `## Review`).
- Plan `ci` calls SHIPS: `.agents/harness/selftest/clerk.sh` runs in every
  consumer's `ci` at its next sync.

## Where to look

- `joharness.sh:clerk_walk` — the row writer; `for-each-ref --no-merged`,
  the stale window, the `in-flight`/`abandoned` decision.
- `joharness.sh:clerk_noop`, `joharness.sh:clerk_stamp_ts` — how no-op refs
  are listed (merged only) and dated (by name, clamped against a broken
  clock).
- `joharness.sh:scout_branches` — drops `abandoned` rows.
- `joharness.sh:clerk_due` — reads `CLERK_ROWS`; confirm an `ended` row
  takes no slot.
- `.agents/harness/selftest/clerk.sh` cases (b) and (c) — fixture shape and
  the expected row text `clerk-<date>  tip-<N>h  in-flight`.
- `.claude/commands/clerk.md` §1 and §4 — push-after-first-plan and the
  no-op record.

## Traps

- Fail closed: a git error, a missing merge base, an unparsable stamp = not
  `ended`. A wrong `ended` lets dispatch spawn a second clerk beside a live
  one.
- A live clerk can drop one plan and write another in the same pass: the
  empty diff alone proves nothing; the later no-op record is required.
- NEVER skip, disable or quarantine a test; existing (b)/(c) cases stay
  green unchanged.
- No edit to core paths (`./joharness.sh protocol-paths`).
