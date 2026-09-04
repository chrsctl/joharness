# Caveman style guide

Rules for all instruction files and agent replies in this repo. Distilled from
[JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman): rules from
`skills/caveman/SKILL.md`, motto from its `README.md`.
MIT License, Copyright (c) 2026 Julius Brussee — full notice at the end of
this file, so a copy of it carries the whole condition wherever it goes.
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
invention, and knowing so is the point of this section — a session that thinks
the harness invented it will either distrust it or rebuild it.

Prior art, named and in production. Vale: entries in `accept.txt` are
"automatically added to a substitution rule (`Vale.Terms`), ensuring that any
occurrences of these words or phrases exactly match their corresponding entry
in `accept.txt`" ([docs.vale.sh/keys/vocabularies](https://docs.vale.sh/keys/vocabularies)).
`textlint-rule-terminology` does the same for tech writing, `textlint --fix
--rule terminology`. Datadog lints its docs with Vale; Elastic publishes its
house style AS a Vale ruleset ([elastic/vale-rules](https://github.com/elastic/vale-rules)).

So the choice was adopt or build, and this repo **built**. Reason, kept
because it is the part that decides whether to re-open: `ci` here is shell and
shellcheck, and `.agents/scripts/sync-to-consumer.sh` ships `joharness.sh` to
every consumer — so adopting puts a Go or Node runtime in all of them. One
table parser paid once against a runtime paid forever. Re-open only if that
trade changes, not because the mechanism looks home-made.

**A term that means different things in two layers gets NO row.** That is
settled in `.agents/docs/glossary.md`, "One meaning, or nothing", and the
reason is mechanical: bans are substrings, so a zoned canonical
(`retry (harness)`) contains the bare ban (`retry`) and could never be
written. The table cannot express a zone split and must not fake one.
Fowler's Bounded Context is the name for the underlying thing — contexts
"each of which can have a unified model", and "Different contexts may have
completely different models of common concepts with mechanisms to map between
these polysemic concepts for integration"
([martinfowler.com/bliki/BoundedContext.html](https://martinfowler.com/bliki/BoundedContext.html)).
The glossary's answer to it is silence, not a zone label: the term is defined
in the file owning the zone, and silence beats a wrong global answer.

## Honest numbers (upstream's own warning)

Style compresses output and re-read input. It proves nothing about quality —
compress only where every load-bearing fact survives. When compressed text
loses a symptom, a number, or a negation, verbose wins. Upstream:
[HONEST-NUMBERS.md](https://github.com/JuliusBrussee/caveman/blob/main/docs/HONEST-NUMBERS.md).

## Upstream license

This file is a derivative of the caveman skill. MIT names two things that
travel with every copy — the copyright notice and the permission notice — so
both are here rather than in a neighbouring file a copy would leave behind.

    MIT License

    Copyright (c) 2026 Julius Brussee

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

The harness's own grant is separate and unaffected: `.agents/LICENSE`, with
`.agents/NOTICE` beside it.
