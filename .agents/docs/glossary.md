# Glossary

Contested terms only — ones this repo spells two ways. Row FIXES a spelling,
POINTS at the file defining it. Gloss disambiguates in one line, never
redefines: a second copy of a definition rots against the first.

| Canonical | Means | Defined in | Not this |
| --- | --- | --- | --- |
| workstream file | one file per work, live on its branch, retired by its own pull request | `.agents/docs/handover/README.md` | handover file |
| agent tier | which of haiku, sonnet, opus, fable implements a plan | `.agents/docs/agent-selection.md` | model tier |
| environment layer | one directory under `.agents/env/`, at most one selected per repo | `.agents/env/README.md` | env layer |
| surveyor | the role that corrects held plans' `scope:` declarations on an `OVERLAP-BOUND` verdict | `.agents/docs/orchestrated.md` | rescope manager |
| role title | `<emoji> <role>: <subject>`; emoji 🔑 keeper, 🎼 orchestrator, 💤 orchestrator (retired), 👯 orchestrator (duplicate), 🔨 manager, 📐 surveyor, 🧭 curator, 📋 clerk, 🧐 conduct, 🩺 retro. A SET writes the emoji; a MATCH accepts the title with or without it | `.agents/docs/orchestrated.md` | bare role title |

## What ci checks

`ci` reads `Not this`, fails on any of those wordings. Comma-separated =
several bans in one cell. Each is matched LITERALLY, as a SUBSTRING,
case-blind — so ban whole phrases. A bare word bans every phrase containing
it.

Scope = paths the harness owns and syncs, plus root `AGENTS.md` and
`CLAUDE.md`. Exact list: `joharness.sh:GLOSSARY_PATHS`. NOT scanned: `docs/`,
the rest of the root, a repo's own `.agents/env/<layer>/`: the consumer's to
write (a local glossary edit reads AHEAD on every future sync).

- This file is the one scanned path that may spell a ban (exempt by path).
- The lint cannot tell prose from a quote: anything quoting a losing spelling
  goes under `docs/`.

## Where the code names the thing, the code wins

Counts settle a spelling only when lopsided; otherwise the name the code uses
(a frontmatter field, a function) wins. Inside the gate's scope a losing
spelling counts 0: the lint working, not evidence.

## One meaning, or nothing

A glossary fixing one meaning repo-wide fights the split this harness is built
on. This table cannot express a zone split and must not fake one: bans are
substrings, so a zoned canonical (`retry (harness)`) contains the bare ban
(`retry`) and could never be written. A term meaning different things in
`.agents/harness/` and an environment layer therefore gets NO row — it is
defined in the file owning the zone, and silence beats a wrong global answer.
`.agents/docs/graph.md` holds the node vocabulary the rows above lean on.

## Prose only

Rows bind prose. Frontmatter fields, subcommands, function names, paths keep
their spellings, `docs/handover/` included (`.agents/docs/caveman.md`, "Never touch").
