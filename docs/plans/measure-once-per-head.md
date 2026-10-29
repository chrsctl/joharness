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

gx learned three measuring rules the hard way, and they hold for any
consumer whose suites take minutes:

1. Merge `origin/main` first, then measure. Step 7 requires the branch to
   be 0 behind, so a measurement taken before the merge is paid twice.
2. A partial run says `SCOPED` and is never the pass.
3. A failure in code the diff does not touch is attributed by ONE paired
   run on `origin/main` (a `git worktree`), started at the same time as the
   branch's re-run, each on its own instance of any shared service. Red on
   `origin/main` too means it is not this branch's: file it, cite it, move
   on.

These rules are in gx `AGENTS.md` Part 2 (§ Commands, "One measurement pass
per head") and in gx `docs/rules/test-discipline.md` ("A baseline that
still holds the product diff measures nothing"). The harness says "all
green or not done" but gives no way to decide whose red a red is. Put the
rules in the harness's protocol text so every consumer gets them.

## Scope

- `.agents/docs/product.md` — new section `## Measuring a head`, placed
  after `## Branch flow`. It states the three rules above, in caveman style
  (`.agents/docs/caveman.md`), each with one line of why. It adds:
  - A stashed or partly reverted diff is no baseline: use a worktree on
    `origin/main`.
  - Search open issues before the paired run.
  - A red that repeats when run alone is real.
- `.agents/harness/AGENTS.md` Loop step 5 — add ONE sentence: "Merge
  `origin/main` before measuring; red outside the diff = one paired run on
  `origin/main` (`.agents/docs/product.md`, Measuring a head)." Fold it
  into an existing line if it fits; the file's line count may grow by at
  most one.

## Assumptions

- A1: nothing in the harness tells a session how to attribute a red
  outside its diff — evidence: `grep -rn 'paired\|origin/main.*worktree'
  .agents/docs .agents/harness/AGENTS.md` (no hit on this rule, checked
  2026-10-29) — confidence: medium (re-run the grep before building).
- A2: gx's wording and its measured cases — evidence: gx `AGENTS.md`
  § Commands ("One measurement pass per head"), gx
  `docs/rules/test-discipline.md` ("A baseline that still holds the
  product diff") — confidence: high.

## Out of scope

- Any `joharness.sh` change. No command enforces these rules in this plan.
- gx-specific numbers (minutes, shard counts, Postgres ports). The
  harness text names no consumer stack.
- Naming gx, or any consumer, in `.agents/harness/`. The layer rule forbids
  naming a specific environment there. Cite the rule, not its origin.

## Acceptance

- `./joharness.sh ci` — `ci: pass` (glossary and caveman lints included).
- `git diff --stat origin/main -- .agents/harness/AGENTS.md` — at most one
  line added.
- `grep -n '## Measuring a head' .agents/docs/product.md` — one hit.
- `./joharness.sh verify` — 0 failed.

## Where to look

- `.agents/docs/product.md` — § Branch flow, "Conflict at finish".
- `.agents/harness/AGENTS.md` — Loop step 5.
- `.agents/docs/caveman.md` — the style the text must follow.

## Traps

- Every line of `.agents/harness/AGENTS.md` loads into every session:
  rules only, why goes in `.agents/docs/`.
- Contested terms have one spelling (`.agents/docs/glossary.md`); `ci`
  fails on the others.
