---
workstream: harness-glossary
status: review
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: harness-glossary
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: verify, retire plan + workstream, PR, merge
---

## Goal

Plan `docs/plans/harness-glossary.md`: the same node has two names in files
every session loads. The glossary fixes each contested term, names the
wordings that are not it, and a lint stage keeps it from rotting into a wish.

## Decisions

- Counts RE-COUNTED here before any of them ship, because the plan's own
  figures had already drifted twice and it says so:
  `grep -rnoi "<term>" --include=*.md --include=*.sh . | grep -v '^./.git' | wc -l`
  on 2026-08-28 gives workstream file 205 against its older spelling 14,
  agent tier 10 against its older spelling 6, environment layer 24 against
  its older spelling 5. The plan quoted 146 / 12
  at 2026-08-24 and noted 208 by 2026-08-27. Nothing here quotes a figure
  without that command beside it.
- Files using BOTH spellings of the workstream-file term today: eight, not
  the five the plan names — `docs/plans/fork-seam-rules.md`, this plan, and
  `docs/research/glossary-enforcement.md` joined since it was written.
- The lint SCANS WHAT CANONICAL OWNS AND SYNCS, not the tree: the exact list
  is `joharness.sh:GLOSSARY_PATHS` — `.agents/docs`, `.agents/harness`,
  `.agents/scripts`, `.agents/env/README.md`, `.claude/commands`,
  `.claude/skills`, `joharness.sh`, plus `AGENTS.md` and `CLAUDE.md`. The
  plan said "a tracked `*.md` or `*.sh` file" and that is a live hazard: a
  whole-tree scan means a harness sync reds a consumer's ci over the
  consumer's own product prose, which the consumer cannot fix by editing the
  glossary (that would make the file AHEAD on every future sync). The two
  root files are in anyway — a consumer edits Part 2 in place, and they are
  what every session loads. `.agents/env/<layer>/` is OUT: the sync ships a
  layer only when canonical carries one by that name, so a consumer's own
  layer is the consumer's prose. Narrowing beat a canonical-only gate, which
  would leave the rule unenforced exactly where a synced hit appears and
  could not be exercised without teaching the fixture to fake a canonical
  marker.
- Records are therefore untouched rather than exempted by name. An earlier
  cut rewrote `docs/research/glossary-enforcement.md`'s measured wording and
  the plan's own figures to satisfy the lint; both are restored verbatim
  from `origin/main`. A lint that edits the evidence it was built on is
  worse than no lint.
- The plan's third acceptance criterion — a whole-tree grep returning 0
  outside the glossary — is SUPERSEDED, not met, and deliberately. Records
  under `docs/` keep the wordings they measured. The criterion that replaced
  it: 0 inside the scanned scope, which `ci` now enforces on every run.
  Demonstrated failure, per the plan's last criterion:

  ```
  == glossary
    .agents/docs/_tmp_demo.md:1:The handover file is the claim.
    ^ says "handover file"; this repo says "workstream file" (.agents/docs/glossary.md)
  ```

  `ci` exits 1 on it.

## Rejected

- ADOPTING Vale rather than building. `docs/research/glossary-enforcement.md`
  refuted the plan's implied "no prior art": Vale's `accept.txt` plus
  `Vale.Terms` is exactly this mechanism, running at Datadog and Elastic, and
  the research left adopt-or-build open for this plan. Built: that is a Go
  binary in a `ci` whose whole toolchain is shell and shellcheck, installed
  into every consumer and a sandbox behind an egress allowlist, for three
  substitutions. Recorded because "we invented it" would be false.
- A marker comment to exempt a file that must name what it bans. The plan
  forbids it and the reason showed up immediately: the exemption would have
  had to spread to the selftest fixture too. The fixture ASSEMBLES the banned
  wording at runtime instead, so exactly one path stays exempt.
- Restating the ban list in the lint. It reads the glossary's own table, so
  the list cannot rot against the file that publishes it — the defect this
  whole stage exists to catch.

## Review

Opus tier, adversarial, two lenses per round on the full branch diff.

Round 1 — correctness lens:
- r1.1 The awk parser enforced whatever looked like a table row: a GFM
  alignment row banned `---` repo-wide, a second table anywhere in the file
  became a second ban list, a renamed first column turned the header into a
  ban, and an escaped pipe inside a cell shifted the columns so the real ban
  vanished and a fragment took its place. Fixed: one table, entered only
  under the `Canonical`/`Not this` header, `NF != 6` reported as MALFORMED
  and red — never quiet.
- r1.2 `rc` was set inside a `printf | while` pipeline, so it never escaped
  the subshell: every hit printed and `ci` stayed green. Fixed with a
  `mktemp` marker file read after the loop.
- r1.3 `git grep` without `-F` read a banned wording as a pattern. Fixed.
- r1.4 A row banning several comma-separated wordings searched for the
  literal `"a, b"` — a ban that looks live and is dead. Fixed by splitting
  on commas and trimming.
- r1.5 A non-git checkout printed the green line for a scan that never ran.
  Fixed: it says so and passes.

Round 1 — doctrine lens:
- r1.6 Whole-tree scan reds a consumer's ci over prose the consumer cannot
  fix. Fixed by scoping (see Decisions).
- r1.7 The sweep REWROTE recorded measurements to satisfy the lint —
  `docs/research/glossary-enforcement.md`'s counted wording, the plan's
  own `146 / 12` figures, and the plan's acceptance grep, which it inverted
  into a grep for the canonical term. All restored verbatim from
  `origin/main`; they now sit outside the scan.
- r1.8 The `agent tier` gloss defined the term using the wording that row
  bans ("which model tier implements a plan"). Rewritten to name the three
  tiers.
- r1.9 The glossary quoted counts with no date, and the numbers were
  pre-sweep. Now dated, attributed to the surviving record, and the section
  says outright that a re-count returns zero because the lint works — not
  because it is evidence.
- r1.10 "One meaning, or a named zone" promised a zone split the four-column
  table had no way to express. The rule now says how: two rows, each
  `Canonical` cell carrying its zone.
- r1.11 Nothing a session loads pointed at the glossary. One line added to
  `.agents/harness/AGENTS.md` beside the house-style pointer.
- r1.12 `.agents/docs/handover/README.md` carried the banned wording split
  across a line break, which a line-based lint can never catch. Rewritten.

Round 2 — correctness lens (both lenses opened on the same defect first):
- r2.1 FAIL-OPEN. Rename the header, drop the table, or leave it with no
  rows, and every ban evaporated while the stage printed its green line —
  output byte-identical to a clean tree. The one defect that makes the whole
  stage a wish. NOHEADER / NOROWS are reported and red now.
- r2.2 A second table under a repeated header re-armed the parser and became
  a second ban list. The glossary's own zone-split section is exactly the
  shape someone would illustrate with one. First table only.
- r2.3 GFM makes the outer pipes optional. A legal row written without them
  ENDED the table, killing every ban below it, silently. Rows are normalised
  before splitting.
- r2.4 A row with an empty `Not this` was dropped with no word — a ban
  rotting to a no-op, which is the defect this stage exists to catch.
  MALFORMED now.
- r2.5 `git grep` exits 1 on no-match and 128 on error; `2>/dev/null || :`
  collapsed both into "found nothing" and printed the green line. Reported
  with git's own words, and red. Reachable from a fixture only through a
  stub `git`, which the suite now carries.
- r2.6 The exemption regex was built from a path unescaped and unanchored, so
  it also exempted `glossary.mdx` and `glossaryXmd`.
- r2.7 Unchecked `mktemp` fails the stage open on a full `TMPDIR`.
- r2.8 A file written this turn was invisible until committed — green ci, red
  after the commit. `--untracked`.
- r2.9 SEVEN mutations survived the round-1 suite: deleting the MALFORMED
  gate, dropping `-F`, dropping the alignment-row skip, dropping the header
  check, dropping the comma split, dropping the ban trimming, and replacing
  the non-git message with the green line. All seven passed 14/14. The suite
  is now 15 mutations wide and every one is caught; the baseline is clean.
  Measured 2026-08-28 by patching a copy of `joharness.sh` and re-running
  this step against it.

Round 2 — doctrine lens:
- r2.10 Scope still reached prose the harness does not own. Root `*.md` is a
  consumer's own README, and `.agents/env/<their layer>/` is never synced —
  the sync adds a layer to DIRS only for one canonical carries — so both were
  unfixable reds after a routine sync. Scope is now canonical-owned synced
  paths plus `AGENTS.md` and `CLAUDE.md`, which a consumer edits in place.
- r2.11 And it MISSED `.claude/commands/` and `.claude/skills/`, which do
  sync — this branch's own fix to `.claude/commands/handover.md` could have
  been reverted with ci staying green — plus uppercase extensions and the
  extensionless markers. The extension filter is gone.
- r2.12 The header comment attributed "205 against 14" to the glossary's
  scoped command, which yields 131 against 8. Re-attributed to the whole-tree
  command that produces it, with the date.
- r2.13 The new stage was inserted ABOVE the graph lint's comment, so that
  paragraph explained the glossary and graph lint kept a stub.
- r2.14 The glossary and the lint comment stated the same four facts, and had
  already diverged — one copy carried a claim about `.agents/` that r2.10
  proves false. Rationale lives in the glossary; the comment points.
- r2.15 The zone-split rule could never be built: bans are substrings, so a
  zoned canonical (`retry (harness)`) contains its own ban (`retry`) and is
  unwritable. Rule replaced — a zone-split term gets NO row.
- r2.16 Comma splitting was undocumented, and a bare word bans every phrase
  containing it. Documented in the glossary, both facts.
- r2.17 Nothing under `.agents/` can quote a losing spelling — no rename
  note, no pasted failure. `docs/` is named as where records live, which is
  why it is out of scope.
- r2.18 The plan's `scope:` frontmatter understated three touched files, and
  `queue-context.sh` parses that field to print "parallel is proven".
  Amended. The three UNRELATED plan files this branch had also reworded are
  reverted — another plan's prose is not this one's to edit, and the wave
  model cannot represent that collision at all.
- r2.19 Acceptance criterion 3 amended in the plan itself, so the retiring
  plan and this record agree rather than contradict.
- r2.20 The glossary was the essay its own plan forbids: 31 prose lines for a
  3-row table, one section a third copy of a `caveman.md` rule. Cut.

Self-caught between rounds, recorded because it changed the design: the
canonical-only gate called an `is_canonical` that does not exist in this
file. `ci` caught it; the fix was to drop the gate for scoping (r1.6), which
is the better answer anyway.

## Blockers

None.

## Where to look

- `joharness.sh:lint_graph` — the stage shape a new lint copies.
- `.agents/docs/graph.md` Nodes — the closest thing to a canonical vocabulary.
- `docs/research/glossary-enforcement.md` — prior research for this plan.
