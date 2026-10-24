---
workstream: halt-claim
status: in-progress
branch: claude/halt-claim
pr: none
plan: halt-claim
issue: none
session: https://claude.ai/code/session_01Te9BJuEAtCjWLZLa2BMTDM
agent: opus
updated: 2026-10-24
next: Re-run ci and the selftest on the verifier fixes, then finish
---

## Goal

Add `./joharness.sh halt <branch>...`: a human's order to release a live
claim at any age, `pr:` or not, written through the guard and the lease;
the item returns to the queue (`docs/plans/halt-claim.md`).

## Decisions

- A1: confirmed — queue-context.sh `claimed_on=` awk `$3 != "abandoned"`; halt selftest case 2 shows no `claimed on`.
- A2: confirmed — halt selftest case 2: `slots     : 4 of 4 free`, no row for the halted branch.
- A3: confirmed — orchestrate.md health table first row; dispatch_branch_plans skips abandoned branches.
- A4: confirmed — dispatch_retired_edges ACMRT line; halt selftest case 3 drops the retired row.
- A5: confirmed — cmd_guard `if [ "$verb" = janitor ]`.
- A6: confirmed — janitor.sh:411 is the one `expect` (171 is fixture text); release_rewrite keeps the janitor's next: text byte-identical.
- A7: confirmed — retro_candidates header; its comment now names halt too.
- A gone branch under halt prints `skip      : <b> — gone on origin` and keeps rc (no failure), as the janitor treats gone.
- halt fetches the base branch too: shape 2's merge base reads `origin/<base>`.

## Rejected

None yet.

## Review

- r1: (plan-checker) case 1 expected `not a candidate` from the janitor; its guard refuses a `pr:` claim first (fixed: plan and selftest expect `guard refused`, plus `guard halt` passes)
- r2: (plan-checker) case 6 via `git push --delete` drops the clone's own ref; and a `--prune` fetch would too (fixed: plan says delete on bare origin, no prune fetch; selftest does so)
- r3: (plan-checker) `.agents/docs/orchestrated.md` shared with hold-requirement but unmarked here (fixed: `shared:` in this plan's scope)
- r4: (plan-checker) stale sentences: handover README "releasing one stays the janitor's", orchestrated.md "the one writer", retro_candidates comment (fixed); scout.md "that word is the janitor's" (wontfix: a scout still never writes it; halt is a human's, not a scout's)
- r5: (plan-checker) SHIPS line names no command for a consumer checkout (no change: run by hand in a scratch clone at finish, recorded here)
- r6: (plan-checker) janitor-range acceptance has no PASS floor; guard acceptance needs network (no change: run here with network; the janitor topic printed its PASS lines)
- r7: (plan-checker) Scope spelled `skip :` etc. unpadded against padded selftest text (fixed: plan uses janitor_apply's padded column)
- r8: (plan-checker) A6's grep prints two lines (no change: one is fixture text, the `expect` is one)
- r9: (verifier) a branch that only deletes plans, no workstream file ever, keeps its retired slot after halt (wontfix: no claim record to release; the plan's Neither = skip; such a branch is a plan-only edge whose pull request closes it — flagged for a human)
- r10: (verifier) halt twice on one day said `no frontmatter … release it by hand`, rc 1 (fixed: an identical blob still on the tip reading `abandoned` = `already released`, rc 0; selftest fails without it)
- r11: (verifier) `halt HEAD` followed the origin/HEAD symref and deleted refs/remotes/origin/main (fixed: `update-ref --no-deref -d` in halt and janitor_apply; selftest fails without it)
- r12: (verifier) the swept-record path had no test (fixed: case 7)
- r13: (verifier) closing `halt wrote git only` line printed when nothing was written (fixed: only after a push; asserted)
- r14: (verifier) orchestrated.md freer row said janitor-released only (fixed: names halt)
## Blockers

None.

## Where to look

- `docs/plans/halt-claim.md` — the plan.
