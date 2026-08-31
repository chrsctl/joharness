---
workstream: plan-provenance
status: review
branch: claude/plan-provenance
pr: none
plan: docs/plans/unsupervised-plan-provenance.md
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Retire this file and the plan, open the pull request, merge.
---

## Goal

Two halves of the goal bound that nothing enforced. The load-bearing one:
an unsupervised session could write itself a requirement, and a fleet with a
finish line it authored has none — so PR 170's goal-reached stop was only as
strong as an unenforced sentence.

## Decisions

- **In `ci`, not in `handover-guard.sh`, and the asymmetry is deliberate.**
  The guard reports facts at turn end and does not prevent — its documented
  shape, which the requirement's Constraint keeps. But a report does not stop
  a merge, and a self-written goal reaching the base branch is where the
  damage lands. Step 7 requires green checks, so `ci` is the gate that holds.
- **ADDED, never edited.** PR 163 annotated a `Satisfied when` bullet with a
  measured result while unsupervised — the mode reporting its own results. A
  guard catching that would stop exactly the feedback the requirement asks
  for.
- **The staleness failure is CHOSEN, not discovered.** `advances:` carries a
  FRAGMENT of the bullet text and the lint checks it still appears. An index
  rots SILENTLY the moment a bullet is inserted above it — pointing at the
  wrong bullet while linting green. A fragment rots LOUDLY: reword the bullet
  and this reds, which is a session's cue to re-read what it serves. Noisier,
  and the noise is the point. The plan's Trap asked for this to be decided
  rather than stumbled into.
- **`advances:` fires only on a plan that HAS a `requirement:`.** A plan
  recorded with no goal open names neither, because there is nothing to name
  — the rule PR 171 restored, and a case pins it.
- **Not by widening `protocol_paths`.** `docs/product/` is not protocol text;
  the boundary's own Constraint says the rule is the role. A different guard
  with a different reason.

## Rejected

- **Reporting rather than redding**, to match the guard's shape. A report a
  session can stop through does not stop a self-written goal from merging,
  and that is the one thing this must stop.

## Review

Round 1, opus, self, with `mutate`.

- r1: **the directory trap, for the third time this session.** Two writes into
  `docs/plans` landed nowhere because a `git rm` had taken the last file and
  git dropped the directory, so two cases asserted against files that were
  never written. `write_ws` guards `docs/handover` and NOTHING guards
  `docs/plans` — that asymmetry is why this keeps happening, and it is worth
  a helper. (fixed here with `mkdir -p` and the reason; the helper is not
  this plan's scope and is recorded rather than smuggled in)
- r2: **a mutation that broke syntax rather than testing behaviour.** Line
  2259 is the first line of a multi-line `printf`, so replacing it corrupted
  the script and redded the `mutate` topic's own unrelated cases. That is the
  invalid-mutation reading PR 153 recorded and PR 160 hit again — third
  instance. (fixed — mutated the comparison itself, which reds exactly the
  two staleness cases)
- r3: shellcheck caught backticks inside a single-quoted `printf` (SC2016),
  again. Second time in three branches. The message text wants backticks and
  the quoting forbids them; I keep writing the former. (fixed)
- r4: my first assertion for the authorship message used a lowercase needle
  against a capitalised sentence, so it could never match. Re-aimed at the
  load-bearing phrase rather than patched to match the case. (fixed)
- r5: I nearly ran four full `ci` invocations in one probe and timed the
  command out at ten minutes. The fixtures exist because `ci` on the real
  tree is not a probe. (recorded — the cases were written first thereafter)
- r6: verifier round owed and NOT run — standing instruction, twenty-sixth
  consecutive edge. (wontfix on this branch — issue #168)

## Verification

- `mutate` the mode gate (check every mode) → reds **5**
- `mutate` the additions filter (count edits as adds) → reds **2**
- `mutate` the missing-`advances` branch → reds **2**
- `mutate` the fragment comparison (always match) → reds **2**
- `ci: pass`; `verify` 6 passed, 0 failed; selftest **1128 passed, 0 failed**
  (up 15)

## Blockers

None.
