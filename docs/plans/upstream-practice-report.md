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

The two routes that exist do not cover it: the clerk's UPSTREAM verdict
(`.claude/commands/clerk.md`) and `feedback.md` § 4's issue route both
file an issue, and both wait for someone to write one first. Practice
mode starts from the rule itself and files the research node canonical
schedules.

Add a second, hand-run report kind: a consumer-local rule proposed for the
harness. It files the same thing edge mode files: one research node.

## Scope

- `.claude/commands/upstream-report.md` — a `practice` mode,
  `/upstream-report practice <path>[:<heading>]` (`<heading>` = the
  heading's text as written, without the `#` marks), as `## 3. Practice
  mode`, between `## 2.` and `## Never`. No `:<heading>` = the whole file
  is one rule; a file holding many rules needs the heading. § 3 stands
  alone: it skips § 0 and § 1, and borrows only § 2's filing. The
  opening (frontmatter `description:` and the first two paragraphs,
  through "Not the queue…") names both modes in as few words as fit the
  budget (A3). The reporter:
  1. Runs `./joharness.sh authority` (VERIFIABLE, else stop) and
     `./joharness.sh upstream` with no argument. Practice mode reads only
     its `canonical :` line. `CANONICAL` = stop (this repo is the harness).
     No `canonical :` line (no fetched base branch, or no merge on it) = read
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
     - canonical already carries it: attach canonical first (§ 2's
       attach), grep the rule's key terms over ITS checkout's `AGENTS.md`,
       `.agents/` and `.claude/` — never this repo's synced copy, whose
       `AGENTS.md` Part 2 holds the rule itself; quote the command and its
       output, and cite the file and section of a hit.
  4. Files ONE report pull request on canonical as § 2 does (branch,
     `.agents/docs/research/TEMPLATE.md` shape, frontmatter, title
     `Report from <repo>: <the question>`), adding ONE research node
     (`docs/research/<stem>.md`). The node's `## Findings` cites the
     consumer path and the measurement; `graduates:` names the canonical
     file the rule would land in. The body names the rule's path and
     heading where § 2's names the edge, and the three stop checks passed
     where § 2's names the dropped count.
  - Edge mode's `## Never` list stays in force, including "Write
    `docs/product/` or `docs/plans/` in either repo".
- `.agents/docs/feedback.md` § When the consumer is the detector, `### 5.
  The manual report` — one paragraph appended: practices are reported by
  hand in practice mode, as a research node. What qualifies: generic,
  measured, absent from canonical. A practice is not a finding: § 8
  (a consumer's own findings) stays as is.

## Assumptions

- A1: edge mode reports only canonical-owned paths and files only a
  research node — evidence: `.claude/commands/upstream-report.md`
  (§ 0, § 2, `## Never`), `joharness.sh:cmd_upstream` — confidence: high.
- A2: in a consumer, `./joharness.sh upstream` with no argument prints
  `canonical :` iff a fetched `origin/<base>` carries a merge —
  evidence: `joharness.sh:cmd_upstream` (`is_canonical` returns first;
  `upstream_edge` fails before the `canonical :` printf) — confidence:
  high. Otherwise step 1's update.yml fallback.
- A3: `upstream-report.md` stays under its reading budget
  (`.agents/harness/selftest/reading-budget.sh`, `rb_bound
  upstream-report.md 5671`, cap +10%) — evidence: `wc -c` 3594 bytes —
  confidence: medium. Room is 6238 - 3594 = 2644 bytes for § 3 and the
  opening edit together; over = cut words, never raise the bound.

## Out of scope

- Any `joharness.sh` change.
- Spawning practice reports automatically, or from a detector.
- Filing a plan or a requirement from a report.

## Acceptance

- `grep -c '^## .*[Pp]ractice' .claude/commands/upstream-report.md` —
  `1` or more, and that section contains the three stop conditions of
  Scope step 3 and the `CANONICAL` and no-`canonical :` cases of step 1.
  Read it: one missing = not done.
- `sed -n '/^## Never/,$p' .claude/commands/upstream-report.md | grep -c
  'docs/plans/'` — `1`: the line `- Write \`docs/product/\` or
  \`docs/plans/\` in either repo` still stands under `## Never`. `0` = not
  done.
- `sed -n '/^### 5\./,/^### 6\./p' .agents/docs/feedback.md | grep -c
  practice` — `1` or more. `0` = not done.
- `bash .agents/harness/selftest.sh` — `0 failed` (covers the reading
  budget). Any failure = not done.
- `./joharness.sh ci` — a line starting `ci: pass` (a `shellcheck
  SKIPPED` note counts: this plan edits no shell). Anything else = not
  done.
- `./joharness.sh verify` — `0 failed`. Anything else = not done.
- Consumer-side (SHIPS; run in a consumer after its next sync, not a
  gate on this pull request): `grep -c '^## 3\. Practice mode'
  .claude/commands/upstream-report.md` — `1`, and its `./joharness.sh ci`
  prints a line starting `ci: pass`.

## Where to look

- `.claude/commands/upstream-report.md` — the edge procedure and
  `## Never`. Mirror its numbered shape.
- `.agents/docs/feedback.md` — § When the consumer is the detector.
- `.agents/docs/research.md` — § Shape, which the filed node must satisfy.
- `joharness.sh:cmd_upstream`, `joharness.sh:upstream_canonical_repo`.

## Traps

- A report is a pull request on canonical, never a direct push.
- Name no consumer in `.agents/harness/`.
