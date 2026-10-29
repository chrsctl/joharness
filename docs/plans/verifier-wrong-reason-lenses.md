---
plan: verifier-wrong-reason-lenses
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: .claude/agents/verifier.md
---

## Goal

The verifier writes most review findings in gx: 3,108 of 4,816 unique
`- rN:` lines since 2026-10-10 carry `(verifier)`. gx wrote down the
shapes of a test that is green for the wrong reason in
`docs/rules/test-discipline.md`. Their unifying rule: an assertion
establishes a property only if it can tell that property apart from its
absence.

The harness verifier already has UNVERIFIED and STUB, and Loop step 5
already says a test for a fix must FAIL without it. It lacks these shapes:

- the assertion reaches a path the fix did not change;
- a stashed or partly reverted baseline still holds the product diff;
- the injected defect sits on the wrong side of the fixture;
- a suite that hangs or dies is neither red nor green.

Add only those, within the file's reading budget.

## Scope

- `.claude/agents/verifier.md` — add the four shapes above as one short
  block, under `## Did the branch do what it was for` beside STUB.
  - One line each, generic, with no consumer's names.
  - Total growth at most 800 bytes: `reading-budget.sh` bounds this file
    at 6211 bytes + 10% = 6832, and the file is 6013 bytes today.

## Assumptions

- A1: `verifier.md` has no wrong-reason lens today — evidence:
  `grep -n 'wrong reason\|inject' .claude/agents/verifier.md` (no hit,
  2026-10-29) — confidence: high.
- A2: room in the budget is 819 bytes — evidence:
  `wc -c .claude/agents/verifier.md` = 6013;
  `.agents/harness/selftest/reading-budget.sh` (`rb_bound verifier.md
  6211`) — confidence: high.
- A3: the shapes are generic — evidence: gx
  `docs/rules/test-discipline.md` ("Green for the wrong reason has
  shapes", "A baseline that still holds the product diff", "a suite can
  HANG", "a suite can DIE") — confidence: high.

## Out of scope

- Raising the reading budget. If four lines do not fit, cut wording, not
  shapes.
- Copying gx's examples (Postgres, browsers, `/dev/shm`).
- Changing the verifier's tools, tier or report format.

## Acceptance

- `wc -c .claude/agents/verifier.md` — at most 6832.
- `grep -c 'wrong side\|hang' .claude/agents/verifier.md` — at least `2`.
- `bash .agents/harness/selftest.sh` — `0 failed` (the reading-budget
  topic included; it reds when the file passes its bound).
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Consumer-side check (this plan SHIPS): after the sync, a consumer's
  `.claude/agents/verifier.md` matches canonical's, and its
  `./joharness.sh ci` passes.

## Where to look

- `.claude/agents/verifier.md` — § Did the branch do what it was for
  (UNVERIFIED, STUB).
- `.agents/harness/selftest/reading-budget.sh` — the bound.
- gx `docs/rules/test-discipline.md` — the source shapes (chrsctl/gx on
  GitHub, if gx is not cloned).

## Traps

- NEVER skip, disable or quarantine a test to get green.
- Name no consumer in harness text.
