---
workstream: queue-always-open
status: review
branch: claude/queue-always-open
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Retire this file, open the pull request, merge.
---

## Goal

The requester said on 2026-08-31: **"We should allow to always create items
in the queue."** Amend the goal bound so recording is never blocked, without
giving up the convergence the bound exists for.

## The conflict this resolves

`docs/product/unsupervised-mode.md`, adopted hours earlier in PR 169:

> A plan that serves no open requirement is not generated.

Read literally, a session that finds a real defect at a moment when no
requirement is open must **drop it on the floor**. That contradicts Loop
step 5 — "Fix them or record why not — never drop silent" — and PR 162,
which reds a branch for exactly that omission. It would also have cost the
thing this harness is best at: PR 164 exists because an unsupervised sweep
found a red nobody had seen.

## Decisions

- **Split RECORDING from GENERATING**, which the one sentence conflated:
  - *Recording* — a session found something and writes it down. Always
    allowed, any mode, goal or no goal.
  - *Generating* — a session with nothing to do manufactures work to stay
    busy. Still bounded by the goal.
- **The convergence argument is untouched**, because it was never about
  recording. A fleet does not fail to converge by writing down what it found;
  it fails by inventing work to remain alive. PR 170 still stops it — the
  bound just no longer gags it on the way out.
- **A recorded item does not restart the fleet.** A plan written with no goal
  open is a note for a human. Otherwise recording becomes a way to
  manufacture a goal, which is the circularity the bound closes.
- **`unsupervised-plan-provenance` rewritten, not deleted.** Its original
  purpose is now the opposite of the rule, but its OTHER half — no
  unsupervised session writes a requirement — is what the goal-reached stop
  rests on and is still unenforced.

## Rejected

- **Reading it as "remove the goal bound".** The sentence is about creating
  queue items, not about stopping, and the same requester directed the bound
  hours earlier. Reverting PR 169 and PR 170 on an ambiguous sentence would
  be an expensive oscillation. Flagged instead: if that is what was meant,
  the revert is small and clean, and this amendment is the smaller half of it.

## Review

Round 1, opus, self.

- r1: I nearly implemented `unsupervised-plan-provenance` as written, one
  turn before this instruction arrived. It would have shipped a `ci` gate
  that reds a session for recording a finding — the exact behaviour PR 162
  reds a session for NOT doing. Two gates in opposite directions, a week
  apart, both from me. (fixed — the plan is rewritten and its Out of scope
  now names the trap in its own words)
- r2: the amendment had to say what a recorded-with-no-goal plan does NOT do.
  Without that, "always allowed" makes recording a way to manufacture a goal
  and reopens the circularity the bound closes. (fixed — it is a note for a
  human and does not restart the fleet)
- r3: the plan's Out of scope now distinguishes ADDING a requirement from
  EDITING one. PR 163 annotated a `Satisfied when` bullet with a measured
  result, unsupervised, and that is useful — a guard that caught it would
  stop the mode reporting its own results. (fixed — named as a deliberate
  decision for the implementing session rather than left to be discovered)
- r4: this reverses a rule I merged hours ago at the same requester's
  direction. Recorded plainly in the requirement with both dates, because a
  reader finding two directions from one person in one day needs to see which
  is current and why, not be left to guess. (no change needed)
- r5: verifier round owed and NOT run — standing instruction, twenty-fifth
  consecutive edge. (wontfix on this branch — issue #168)

## Blockers

None. If the requester meant "remove the bound entirely", say so — the
revert is small and this amendment is already half of it.
