---
workstream: mark-mixed-protocol-scope
status: in-progress
branch: claude/unsupervised-slim-down-nqfie4
pr: none
plan: mark-mixed-protocol-scope
issue: none
session: https://claude.ai/code/session_017oZ8o5q2YRzjFT1eTnx4Cs
agent: opus
updated: 2026-09-02
next: Record verifier findings, fix or disposition each, retire this file and the plan, open the pull request.
---

## Goal

Direct ask after a review of the merged plan `unsupervised-drain-only`
(PR 197): "Research and solve". Three findings from that review, two
solved here and one raised for the human.

## Decisions

- `qc_scope_class` marks on ANY protocol path, not only on ALL.
  `handover-guard.sh` counts ANY, so the queue and the guard disagreed and
  the queue was the wrong one. Reverses a deliberate, commented, tested
  decision — the reasoning is in the plan's Goal and the short form is:
  the old rule assumes a session can half-finish a plan, and the Loop has
  no such state.
- Two labels, both marking, both de-ranking: `is all protocol text` and
  `includes protocol text`. One label would erase the distinction the old
  classes carried, and the shapes want different fixes — an `only` plan is
  supervised work forever, a `some` plan might be split.
- `unknown` untouched. Guessing stays out of scope.
- `unsupervised-drain-only.md` gets a stale-plan fix in place, not a new
  plan: `.agents/docs/plans/README.md` names that route, and the file is
  already on `main`.
- Its `advances:` is REMOVED rather than repointed. It advances no bullet:
  it rewrites the requirement. `lint_plan_advances` only fires on plans a
  branch ADDS, so a merged plan losing the field reds nothing.
- Found while building: `cmd_drain`'s NOT YOURS block explains the marked
  rows with "Scope is entirely protocol text", false for a `some` plan the
  moment this lands. Fixed with the block, not left for the next reader —
  `joharness.sh` and `selftest/drain.sh` joined the plan's scope for it.
- Finding 4 of the review — after that plan lands, the mode is one line of
  `drain` text, the spawn line, the `ci` requirement gate, the guard and
  the banner — is NOT acted on. Whether a mode that thin earns its switch
  is product direction. Raised in the pull request.

## Rejected

- Leaving `mixed` alone and fixing only the plan's prose. The prose said
  "Supervised session only" already; attempt four measured prose losing to
  dispatch. A rule nothing reads is the defect, not the wording.
- Marking `mixed` without de-ranking it (a note only). The hazard is that
  `drain` hands the plan out as `next:`; a note does not stop that.
- Changing the plan's `scope:` to protocol paths only. It genuinely
  touches `docs/product/`; a scope that lies to get a marking is worse
  than the marking being wrong.
- Splitting `unsupervised-drain-only` into two plans along the boundary.
  Its doc half rewrites a requirement to describe behavior the code half
  has not got yet; shipping that half alone makes the requirement lie.

## Review

Round 1, self, adversarial (correctness, does-it-reproduce, second-order):

- r1: `cmd_drain`'s NOT YOURS block explains the marked rows with "Scope
  is entirely protocol text" — false for a `some` plan the moment this
  lands, and the block is the one place a session reads the reason.
  (fixed: "Scope holds protocol text ... the row above says whether that
  is all of it or part"; `drain.sh` pin moved with it)
- r2: the corrected `unsupervised-drain-only.md` still listed the comment
  above `qc_mode` among comments naming DELETED symbols. The marking
  stays, so that comment names nothing deleted. (fixed)
- r3: its Where to look still said `drain_supervised_only` and the
  `drain_plan` filter "feed only" code the plan deletes. (fixed: they feed
  the marking and stay)
- r4: its decision 1 deleted the whole unsupervised arm of `cmd_drain`
  after "Nothing free" — including the NOT YOURS block, which belongs to
  the marking decision 3 now keeps. Without it a session reads DRAINED
  over a tree still holding plans, the defect `drain_goal_reached` was
  written against. (fixed: the goal and sweep lines go, NOT YOURS stays)
- r5: same split missed in its `drain.sh` bullet, which listed the six
  NOT YOURS cases among those to delete. (fixed: named as STAY)
- r6: second-order effect, recorded not fixed. All three plans on `main`
  are now marked, so an unattended fleet here reaches the generate-work
  edge instead of taking work it could not finish. That is the designed
  behaviour of the current tree and it is transitional — once
  `unsupervised-drain-only` lands, that edge is a stop. Dispatching
  unfinishable work is the worse of the two. (no change needed)

Round 2, verifier at opus, 12 findings:

- r7: (verifier) my own r1 fix was false. `drain_supervised_only` strips
  the label, so drain's block prints bare paths — and the replacement text
  said "the row above says whether that is all of it or part". I read that
  output and did not see it. (fixed: clause dropped, comment says why the
  block cannot make that claim)
- r8: (verifier) the boundary-unread block in `queue-context.sh` still
  printed the old rule ("a plan scoped entirely to protocol text"), and
  the completeness grep could not see it. (fixed)
- r9: (verifier) the change silently un-pinned the space-split
  regression: every all-protocol case asserted only `SUPERVISED ONLY`, and
  a fragmenting bug now yields `some`, which still marks. (fixed: the five
  all-protocol fixtures assert the LABEL; re-verified by mutation —
  `local IFS=', '` reds "a space in a path does not split it into two",
  1273 passed 1 failed)
- r10: (verifier) `unsupervised-drain-only`'s acceptance demanding the two
  modes' hook output diff empty is unsatisfiable once the marking stays.
  (fixed: the `eq_same` fixtures are the pin; a whole-repo diff is not)
- r11: (verifier) its size acceptance demanded `queue-context.sh` shrink
  while decision 3 now touches nothing there. (fixed)
- r12: (verifier) its `perf_rows` bullet claimed the unsupervised row
  measures the same path as supervised. (fixed: the marking stays, so it
  does not)
- r13: (verifier) its Trap still explained an `advances:` this branch
  removed. (fixed: deleted)
- r14: (verifier) honest declaration now costs dispatchability — the plan
  protocol tells authors to declare registration files and `shared:`
  paths, which in this repo are protocol text, so declaring them marks the
  plan. (recorded as a KNOWN COST in the plan, not designed around:
  under-declaring costs a reconcile, dispatching an unfinishable plan
  costs the run) (no change needed — the marking is not narrowed back;
  the cost is recorded in the plan's Traps so the next author sees it)
- r15: (verifier) the requirement cited attempt two for the ANY rule;
  attempt two's plan was all-protocol. (fixed: attempt two measures the
  all shape, the f9fb932 drain run measures the partly shape)
- r16: (verifier) this plan's `scope:` omitted
  `docs/plans/unsupervised-drain-only.md`, which the branch edits, and its
  Scope said "three classes" where the code returns four. (fixed)
- r17: (verifier) two comments still named the removed class `mixed`.
  (fixed)
- r18: (verifier) drain's block grew two lines against the style guide.
  (fixed by r7)

## Blockers

None.

## Where to look

- `.agents/harness/queue-context.sh:qc_scope_class` — the comparison this
  branch changes.
- `.agents/harness/selftest/queue-context-supervised-only.sh` — "partial
  overlap is a different case", the block that inverts.
- `docs/plans/unsupervised-drain-only.md` — `advances:`, the Traps line
  claiming the queue marks it, and decision 3's bundle.
