---
workstream: queue-hides-supervised-only-plans
status: in-progress
branch: claude/current-state-review-oxfb7f
pr: none
plan: queue-hides-supervised-only-plans
issue: none
session: https://claude.ai/code/session_011LSGxqQsZyuMYSqxa3jVT5
agent: opus
updated: 2026-09-01
next: Implement the SUPERVISED ONLY mark in queue-context.sh, then teach drain to read it
---

## Goal

The endurance retry of 2026-08-31 spent 55 minutes and $12.05 on
`marker-gate-needs-no-done`, a plan whose whole declared scope is protocol
text — which the unsupervised-mode Constraints forbid an unattended session
to commit. The session did everything right and could not finish. The queue
offered it as the top free item, and the disqualifying fact was in the
plan's own `scope:` frontmatter the whole time. Mark such a plan and stop
offering it to an unsupervised fleet.

## Decisions

- **Mode-gated, both the mark and the de-rank.** The plan's Acceptance says
  a supervised session sees the plan unchanged, and `queue-context.sh`
  already states the rule for itself: every mode-dependent line sits inside
  a branch `qc_mode` guards, so supervised output stays byte-identical.
  Supervised also pays zero extra forks, which keeps the perf row honest.
- **The protocol list comes from `joharness.sh protocol-paths`, one fork per
  hook run, not per plan.** Second copy is what issue #114 cost. Same call
  shape `handover-guard.sh` already uses.
- **Comparison is git pathspec semantics**, matching how the guard compares
  the same list: an entry is protocol when it equals a protocol path or sits
  under one at a slash boundary. `joharness.shX` therefore does not match
  `joharness.sh` — a Trap the plan names.
- **Classification is pure bash, no forks per plan.** A `tr`/`sed`/`grep`
  pipeline per plan is the fork-in-a-loop regression the perf budget exists
  to catch, in the file whose budget is tightest.
- **`scope:` is read in the row loop's existing `fields` call.** That call
  already reads six keys in one pass; a seventh costs nothing, and the rank
  is computed there.
- **De-rank is +2, the weight `claimed` carries** — listed, never leading.
  Not +4 (blocked): nothing is blocking it, and a supervised session should
  still see it as takeable work.
- **A plan with no `scope:` is UNKNOWN and is not marked SUPERVISED ONLY**,
  because guessing scope is out of the plan's scope. It gets its own
  unsupervised-only label instead, so absence is not silently read as clean.
- **`drain` reads the hook's answer, never re-derives it.** `drain_plan`
  filters the same string the hook prints, and `cmd_drain` names the
  supervised-only plans before deferring to the sweep — otherwise "queue
  empty" would print over a plan that is sitting right there, which is the
  DRAINED-over-a-requirement defect PR 157 fixed.

## Rejected

- **Marking in supervised mode too.** Reads as a useful warning; breaks the
  Acceptance line that says a supervised session cannot tell the feature
  shipped, and buys nothing — a supervised session may legitimately take the
  plan.
- **Blocking the session from taking it.** Explicitly out of scope: this
  marks and de-ranks, it does not forbid.

## Review

Depth is opus-adversarial (`./joharness.sh review`), plus a verifier that did
not write this diff.

- r1: **`drain` was reading a queue it never asked about.** `drain_hook` set
  `CLAUDE_PROJECT_DIR` and `HANDOVER_FETCH` and nothing else, so
  `queue-context.sh` fell back to `${JOHARNESS_RUN_MODE:-supervised}` and
  answered as supervised no matter what mode `drain` had just resolved and
  printed in its own banner. Every mode-dependent line in the hook was
  therefore invisible to `drain`, and the SUPERVISED ONLY row arrived here
  ranked free. Not a defect this change introduced — it predates it, and it
  means the session banner and `drain` have been describing different queues
  from one tree. Found because the new cases failed on a `next:` line that
  should have been filtered. (fixed — the resolved mode is passed to the
  child, exactly as `cmd_session_start` passes it; +2 external commands on
  the `drain` row, counted below)
- r2: two of my own first-draft assertions were vacuous, both in the shapes
  this repo has already paid for. `refute ... "1 free plans"` named a line
  the hook only prints at two or more free plans, so it could never have
  matched; and the unreadable-boundary `refute` matched the explanatory note
  that itself contains the words "marked SUPERVISED ONLY". Caught by running
  them, not by reading them. (fixed — the first asserts on the tail line the
  hook does print, the second reads the plan ROW)
- r3: my ordering case asserted the marked plan leads under supervised, and
  it did not: both plans were committed within the same second, so `added`
  tied and `sort`'s last-resort whole-line comparison decided it on the
  filename. That is PR129 r3's tie, walked into while writing a case about
  ordering. (fixed — the free plan is named `ztakeable` so the tie-break
  gives the OPPOSITE answer, which makes the rank the only thing that can
  produce the result asserted)
- r4: `ci` is RED on this branch and red on `origin/main` in this same
  container, on one case: the `graph` perf row, 422 counted against a budget
  of 260. It is the ref count, and that is now measured rather than called
  container-local: a `--single-branch` clone of this repo has 1
  remote-tracking ref and counts `graph` 31, `session-start` 86,
  `queue-context` 61, `drain` 83 — every row far inside budget. This
  container has 107, because 44 merged branches and their tracking refs are
  still standing (issue #167). The budgets were calibrated against a CI
  checkout, which fetches one branch. (wontfix on this branch — raising a
  literal to match an operator's ref count is what the row's own comment
  forbids, and the fix is deleting branches, which is human-only. Verified
  the other way instead: the whole suite is green in a single-ref clone.)
- r5: the change costs 0 external commands in the queue hook and +2 in
  `drain` — that row moved 1186 -> 1188 for r1's two `run_mode` calls, while
  `queue-context` and `session-start` did not move at all (497 -> 497,
  1188 -> 1188). Zero in the hook is the design and not luck: the boundary
  list is read once per run rather than per plan, `scope:` rides the
  `fields` call that was already there, and the classifier sets a global
  instead of being called in a `$( )` that would fork per plan. Measured on ONE tree by swapping only the two
  changed files, because these counts drift with repo state and a
  before/after taken across a commit is not a measurement of the code.
  (fixed — nothing to change; the design intent, counted)

## Blockers

None.

## Where to look

- `.agents/harness/queue-context.sh` — the row loop computes rank and label;
  `qc_mode` guards every mode-dependent line.
- `joharness.sh:protocol_paths` — the one list. `protocol-paths` is the
  subcommand.
- `joharness.sh:drain_plan` — the filter that keeps claimed and blocked rows
  out of `next:`.
