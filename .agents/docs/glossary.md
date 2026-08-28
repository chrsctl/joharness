# Glossary

Contested terms only — the ones this repo spells two ways. Not a dictionary:
a term with one spelling needs no row, and a full one is context nobody pays
for willingly.

Each row FIXES a spelling and POINTS at the file that defines it. The gloss
disambiguates in one line; it never redefines. A row explaining a term would
be a second copy of that definition, and second copies rot against the first
(`.agents/docs/caveman.md`, state each fact once).

`ci` reads the `Not this` column and fails on any of those wordings in a
tracked file under `.agents/`, or a tracked root-level `*.md`. Not the whole
tree: this vocabulary is harness-owned and ships to consumers, so a sync must
never red a consumer's CI over the consumer's own product prose. This file is
the one place the banned wordings may appear — exempted by path, because a
marker comment would spread to every file that wanted the exemption.

| Canonical | Means | Defined in | Not this |
| --- | --- | --- | --- |
| workstream file | one file per work, live on its branch, retired by its own pull request | `.agents/docs/handover/README.md` | handover file |
| agent tier | which of haiku, sonnet, opus implements a plan | `.agents/docs/agent-selection.md` | model tier |
| environment layer | one directory under `.agents/env/`, at most one selected per repo | `.agents/env/README.md` | env layer |

## Where the code names the thing, the code wins

Counts settle a spelling only when they are lopsided. Whole-tree measurement
on 2026-08-25, before the sweep that made these rows true, recorded in
`docs/research/glossary-enforcement.md`: 107 against 10, five files carrying
both. That settles `workstream file`. It did NOT settle `agent tier` — 10
against 5 on 2026-08-24 — and the frontmatter field is `agent`, which is the
stronger evidence and is what decided that row. Re-counting today returns zero
for every losing spelling; that is the lint working, not evidence. What a
fresh count is still good for is the winning term, which moves with every
merge:

```bash
git grep -Fnoi -- "<term>" -- '.agents/*.md' '.agents/*.sh' ':(glob)*.md' | wc -l
```

## One meaning, or a named zone

A glossary that fixes one meaning repo-wide fights the split this harness is
built on. Where a term genuinely differs between `.agents/harness/` and an
environment layer, it gets TWO rows, each `Canonical` cell carrying its zone
(`retry (harness)`, `retry (env/k8s)`) so the two spellings differ and neither
bans the other. No term here is zone-split today; the rule exists so the first
one that is does not get flattened into a wrong global answer.
`.agents/docs/graph.md` holds the node vocabulary the rows above lean on.

## Prose only

Frontmatter fields, subcommands, function names and paths keep their
spellings, `docs/handover/` included. A field rename breaks every consumer's
synced harness and every open branch's frontmatter for a vocabulary win.
