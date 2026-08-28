# Glossary

Contested terms only — the ones this repo spells two ways. Not a dictionary:
a term with one spelling needs no row, and a full one is context nobody pays
for willingly.

Each row FIXES a spelling and POINTS at the file that defines it. The gloss
disambiguates in one line; it never redefines. A row explaining a term would
be a second copy of that definition, and second copies rot against the first
(`.agents/docs/caveman.md`, state each fact once).

`ci` reads the `Not this` column and fails on any of those wordings in a
tracked `*.md` or `*.sh` file. This file is the one place they may appear —
exempted by path, because a marker comment would spread to every file that
wanted the exemption.

| Canonical | Means | Defined in | Not this |
| --- | --- | --- | --- |
| workstream file | one file per work, live on its branch, retired by its own pull request | `.agents/docs/handover/README.md` | handover file |
| agent tier | which model tier implements a plan: haiku, sonnet, opus | `.agents/docs/agent-selection.md` | model tier |
| environment layer | one directory under `.agents/env/`, at most one selected per repo | `.agents/env/README.md` | env layer |

## Where the code names the thing, the code wins

Counts settle a spelling only when they are lopsided. "workstream file" 205
against "handover file" 14 settles that one; "agent tier" 10 against "model
tier" 6 does not, and the frontmatter field is `agent`, which is the stronger
evidence. Re-count before quoting either figure — they move with every merge:

```bash
grep -rnoi "<term>" --include=*.md --include=*.sh . | grep -v '^./.git' | wc -l
```

## One meaning, or a named zone

A glossary that fixes one meaning repo-wide fights the split this harness is
built on. Where a term genuinely differs between `.agents/harness/` and an
environment layer, the row names the zone rather than picking a winner —
`.agents/docs/graph.md` holds the node vocabulary the rows above lean on. No
term here is zone-split today; the rule exists so the first one that is does
not get flattened into a wrong global answer.

## Prose only

Frontmatter fields, subcommands, function names and paths keep their
spellings, `docs/handover/` included. A field rename breaks every consumer's
synced harness and every open branch's frontmatter for a vocabulary win.
