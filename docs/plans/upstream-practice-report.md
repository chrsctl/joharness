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

The upstream channel carries bugs, but it has no route for practices.
gx's "Report from gx" pull requests on joharness all concern harness
files, because `/upstream-report` reports only findings that
`./joharness.sh upstream <edge>` places on a file canonical owns.

The practices gx invented live in consumer-owned files (`AGENTS.md` Part 2,
`docs/rules/`, `scripts/`), so they never qualify. Two of them reached the
queue (`measure-once-per-head`, `verifier-wrong-reason-lenses`) only
because a session read gx by hand.

Add a second, hand-run report kind: a consumer-local rule proposed for the
harness. It files the same thing edge mode files: one research node.

## Scope

- `.claude/commands/upstream-report.md` — a `practice` mode,
  `/upstream-report practice <path>[:<heading>]`, as a new numbered
  section after the edge procedure. The reporter:
  1. Runs `./joharness.sh authority` (VERIFIABLE, else stop) and
     `./joharness.sh upstream` with no argument. Practice mode reads only
     its `canonical :` line; `UNKNOWN` = stop.
  2. Reads the named rule in the consumer's own files.
  3. Stops, saying so, when any of these holds:
     - the rule names a consumer-specific stack and cannot be restated
       without it;
     - no measurement or recorded incident stands behind it;
     - canonical already carries it (grep canonical, quote the command
       and its output).
  4. Files ONE report pull request on canonical, adding ONE research node
     (`docs/research/<stem>.md`, all nine sections of
     `.agents/docs/research.md` § Shape). It cites the consumer path and
     the measurement, and names the canonical file the rule would
     graduate to.
  - Edge mode's `## Never` list stays in force, including "Write
    `docs/product/` or `docs/plans/` in either repo".
- `.agents/docs/feedback.md` § When the consumer is the detector — one
  paragraph: practices are reported by hand in practice mode, as a
  research node. What qualifies: generic, measured, absent from canonical.

## Assumptions

- A1: edge mode reports only canonical-owned paths and files only a
  research node — evidence: `.claude/commands/upstream-report.md`
  (§ 0, § 2, `## Never`), `joharness.sh:cmd_upstream` — confidence: high.
- A2: `./joharness.sh upstream` with no argument prints `canonical :` —
  evidence: `joharness.sh:cmd_upstream` (usage allows zero arguments; the
  `canonical :` printf) — confidence: medium. Run it in a consumer before
  building. If it does not print the line, read `CANONICAL_REPO` from
  `.github/workflows/update.yml`, as `upstream_canonical_repo` does.

## Out of scope

- Any `joharness.sh` change.
- Spawning practice reports automatically, or from a detector.
- Filing a plan or a requirement from a report.

## Acceptance

- `grep -c '^## .*[Pp]ractice' .claude/commands/upstream-report.md` —
  `1` or more, and that section contains the three stop conditions of
  Scope step 3. Read it: a stop condition missing = not done.
- `grep -n 'docs/plans/' .claude/commands/upstream-report.md` — still
  matches the `## Never` line (unchanged).
- `bash .agents/harness/selftest.sh` — `0 failed`.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Consumer-side check (this plan SHIPS): after the sync, a consumer's
  `/upstream-report` command file carries the practice section, and its
  `./joharness.sh ci` passes.

## Where to look

- `.claude/commands/upstream-report.md` — the edge procedure and
  `## Never`. Mirror its numbered shape.
- `.agents/docs/feedback.md` — § When the consumer is the detector.
- `.agents/docs/research.md` — § Shape, which the filed node must satisfy.
- `joharness.sh:cmd_upstream`, `joharness.sh:upstream_canonical_repo`.

## Traps

- A report is a pull request on canonical, never a direct push.
- Name no consumer in `.agents/harness/`.
