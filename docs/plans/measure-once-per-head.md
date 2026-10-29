---
plan: measure-once-per-head
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
serves: all
issue: none
scope: .agents/docs/product.md, .agents/harness/AGENTS.md
---

## Goal

The harness says "all green or not done", but it gives no way to decide
whose red a red is. gx learned two measuring rules that answer this for
any consumer whose suites take minutes:

1. **A failure in code the diff does not touch is attributed by ONE paired
   run.** Search the open issues first. Then run the same suite on
   `origin/main` in a `git worktree`, at the same time as the branch's
   re-run, each on its own instance of any shared service. Red on
   `origin/main` too means it is not this branch's: file it, cite it, move
   on. A stashed or partly reverted diff is no baseline.
2. **A partial run says `SCOPED` and is never the pass.** A red that
   repeats when run alone is real.

Sources: gx `AGENTS.md` Part 2 (§ Commands, "One measurement pass per
head"), and gx `docs/rules/test-discipline.md` ("A baseline that still
holds the product diff measures nothing").

Merge-before-finish is already harness law (Loop steps 3 and 7). This plan
adds one corollary: measure after that merge, not before it.

## Scope

- `.agents/docs/product.md` — new section `## Measuring a head`, placed
  after `## Branch flow`.
  - It states the two rules above and the corollary, in caveman style
    (`.agents/docs/caveman.md`), each with one line of why.
- `.agents/harness/AGENTS.md` Loop step 5 — add ONE sentence: "Red outside
  the diff = one paired run on `origin/main` (`.agents/docs/product.md`,
  Measuring a head)."
  - Fold it into an existing line if it fits.
  - The file may grow by at most one line.

## Assumptions

- A1: nothing in the harness tells a session how to attribute a red
  outside its diff — evidence: `grep -rn 'paired' .agents/docs
  .agents/harness/AGENTS.md` (no hit on this rule, 2026-10-29) —
  confidence: high (a plan-checker re-ran it).
- A2: `.agents/harness/AGENTS.md` has room in its reading budget —
  evidence: 6459 of 7228 bytes, measured by the plan-checker 2026-10-29
  — confidence: high.

## Out of scope

- Any `joharness.sh` change. No command enforces these rules.
- gx-specific numbers (minutes, shard counts, ports).
- Naming gx, or any consumer, in `.agents/harness/`.

## Acceptance

- `grep -c '^## Measuring a head' .agents/docs/product.md` — `1`.
- `git diff --numstat origin/main -- .agents/harness/AGENTS.md` — added
  minus deleted is at most `1`.
- `bash .agents/harness/selftest.sh` — `0 failed` (reading budgets
  included).
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Consumer-side check (this plan SHIPS): after the sync, a consumer's
  `./joharness.sh ci` passes, and its `.agents/docs/product.md` carries
  the section.

## Where to look

- `.agents/docs/product.md` — § Branch flow, "Conflict at finish".
- `.agents/harness/AGENTS.md` — Loop step 5.
- `.agents/docs/caveman.md` — the style the text must follow.

## Traps

- Every line of `.agents/harness/AGENTS.md` loads into every session:
  rules only, why goes in `.agents/docs/`.
- Contested terms have one spelling (`.agents/docs/glossary.md`); `ci`
  fails on the others.
