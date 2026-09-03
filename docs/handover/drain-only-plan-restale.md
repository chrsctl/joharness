---
workstream: drain-only-plan-restale
status: in-progress
branch: claude/unsupervised-slim-down-nqfie4
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_017oZ8o5q2YRzjFT1eTnx4Cs
agent: opus
updated: 2026-09-03
next: Retire this file and open the pull request.
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
  `main`; `git rm` with a missing pathspec is fatal and stages NOTHING —
  measured 2026-09-03 in a scratch repo, `git init`, two tracked files,
  then `git rm keep.md missing.md` prints
  `fatal: pathspec 'missing.md' did not match any files`, exits 128, and
  `git diff --cached --name-only` comes back empty — so a session
  following the Acceptance literally produces no retire commit at all —
  no plan file deleted, no workstream file deleted. The Scope bullet
  hedged this; Acceptance and Traps did not, and the plan protocol writes
  for a literal reader.
- `scope:` drops two entries: that same deleted path, and
  `.agents/harness/queue-context.sh`, which decision 3 explicitly leaves
  alone ("NOTHING"). THREE readers consume `scope:` — `lint_ship`, the
  SUPERVISED ONLY marking, and the wave partition (`scopes_overlap` /
  `wave_split_hit`, which the plan's own Out of scope names) — so an
  untrue scope is a wrong answer from all three. Still `some` after the
  trim, so the marking is unchanged; the partition never saw this plan
  anyway, because a de-ranked plan never enters `free_scopes`.
- Sizes re-counted at the ref they now describe rather than deleted. The
  Goal argues the cut FROM those numbers, so the argument wants live ones.
- The "rewritten once already" trap becomes a `git log --first-parent`
  command rather than a hand-written sequence of merges. Three drafts of
  that sentence got the order or the dates wrong (r4); the plan's own rule
  is to trust counted numbers over written ones, and this sentence is the
  one place the plan was breaking it.

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

- r1: recorded as a clean pass, and **r5 below shows it was not one.**
  What it checked, all at a6decc1, and what survives: fifteen named
  symbols carry non-zero counts (`cmd_sources`, `src_run_checks`,
  `src_unmarked`, `SRC_MARKERS`, `FB_SINCE`, `fb_since_ok`,
  `FB_UNMARKED_SINCE`, `since_set`, `FB_CACHE_VARS`, `fb_cache_load`,
  `lint_plan_advances`, `drain_goals`, `drain_wave1`,
  `drain_supervised_only`, `qc_scope_class`); all twelve `drain.sh` case
  names listed for deletion and all six NOT YOURS cases said to STAY are
  present (`grep -cF` per name); the requirement phrase grep hits nine
  bullets, one each, every one a bullet the plan deletes or rewords; the
  `awk` grep over `.agents/docs/unsupervised.md` hits only the rows and
  the section the plan rewrites; the marking still reads `SUPERVISED
  ONLY: scope includes protocol text` and ship-scope drops
  `queue-context.sh`.
  What does NOT survive is the sentence it drew from all that: "every
  symbol the plan names still exists". Those fifteen were a list I wrote
  from the plan's Scope, and it omitted `authority_merged` — named under
  Out of scope, gone from the tree since `0b78eaa`. A completeness claim
  is worth exactly the list behind it, and mine was not derived from the
  file it claimed to cover. (fixed by r5)

Round 2, verifier at opus, 12 findings:

- r2: (verifier) Out of scope still treated `gate-review-verifier-tag` as
  a claimed plan to reconcile with — merged as PR 194 and gone from the
  tree, the same defect class this branch exists to fix, one bullet away
  from the one it fixed. (fixed: the bullet now says the gate is merged
  and its cases are already in `review.sh`)
- r3: (verifier) "measured 2026-09-02 on `main` a6decc1" is an impossible
  date — a6decc1 is 2026-09-03 08:15 +0200 and the commit writing the
  sentence is 2026-09-03. The counts reproduce; the "when" did not.
  (fixed here and on the `cmd_sources` count beside it)
- r4: (verifier) the staleness Traps sentence was wrong in order and in
  date, and "in one day" was false: PR 194 and PR 196 precede PR
  197/199/200/198, which span two calendar days. (fixed: the narrative I
  keep getting wrong is replaced by the `git log --first-parent` command
  that regenerates it — a written number replaced by a counted one)
- r5: (verifier) Out of scope names `authority_merged`, deleted by
  `0b78eaa` and present nowhere but that line. (fixed: removed; r1
  corrected above)
- r6: (verifier) the Acceptance grep is unsatisfiable under the plan's own
  Scope: `queue-context-edge.sh:66` refutes `GOAL REACHED` inside
  `eq_same`, which Scope says stays, and Traps forbid cutting a case to go
  green. (fixed: that refute is now named as a third line to remove — once
  the goal stop is deleted it refutes a string no mode can print, the same
  shape as "supervised does not pay for the sweep")
- r7: (verifier) `cmd_drain` is 156 lines at a6decc1, not the 152 the plan
  quoted from 15c5df8. (fixed: both refs given)
- r8: (verifier) the `git rm` justification carried no command and no
  date, though it is the load-bearing evidence for the whole correction.
  Independently reproduced by the verifier and TRUE. (fixed: command
  written out)
- r9: (verifier) this file said two readers consume `scope:`; there are
  three. (fixed)
- r10: (verifier) `updated:` was a day behind. (fixed)
- r11: (verifier) two places said `queue-context-fanout.sh` has "two" trap
  cases; `grep -n` finds one. (fixed)
- r12: (verifier) `mark-mixed-protocol-scope.md` is named as a path but is
  merged and retired. Read as history, so it misdirects nobody. (fixed
  anyway: named as PR 198 history rather than as a file)
- r13: (verifier) the branch reuses `claude/unsupervised-slim-down-nqfie4`,
  the head branch of already-merged PR 198, against Branch flow's one
  branch per plan. (wontfix — this session's instructions pin the branch
  name and forbid pushing to another without permission; the merged
  history was reset from `main` first, which is the documented way to
  reuse a merged designated branch. Worth a human's eye, not a session's
  unilateral rename.)

## Blockers

None.

## Where to look

- `docs/plans/unsupervised-drain-only.md` — `scope:`, the Goal's size
  paragraph, the `advance-feedback-baseline` Scope bullet, the retire
  lines in Acceptance and Traps, the "rewritten once" trap.
- `.agents/docs/plans/README.md` — Lifecycle, "Stale plan", the route
  this branch takes.
