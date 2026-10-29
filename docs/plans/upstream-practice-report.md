---
plan: upstream-practice-report
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: .claude/commands/upstream-report.md, .agents/docs/feedback.md
---

## Goal

The upstream channel carries bugs, but it has no route for practices. gx
has filed 18 "Report from gx" pull requests on joharness (2026-09-12 to
2026-10-28), and 16 merged. Every one concerns a harness file, because
`/upstream-report` only reports findings that `./joharness.sh upstream`
places on a file canonical owns.

The practices gx invented live in consumer-owned files, so they never
qualify. Examples:

- the measuring rules in `AGENTS.md` Part 2 (now `measure-once-per-head`);
- the wrong-reason test shapes in `docs/rules/` (now
  `verifier-wrong-reason-lenses`);
- allocating ADR and criterion numbers at merge time, with a renumber
  audit.

This session found them only by reading gx by hand. Add a second report
kind: a consumer-local rule proposed for the harness.

## Scope

- `.claude/commands/upstream-report.md` — a `practice` mode:
  `/upstream-report practice <path>[:<heading>]`.
  - The reporter reads the named rule in the consumer's own files.
  - It checks that the rule names no consumer-specific stack, or can be
    restated without one.
  - It checks the canonical does not already carry it (grep, and quote
    the result).
  - It files ONE report pull request on canonical. The PR adds a plan
    file in canonical's `docs/plans/` with all seven sections, citing the
    consumer path and the measurement behind the rule.
  - Preconditions are the same as edge mode: `authority`, and the
    `canonical :` address.
  - A rule with no measurement behind it is not reported. Say so and stop.
- `.agents/docs/feedback.md` § When the consumer is the detector — one
  paragraph: practices are reported by hand in `practice` mode. Name what
  qualifies: generic, measured, and absent from canonical.

## Assumptions

- A1: edge mode reports only canonical-owned paths — evidence:
  `.claude/commands/upstream-report.md` (§ 0 and § 1),
  `joharness.sh:cmd_upstream` — confidence: high.
- A2: none of the 18 gx reports carried a practice — evidence: GitHub PR
  search on chrsctl/joharness for "Report from" gx, read 2026-10-29 —
  confidence: medium.

## Out of scope

- Any `joharness.sh` change. Practice mode is a procedure, and `upstream`
  keeps its edge-only meaning.
- Spawning practice reports automatically, or from a detector. Intake is
  by hand (`.agents/docs/plans.md`, Lifecycle: "no session writes a plan
  from a detector").
- Reporting the three practices named in the Goal. Two already have
  plans; the third is a candidate for the first real use.

## Acceptance

- `grep -n 'practice' .claude/commands/upstream-report.md` — the mode,
  its preconditions and its stop conditions are present.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed.

## Where to look

- `.claude/commands/upstream-report.md` — today's edge procedure. Mirror
  its numbered shape.
- `.agents/docs/feedback.md` — § When the consumer is the detector.
- `.agents/docs/plans.md` — § Shape, which the report's plan must satisfy.

## Traps

- Name no consumer in `.agents/harness/`. This plan does not touch it;
  keep it that way.
- A report is a pull request on canonical, never a direct push.
