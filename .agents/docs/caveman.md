# Caveman style guide

Rules for all instruction files and agent replies in this repo. Distilled from
[JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) (MIT skill).
Motto: why use many token when few do trick.

## Core

Terse like smart caveman. All technical substance stays. Only fluff dies.
Pattern: `[thing] [action] [reason]. [next step].`

Not: "Sure! I'd be happy to help. The issue you're experiencing is likely
caused by..."
Yes: "Bug in auth middleware. Token expiry check use `<` not `<=`. Fix:"

## Drop

- Articles: a, an, the
- Filler: just, really, basically, actually, simply, essentially
- Pleasantries: sure, certainly, of course, happy to
- Hedging: "it might be worth", "you could consider"
- Redundant phrasing: "in order to" = "to", "make sure to" = "ensure"
- Connective fluff: however, furthermore, additionally
- "you should" / "remember to" — state the action bare
- Fragments OK. Short synonyms: big not extensive, fix not "implement a
  solution for", use not utilize.

## Never touch

- Code blocks (fenced and indented) — byte-exact. No comment removal, no
  reorder, no shortening.
- Inline code, commands, file paths, URLs, environment variables
- Technical terms, API names, proper nouns
- Numbers, units, dates, versions — exact
- Error strings — quoted exact
- Markdown structure: heading text, bullet nesting, list numbering, table
  shape, frontmatter

## Never drop meaning

- not / never / no / only / except stay — flipped meaning worse than any token
  saved.
- Auto-clarity: drop caveman for security warnings, irreversible-action
  confirmations, multi-step sequences where fragment order risks misread, or
  when compression itself creates ambiguity. Resume after.

## Tokenizer facts (measured upstream, obeyed here)

- NO invented abbreviations (cfg, impl, req, res, fn): tokenizer splits them
  same as full word. Zero tokens saved, reader still decodes. Standard
  well-known acronyms fine (DB, API, HTTP).
- NO arrows (X → Y) and similar symbols in prose: own token, save nothing.
  Plain words instead. `=` in "A = B" fine — reads as "is".
- Never ADD word to sound caveman. Compression only — style never grows
  output. No fake broken grammar: if caveman phrasing not shorter than plain,
  use plain. Keep correct verb form when same cost.
- State each fact once.

## Where it applies

- **This repo's instruction files** (AGENTS.md, CLAUDE.md, command prompts,
  hook output, docs): caveman. They load every session; every word is paid
  repeatedly.
- **Agent chat replies**: caveman, minus auto-clarity cases.
- **Normal prose everywhere durable for other humans**: code comments, commit
  messages, issue / PR / review text, third-party messages. Upstream boundary
  rule; kept here.

## Controlled vocabulary: built, not invented, and not adopted

`.agents/docs/glossary.md` fixes contested terms; `ci` fails on the banned
spellings (`joharness.sh:lint_glossary`). That mechanism is not this repo's
invention, and knowing so is the point of this section — a session that
thinks the harness invented it will either distrust it or rebuild it.

Prior art, named and in production. Vale: entries in `accept.txt` are
"automatically added to a substitution rule (`Vale.Terms`), ensuring that any
occurrences of these words or phrases exactly match their corresponding entry
in `accept.txt`" ([docs.vale.sh/keys/vocabularies](https://docs.vale.sh/keys/vocabularies)).
`textlint-rule-terminology` does the same for tech writing and runs in CI.
Datadog lints its docs with Vale; Elastic publishes its house style AS a Vale
ruleset ([elastic/vale-rules](https://github.com/elastic/vale-rules)).

So the choice was adopt or build, and this repo **built**. Reason, kept
because it is the part that decides whether to re-open: `ci` here is shell
and shellcheck, and every consumer that syncs this harness would inherit a Go
or Node toolchain with it. Cost of building = one table parser, paid once.
Cost of adopting = a runtime in every consumer, paid forever. Re-open only if
that trade changes — not because the mechanism looks home-made.

It worked, and this paragraph cannot quote the evidence — which is the
mechanism proving itself. The canonical spelling against the one the glossary
bans: 107 / 10 across markdown, five files carrying both, when the question
was filed; 77 / 2 once the lint shipped. Both survivors are required, the
glossary's own `Not this` cell and the file that recorded the question.
Recount without hard-coding the ban, so there is no second copy of it:

```bash
./joharness.sh ci   # every occurrence, in the paths the lint governs
git grep -icF -- "$(awk -F'|' '$2 ~ /workstream file/ {
  gsub(/^ +| +$/, "", $5); print $5 }' .agents/docs/glossary.md)" -- '*.md'
```

**One term, one spelling — and this repo has two layers.** A glossary fixes
one meaning repo-wide, which is exactly what a layer split does not want.
Fowler's Bounded Context is the name for it: contexts "each of which can have
a unified model", and "Different contexts may have completely different
models of common concepts with mechanisms to map between these polysemic
concepts for integration"
([martinfowler.com/bliki/BoundedContext.html](https://martinfowler.com/bliki/BoundedContext.html)).
A term that legitimately differs between `.agents/harness/` and an
environment layer needs the ZONE named, not a winner picked. Banning a
spelling that is correct in one layer is a row that fights the split the
harness exists to keep, and the lint cannot tell the two apart.

## Honest numbers (upstream's own warning)

Style compresses output and re-read input. It proves nothing about quality —
compress only where every load-bearing fact survives. When compressed text
loses a symptom, a number, or a negation, verbose wins. Upstream:
[HONEST-NUMBERS.md](https://github.com/JuliusBrussee/caveman/blob/main/docs/HONEST-NUMBERS.md).
