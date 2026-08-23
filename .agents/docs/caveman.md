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

## Honest numbers (upstream's own warning)

Style compresses output and re-read input. It proves nothing about quality —
compress only where every load-bearing fact survives. When compressed text
loses a symptom, a number, or a negation, verbose wins. Upstream:
[HONEST-NUMBERS.md](https://github.com/JuliusBrussee/caveman/blob/main/docs/HONEST-NUMBERS.md).
