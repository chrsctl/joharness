# Glossary

Contested terms only — ones this repo spells two ways. Not a dictionary: term
with one spelling needs no row.

Row FIXES a spelling, POINTS at the file defining it. Gloss disambiguates in
one line, never redefines. Row explaining a term = second copy of that
definition, rots against the first (`.agents/docs/caveman.md`).

| Canonical | Means | Defined in | Not this |
| --- | --- | --- | --- |
| workstream file | one file per work, live on its branch, retired by its own pull request | `.agents/docs/handover/README.md` | handover file |
| agent tier | which of haiku, sonnet, opus implements a plan | `.agents/docs/agent-selection.md` | model tier |
| environment layer | one directory under `.agents/env/`, at most one selected per repo | `.agents/env/README.md` | env layer |

## What ci checks

`ci` reads `Not this`, fails on any of those wordings. Comma-separated =
several bans in one cell. Each is matched LITERALLY, as a SUBSTRING,
case-blind — so ban whole phrases. A bare word bans every phrase containing
it.

Scope = paths the harness owns and syncs, plus root `AGENTS.md` and
`CLAUDE.md`. Exact list: `joharness.sh:GLOSSARY_PATHS`. NOT scanned: `docs/`,
the rest of the root, a repo's own `.agents/env/<layer>/`. Those are the
consumer's to write, and a consumer cannot fix a hit in the glossary anyway —
editing it locally makes the file AHEAD on every future sync.

Two consequences worth knowing before you fight the gate:

- This file is the one scanned path that may spell a ban. Exempt by path; a
  marker comment would spread to every file that wanted one.
- The lint cannot tell prose from a quote. A record of the rename, a pasted
  failure, an old commit message — anything quoting a losing spelling goes
  under `docs/`, which is out of scope for exactly this reason.

## Where the code names the thing, the code wins

Counts settle a spelling only when lopsided. Whole tree, `git grep -Fni --
"<term>" -- '*.md' '*.sh' | wc -l` on `origin/main` 2026-08-28: 205 against
14, eight files carrying both. Settles `workstream file`. Did NOT settle
`agent tier` — 10 against 5, same command, 2026-08-24 — and the frontmatter
field is `agent`, the stronger evidence, which is what decided that row.

Re-count inside the gate's own scope and every losing spelling is 0. That is
the lint working, not evidence:

```bash
git grep -Fnoi -- "<term>" -- '.agents/docs/*' '.agents/harness/*' 'AGENTS.md' | wc -l
```

## One meaning, or nothing

A glossary fixing one meaning repo-wide fights the split this harness is built
on. This table cannot express a zone split and must not fake one: bans are
substrings, so a zoned canonical (`retry (harness)`) contains the bare ban
(`retry`) and could never be written. A term meaning different things in
`.agents/harness/` and an environment layer therefore gets NO row — it is
defined in the file owning the zone, and silence beats a wrong global answer.
`.agents/docs/graph.md` holds the node vocabulary the rows above lean on.

## Prose only

Frontmatter fields, subcommands, function names, paths keep their spellings,
`docs/handover/` included. Rule is `.agents/docs/caveman.md` "Never touch";
the row exists because a rename sweep runs straight at it.
