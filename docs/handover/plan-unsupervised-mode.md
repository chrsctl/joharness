---
workstream: plan-unsupervised-mode
status: done
branch: claude/plan-unsupervised-mode
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Retire this file, open the pull request, merge.
---

## Goal

Decompose `docs/product/unsupervised-mode.md`, the queue's only entrypoint.
Decomposing IS the work (step 2); the four plans are the deliverable.

## What was already satisfied, checked against the tree

Filing a plan for work already done is the expensive mistake here, so every
`Satisfied when` bullet was checked before anything was written:

- **mode in `joharness.conf`, visible at session start** — done; the hook
  prints `Mode: supervised`.
- **supervised byte-identical** — done.
- **full Loop on a free plan, self-merge under step 7** — done, and measured
  by the fan-out run.
- **two free plans produce two sessions** — done, measured 2026-08-30.
- **no unsupervised commit to protocol text** — done: issue #114 is closed
  as completed by merged PR #118, `joharness.sh:protocol_paths` is the one
  list, and `handover-guard.sh` reads it.

Two bullets are unmeasured, and two Constraints have no implementation.
Those are the four plans.

## The four, and why that order

- `unsupervised-stop-condition` (sonnet, medium) — `sources` reports **one**
  of the stop condition's four parts. Counted on `aab2fa4`: `sweep NOT dry
  — checks(0 failing, 1 skipped) findings(151 unmarked)`, which is one
  sweep's detectors and nothing about "two consecutive", queue empty, or no
  open pull request.
- `unsupervised-finding-dedupe` (sonnet, medium) — the constraint "a finding
  that unsupervised-generated work itself introduced is not a source
  finding" has **no implementation**: `grep -rn "dedupe\|already cited\|cited
  the finding" joharness.sh .agents/harness/*.sh` returns nothing,
  2026-08-31. The detector it guards reports 151 unmarked and grows with
  every merge, so it is the one least able to reach zero — and the mode's
  only stop runs through it.
- `unsupervised-edge-generates-work` (opus, high) — the unmeasured bullet
  about generating work at the edge. `needs:` both of the above.
- `unsupervised-endurance` (opus, xhigh) — the unmeasured "for hours".
  `needs:` the one above it.

Mechanism before measurement, because measuring endurance against a stop
condition no command states measures the wrong thing.

## Decisions

- **Decomposed against the text as it stands**, at the human's instruction.
  Both measurement plans carry a `BEFORE YOU START` section naming the
  contested wording and what happens if the amendment lands first — for
  `unsupervised-endurance` the answer is "this plan needs rewriting, not
  just re-reading", because the live text and the amendment make that run
  measure different things.
- **The human gates are stated IN the plans, not only as `needs:` edges.** A
  `needs:` edge stops the queue offering them early; it does not tell the
  session that took them that flipping `joharness.conf` is repo-wide, or
  that an hours-long fleet is a multiple of the $14.92 the 53-minute run
  cost. Both are things `.agents/harness/AGENTS.md` says to stop and ask
  about.
- **The three declined limits are named as out of scope in both measurement
  plans** — no spend cap, no halt on red `main`, no ban on sessions spawning
  sessions, declined by the requester 2026-08-24. A decomposing session must
  not add them back on its own judgment, and the plan a later session reads
  is where that has to be said.
- **`shared:joharness.sh`** on the two mechanism plans. They genuinely both
  touch it, so the wave line names an expected reconcile rather than
  claiming an independence they do not have.

## Rejected

- **A plan to resolve the amendment.** A requirement is the human's; the
  branch's own reasoning is that sessions may not write requirements.
- **Filing the two measurement plans as free.** They would be offered to a
  session that cannot start them without a decision nobody has made.

## Review

Round 1, opus, self.

- r1: I nearly wrote a plan for the protocol-boundary bullet from the
  requirement's own alarming wording about #114. Checked: #114 is CLOSED as
  completed by merged PR #118. (fixed — no plan; the check is recorded above
  so the next reader does not redo it)
- r2: the dedupe constraint reads like description and is actually an
  unimplemented requirement. Found by grepping for it, not by reading it —
  reading it four times had not told me nothing implemented it. (recorded)
- r3: first draft gave the measurement plans no `needs:` edges, which would
  have put two plans in the queue that no session can start. (fixed — the
  DAG makes them blocked until the mechanism lands, which is also true on
  the merits)
- r4: `graph lint` counts 4 plans and calls the edges sound, but the queue
  hook reads `origin/main`, so the wave partition these `scope:` lines
  produce cannot be seen until this merges. The `shared:` marking is
  therefore reasoned, not observed. (recorded — first reader after the merge
  should check the wave line says what this expects)
- r5: verifier round owed and NOT run — standing instruction, fifteenth
  consecutive edge.

## Blockers

None for this merge. Both measurement plans are blocked on a human decision
and say so in their own text.
