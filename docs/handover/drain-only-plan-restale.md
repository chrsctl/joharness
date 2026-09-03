---
workstream: drain-only-plan-restale
status: in-progress
branch: claude/unsupervised-slim-down-nqfie4
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_017oZ8o5q2YRzjFT1eTnx4Cs
agent: opus
updated: 2026-09-02
next: Apply the three corrections, review at opus with a verifier, retire this file, open the pull request.
---

## Goal

Direct ask after reviewing `main` at a6decc1: "Fix". Three findings against
`docs/plans/unsupervised-drain-only.md`, the queue's only plan, staled by
the merges that landed while it waited.

## Decisions

- No new plan file. `.agents/docs/plans/README.md` Lifecycle names this
  route: "Stale plan (code moved under it): fix plan in place on `main`
  via small PR". A plan to fix a plan's three stale sentences is ceremony
  the route already answers.
- The retire list loses `docs/plans/advance-feedback-baseline.md`.
  That plan was retired by its own pull request (91efcbe) and is gone from
  `main`; `git rm` with a missing pathspec is fatal and stages NOTHING
  (measured in a scratch repo: exit 128, empty index), so a session
  following the Acceptance literally produces no retire commit at all —
  no plan file deleted, no workstream file deleted. The Scope bullet
  hedged this; Acceptance and Traps did not, and the plan protocol writes
  for a literal reader.
- `scope:` drops two entries: that same deleted path, and
  `.agents/harness/queue-context.sh`, which decision 3 explicitly leaves
  alone ("NOTHING"). Two readers consume `scope:` — the ship-scope stage
  and the SUPERVISED ONLY marking — so an untrue scope is a wrong answer
  from both. Still `some` after the trim, so the marking is unchanged.
- Sizes re-counted at the ref they now describe rather than deleted. The
  Goal argues the cut FROM those numbers, so the argument wants live ones.
- The "rewritten once already" trap becomes three times, with the dates.
  That is the plan's real risk and it is the cheapest thing to keep true.

## Rejected

- Deleting the plan as obsolete. It is not: every decision in it still
  describes work nobody has done, and the requirement it rewrites is open.
- Implementing it here to stop the staling. It is xhigh, entirely
  protocol-scoped, and the human has not asked for it — the review said
  so and that stands.
- Slicing it into smaller plans so each lands before the next merge. A
  real option, and the review named it, but it is a decomposition
  decision the human should take rather than a correction to a stale file.

## Review

Round 1, self, adversarial (correctness, does-it-reproduce):

- r1: clean pass, no findings. What was checked rather than assumed, all
  at a6decc1: every symbol the plan names still exists (`cmd_sources`,
  `src_run_checks`, `src_unmarked`, `SRC_MARKERS`, `FB_SINCE`,
  `fb_since_ok`, `FB_UNMARKED_SINCE`, `since_set`, `FB_CACHE_VARS`,
  `fb_cache_load`, `lint_plan_advances`, `drain_goals`, `drain_wave1`,
  `drain_supervised_only`, `qc_scope_class` — non-zero counts for each);
  all twelve `drain.sh` case names it lists for deletion and all six NOT
  YOURS cases it says STAY are present (`grep -cF` per name, none
  missing); its requirement phrase grep hits nine bullets, one each, every
  one a bullet the plan deletes or rewords; its `awk` grep over
  `.agents/docs/unsupervised.md` hits only the table rows and the section
  the plan rewrites, and no longer the queue-hook row it now leaves alone.
  The marking still reads `SUPERVISED ONLY: scope includes protocol text`
  after the scope trim, and ship-scope drops `queue-context.sh` from the
  SHIPS list, which is the point of trimming it. (no change needed)

## Blockers

None.

## Where to look

- `docs/plans/unsupervised-drain-only.md` — `scope:`, the Goal's size
  paragraph, the `advance-feedback-baseline` Scope bullet, the retire
  lines in Acceptance and Traps, the "rewritten once" trap.
- `.agents/docs/plans/README.md` — Lifecycle, "Stale plan", the route
  this branch takes.
