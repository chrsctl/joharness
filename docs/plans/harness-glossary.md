---
plan: harness-glossary
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: .agents/docs/glossary.md, joharness.sh, .agents/harness/selftest.sh, .agents/docs, .agents/harness/AGENTS.md, AGENTS.md, CLAUDE.md, README.md
---

## Goal

The same node has two names in the instruction files agents load every
session. Counted on this repo at plan time, `grep -rnoi <term> --include=*.md
--include=*.sh . | grep -v '^./.git' | wc -l`: "workstream file" 146,
"workstream file" 12, and five files use both — `.agents/docs/handover/README.md`,
`.agents/docs/plans/README.md`, `.agents/docs/product/README.md`,
`.claude/commands/handover.md`, `README.md`. Same split elsewhere:
"agent tier" 10 against "agent tier" 5, "environment layer" 18 against "env
layer" 2. Every one of those files is written for a literal reader, and the
Loop's own warning is that ambiguity gets executed wrong or asked back.
`kitchen-engineer42/joharnessburg` holds this line with `CONTEXT.md`, which
fixes each term and — the part worth copying — lists the wordings to
avoid, declaring itself the winner when older prose disagrees. Take the
avoid-list. Do not take the essay: this repo states each fact once
(`.agents/docs/caveman.md`), so the glossary indexes and points, it does
not redefine.

## Scope

- `.agents/docs/glossary.md` — new. One row per term: canonical spelling, a
  gloss no longer than one line, the file that defines it, the wordings
  that are not it. The gloss disambiguates; the pointer carries the
  meaning. A row that explains a term is a second copy of that term's
  definition and rots against the first.
- `joharness.sh` — a lint stage that fails when a listed non-canonical
  wording appears in a tracked `*.md` or `*.sh` file, so the glossary
  cannot rot into a wish. Beside `lint_graph`, reported like the
  other `ci` stages. The glossary file itself is the one place the
  non-canonical wordings are allowed to appear; exempt it by path, not by a
  marker comment that spreads.
- Instruction files carrying a non-canonical wording today — the five named
  above and whatever the new lint finds. Rewrite to the canonical term. A
  fix that only silences the lint by deleting a sentence loses a fact; the
  sentence keeps its meaning and changes its word.
- `.agents/harness/selftest.sh` — a fixture repo with a banned wording
  fails the lint, one without it passes, and the glossary's own rows do not
  trip it.

## Out of scope

- Choosing canonical terms by count alone. 146 against 12 settles
  "workstream file"; 10 against 5 does not settle "agent tier", and the
  frontmatter field is `agent`, which is the stronger evidence. Where the
  code names the thing, the code wins.
- Renaming anything in code: frontmatter field names, subcommands, function
  names, paths, `docs/handover/` itself. Prose only. A field rename breaks
  every consumer's synced harness and every open branch's frontmatter for a
  vocabulary win.
- Terms with one spelling. The glossary lists contested terms, not every
  noun in the harness; a full dictionary is context nobody pays for
  willingly.
- Restating rules. The glossary points at the file that holds the rule.
- Consumer repos' own prose. They sync the harness, not their own writing.

## Acceptance

- `.agents/docs/glossary.md` exists, every row's pointer resolves to a real
  file that really defines the term. Open each; a wrong pointer costs more
  than no pointer.
- `./joharness.sh ci` — `ci: pass`, with the new lint stage printing its
  own line whether or not it finds anything.
- `grep -rnoi "workstream file" --include=*.md --include=*.sh . | grep -v
  '^./.git' | wc -l` — 0 outside `.agents/docs/glossary.md`. Same for every
  other wording the glossary bans.
- Re-count the two headline pairs before quoting them anywhere that ships;
  the 146 / 12 / 10 / 5 / 18 / 2 figures were re-counted 2026-08-24 with the
  command above and drift fast ("workstream file" already 208 by
  2026-08-27, +42%) — they move with every merge.
- `./.agents/harness/selftest.sh` — passes, count higher by the tests added.
- The lint fails on a deliberately reintroduced banned wording, and the
  failure names the file, the line, and the canonical replacement. Paste
  it.

## Where to look

- `joharness.sh:lint_graph` — how a lint stage reads tracked files and
  reports; `joharness.sh:cmd_ci` — where stages are sequenced and `rc` is
  set.
- `.agents/docs/caveman.md`, "Never touch" — technical terms, API names and
  proper nouns are byte-exact, and code blocks are untouchable. A rename
  sweep runs straight at that rule.
- `.agents/docs/graph.md`, Nodes — the table already names the node types
  (Requirement, Plan, Workstream, Rule, Why-explanation, Change). That
  table is the closest thing to a canonical vocabulary this repo has; the
  glossary agrees with it or explains why not.
- `.agents/docs/handover/README.md` and `.claude/commands/handover.md` —
  two of the five files that use both wordings, and the place the split is
  most load-bearing.

## Traps

- Never drop meaning (`.agents/docs/caveman.md`): not / never / no / only /
  except survive every rewrite. A vocabulary sweep is exactly the edit that
  flattens them.
- Code blocks, inline code, paths, commands and frontmatter are byte-exact.
  `docs/handover/` stays `docs/handover/` in every path, whatever the prose
  calls the file.
- A lint whose fix is "delete the sentence" trades a fact for a green run.
  Rewrite, never delete.
- `compact-reorient` and `process-scorecard` also touch
  `.agents/harness/selftest.sh`; `process-scorecard` and `ci-scope-selftest`
  also touch `joharness.sh`. Not a wave with those, and this plan's sweep
  touches prose in files those plans may be editing — land it while they
  are not in flight, or rebase the sweep last.
- Broad `scope:` here is honest, not lazy: the sweep goes wherever the
  wording is. It joins no wave with anything.
