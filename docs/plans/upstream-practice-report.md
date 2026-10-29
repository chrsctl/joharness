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
  `/upstream-report practice <path>[:<heading>]` (`<heading>` = the
  heading's text as written, without the `#` marks), as `## 3. Practice
  mode`, between `## 2.` and `## Never`. The reporter:
  1. Runs `./joharness.sh authority` (VERIFIABLE, else stop) and
     `./joharness.sh upstream` with no argument. Practice mode reads only
     its `canonical :` line. `CANONICAL` = stop (this repo is the harness).
     No `canonical :` line (no merge on the base branch yet) = read
     `CANONICAL_REPO` from `.github/workflows/update.yml`, as
     `upstream_canonical_repo` does. `UNKNOWN` or none found = stop.
  2. Reads the named rule in the consumer's own files.
  3. Stops, saying so, when any of these holds:
     - the rule names a consumer-specific stack (a language, framework,
       service or file layout only this consumer has) and cannot be
       restated without it;
     - no measurement stands behind it: a command and its output, or a
       recorded incident whose record carries one (edge mode's `## Never`:
       no report with no measurement);
     - canonical already carries it (grep canonical, quote the command
       and its output).
  4. Files ONE report pull request on canonical exactly as § 2 does
     (attach, branch, `.agents/docs/research/TEMPLATE.md` shape, frontmatter,
     title `Report from <repo>: <the question>`), adding ONE research node
     (`docs/research/<stem>.md`). It cites the consumer path and the
     measurement; `graduates:` names the canonical file the rule would
     land in.
  - Edge mode's `## Never` list stays in force, including "Write
    `docs/product/` or `docs/plans/` in either repo".
- `.agents/docs/feedback.md` § When the consumer is the detector, `### 5.
  The manual report` — one paragraph appended: practices are reported by
  hand in practice mode, as a research node. What qualifies: generic,
  measured, absent from canonical.

## Assumptions

- A1: edge mode reports only canonical-owned paths and files only a
  research node — evidence: `.claude/commands/upstream-report.md`
  (§ 0, § 2, `## Never`), `joharness.sh:cmd_upstream` — confidence: high.
- A2: `./joharness.sh upstream` with no argument prints `canonical :` —
  evidence: `joharness.sh:cmd_upstream` (usage allows zero arguments; the
  `canonical :` printf) — confidence: medium. Run it in a consumer before
  building. If it does not print the line, read `CANONICAL_REPO` from
  `.github/workflows/update.yml`, as `upstream_canonical_repo` does.
- A3: `upstream-report.md` stays under its reading budget
  (`.agents/harness/selftest/reading-budget.sh`, `rb_bound
  upstream-report.md 5671`, cap +10%) — evidence: `wc -c` 3594 bytes —
  confidence: medium. The section fits in about 2600 bytes; over = cut
  words, never raise the bound.

## Out of scope

- Any `joharness.sh` change.
- Spawning practice reports automatically, or from a detector.
- Filing a plan or a requirement from a report.

## Acceptance

- `grep -c '^## .*[Pp]ractice' .claude/commands/upstream-report.md` —
  `1` or more, and that section contains the three stop conditions of
  Scope step 3 and the `CANONICAL` and no-`canonical :` cases of step 1.
  Read it: one missing = not done.
- `grep -n 'docs/plans/' .claude/commands/upstream-report.md` — still
  matches `- Write \`docs/product/\` or \`docs/plans/\` in either repo,
  or touch anything`, under `## Never`. No match = not done.
- `grep -c 'practice' .agents/docs/feedback.md` — `1` or more, inside
  `### 5. The manual report`. `0` = not done.
- `grep -n '\.claude/commands' .agents/scripts/sync-to-consumer.sh` — a
  match: the command file ships to consumers with the next sync. No
  match = not done.
- `bash .agents/harness/selftest.sh` — `0 failed` (covers the reading
  budget). Any failure = not done.
- `./joharness.sh ci` — `ci: pass`. Anything else = not done.
- `./joharness.sh verify` — `0 failed`. Anything else = not done.

## Where to look

- `.claude/commands/upstream-report.md` — the edge procedure and
  `## Never`. Mirror its numbered shape.
- `.agents/docs/feedback.md` — § When the consumer is the detector.
- `.agents/docs/research.md` — § Shape, which the filed node must satisfy.
- `joharness.sh:cmd_upstream`, `joharness.sh:upstream_canonical_repo`.

## Traps

- A report is a pull request on canonical, never a direct push.
- Name no consumer in `.agents/harness/`.
