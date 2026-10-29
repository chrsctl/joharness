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

The verifier produces 69% of review findings in gx (3,298 of 4,747 review
lines since 2026-10-10). About 210 of those were weak tests: a test that
stays green with the fix removed, or one that could never fail.

gx wrote down the shapes that produce this in `docs/rules/test-discipline.md`,
under "Green for the wrong reason has shapes". Their unifying rule is that
an assertion establishes a property only if it can tell that property
apart from its absence. The same file gives two companion rules:

- Prove a new check can fail by injecting the defect.
- A hang or a dead suite is a third state, neither red nor green.

None of these shapes are language-specific. The harness verifier carries
none of them, so each consumer has to rediscover them. Give the verifier
these lenses.

## Scope

- `.claude/agents/verifier.md` — new section
  `## Green for the wrong reason`, after `## What a finding is`. Content:
  - the unifying rule;
  - one line per shape, generic, with no consumer's names: the assertion
    reaches a path the fix did not change; the assertion could never pass
    or never fail; a stashed or partly reverted baseline; a fixture on the
    wrong side of the injection;
  - a check added by the branch is a finding unless the branch shows it
    red without the fix;
  - a suite that hangs or dies is not green.

  At most 25 added lines.

## Assumptions

- A1: `verifier.md` has no wrong-reason lens today — evidence:
  `grep -n 'wrong reason\|inject' .claude/agents/verifier.md` (no hit
  expected) — confidence: medium (run the grep first).
- A2: the shapes are generic — evidence: gx
  `docs/rules/test-discipline.md` ("Green for the wrong reason has
  shapes", "A new check needs the same suspicion", "a suite can HANG",
  "a suite can DIE") — confidence: high.
- A3: weak tests are a large class — evidence: about 210 weak-test review
  lines in gx workstream files recovered from history, 2026-10-29 —
  confidence: medium (keyword classification).

## Out of scope

- Copying gx's examples (Postgres, browsers, `/dev/shm`). Name the shape,
  not the stack.
- Changing the verifier's tools, tier or report format.
- Adding the same text to `AGENTS.md`. The verifier file is its home.

## Acceptance

- `grep -c '## Green for the wrong reason' .claude/agents/verifier.md` —
  `1`.
- `git diff --numstat origin/main -- .claude/agents/verifier.md` — at
  most 25 added lines.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed.

## Where to look

- `.claude/agents/verifier.md` — § What a finding is, § Did the branch do
  what it was for.
- gx `docs/rules/test-discipline.md` — the source shapes. Read them on
  GitHub (chrsctl/gx) if gx is not cloned.

## Traps

- NEVER skip, disable or quarantine a test to get green. The lens exists
  to catch the subtler version of that.
- Name no consumer in harness text.
