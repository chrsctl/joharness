---
workstream: plan-halt-and-hold
status: in-progress
branch: claude/plan-halt-and-hold
pr: none
plan: halt-and-hold
issue: none
session: https://claude.ai/code/session_016VB32myigsC5a7gT5th1gL
agent: fable
updated: 2026-10-24
next: Retire the workstream file in the last commit, open the pull request, run finish, merge
---

## Goal

Planning pass for `docs/product/halt-and-hold.md`: decompose the requirement
(halt a live claim on a human's order; hold an unplanned requirement behind
other work without a slot) into plans. Plans only, no implementation.

## Decisions

- Two plans, one per gap, no `needs:` edge between them: `halt-claim`
  (opus, xhigh: a new leased writer onto a branch the session does not own,
  Part 2 territory) and `hold-requirement` (sonnet, high: hook rows, a lint
  arm, a dispatch line). Both declare `shared:joharness.sh`: disjoint
  functions, a routine reconcile.
- Halt reuses `status: abandoned`. Read in code: the hook drops an `abandoned`
  claim from `claimed on` (`queue-context.sh`, awk `$3 != "abandoned"`),
  dispatch then has no in-flight row and no slot, `dispatch_freeable` and
  `dispatch_branch_plans` hide the branch, the orchestrator drops a branch
  dispatch stops listing. A new word would touch every `status:` reader
  for no measured gain; the halt is told apart in git by its commit subject
  and `next:` text.
- An edge branch (retired record, open pull request) is halted by
  restoring its own retired record with the word: `dispatch_retired_edges`
  skips any branch whose diff against the base adds a workstream file, so
  the slot goes and the claim reads released.
- Hold = two optional requirement fields: `needs:` (deferred behind an
  item; clears without an edit when the file is gone) and `hold:` (a
  human's reason; clears by edit). Resolution across plans, research and
  requirements in the claim order. The reason never enters a hook label
  (forged-claim rule, verifier r6 in the hook); dispatch prints it from the
  base on a `withheld` line.
- Requirement clause checks against code: janitor gates are in
  `janitor_candidates` (age `HANDOVER_STALE_SECONDS`, `pr:`, status) and
  `cmd_guard`'s janitor-only `pr:` arm — confirmed; requirement frontmatter
  reads `priority` only (`queue-context.sh`, `lint_graph`) — confirmed;
  `drain_requirement` is the one offering reader — confirmed.

## Rejected

- `janitor --apply --halt <branch>`: overloads the sweep whose rules the
  requirement says must stay for claims nobody halted; a separate command
  keeps the age gate and the `pr:` refusal untouched and readable.
- A `priority: held` value or `needs: human`: `priority` is an enum two
  readers red on; `needs: human` reds `lint_graph` as a stem that never
  existed. Two fields, two meanings.
- A plan's `needs:` reaching requirements: not asked, and the plan edge
  stays plan to plan.

## Review

- r1: halt-claim Scope lacked the rev-parse step before the guard that its SHIPS acceptance line relies on (plan-checker) (fixed)
- r2: halt-claim left `guard janitor|kill|loop` stale in orchestrated.md and the joharness.sh header (plan-checker) (fixed)
- r3: halt-claim said an unlisted selftest topic is never run; the runner reds it (plan-checker) (fixed)
- r4: halt-claim A7 anchored `retro_due`; the comment is `retro_candidates`'s (plan-checker) (fixed)
- r5: halt-claim named the `own` walk; `dispatch_retired_edges` computes `items` and filters by `own` (plan-checker) (fixed)
- r6: halt's `next:` dropped the janitor's why clause a pre-`abandoned` branch needs (plan-checker) (fixed)
- r7: both plans at 8 or 9 Scope bullets drew curate's decompose proposal; same-file bullets merged to 7 each (plan-checker) (fixed)
- r8: hold-requirement's queue-context case refuted a sentence that fixture never prints (plan-checker) (fixed)
- r9: hold-requirement anchor named assertions absent from the queue-context selftest (plan-checker) (fixed)
- r10: hold-requirement acceptance counted `withheld` from 4 while one PASS label already carries it (plan-checker) (fixed)
- r11: hold-requirement SHIPS parenthetical understated the shipped set (plan-checker) (fixed)
- r12: hold-requirement anchors imprecise on the `rprio` comment and the `claimed on` parse (plan-checker) (fixed)
- r13: hold-requirement filtered `unplanned_free` on the bare word `held`, dropping any stem containing it; the comma-led token is the filter, with a selftest case (verifier) (fixed)
- r14: hold-requirement named its dispatch line `withheld`, a word and a variable the edge already owns; renamed `deferred`, `orchestrated.md` declared `shared:` (verifier) (fixed)
- r15: `halt` cannot prove a human ordered it; a Traps line names the risk and that no session runs it on its own judgement (verifier) (fixed)
- r16: a requirement `needs:` naming an item on an unmerged branch only fails open on the hook and reds `ci`; named in Out of scope as the same rule a plan's `needs:` has (verifier) (fixed)
- r17: a requirement `needs:` naming itself held forever with no lint; `lint_graph` reds `names itself` (verifier) (fixed)
- r18: halt on guard exit 2 kept the stale remote-tracking ref `janitor_apply` drops; added, with the assertion in case 6 (verifier) (fixed)
- r19: halt shape 2 missed an edge whose record was inherited from the base and swept; restore `<base>:<swept>` (verifier) (fixed)
- r20: r7 and two Assumptions carried text after the disposition or confidence word (verifier) (fixed)
- r21: Decisions said "Measured" for a code reading with no command; reworded (verifier) (fixed)
- r22: `needs:` case sensitivity on a case-insensitive filesystem is the same property a plan's `needs:` has today (verifier) (no change)

## Blockers

None.

## Where to look

- `docs/product/halt-and-hold.md` — the requirement.
- `docs/plans/halt-claim.md`, `docs/plans/hold-requirement.md` — the plans.
- `joharness.sh:janitor_apply` — the leased write halt copies.
- `joharness.sh:drain_requirement` — the one reader that offers a requirement.
