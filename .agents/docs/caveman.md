# Caveman style guide

Rules for all instruction files and agent replies in this repo. Distilled from
[JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman): rules from
`skills/caveman/SKILL.md`, motto from its `README.md`.
MIT License, Copyright (c) 2026 Julius Brussee — full notice at the end.
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
  same as full word. Well-known acronyms fine (DB, API, HTTP).
- NO arrows (X → Y) and similar symbols in prose: own token, save nothing.
  `=` in "A = B" fine — reads as "is".
- Never ADD word to sound caveman: compression only, style never grows output.
  No fake broken grammar: not shorter than plain = use plain; keep correct verb
  form when same cost.
- State each fact once.

## Status quo

Markdown states what IS. Reader acts on present rule, not on how it was
reached; every past sentence is paid by every reader, forever.

- Keep: rule, mechanism in present tense, number that is the rule's
  current basis, symptom that identifies the failure today, id of the
  decision in force.
- Drop: incident counts ("hit three times"), dated stories ("measured
  2026-09-16"), "was / used to / no longer", superseded or rejected
  designs, amendment chains, who found what.
- Reversed decision: rewrite the rule in place; record keeps one line
  naming the decision in force. Old text = `git log -p`.
- Workstream and plan files: same rule (`handover.md`: only what git
  cannot tell).

"Numbers, dates — exact" (Never touch) governs text that stays, not whether a
dated story stays. Measured number keeps its command and when (Loop step 5).

## Where it applies

- **This repo's instruction files** (AGENTS.md, CLAUDE.md, command prompts,
  hook output, docs): caveman. They load every session; every word is paid
  repeatedly.
- **Agent chat replies**: caveman, minus auto-clarity cases.
- **Normal prose everywhere durable for other humans**: code comments, commit
  messages, issue / PR / review text, third-party messages. Upstream boundary
  rule; kept here.

Cost: every file loaded before the first prompt (`CLAUDE.md` and its `@`
imports, the `session-start` injection) is paid by every session, forever.
Before adding a line there: is the rule already stated somewhere read on
demand? A why under `.agents/docs/` costs nothing until opened.

## Controlled vocabulary

`.agents/docs/glossary.md` fixes contested terms; `ci` fails on the banned
spellings (`joharness.sh:lint_glossary`, shell: adopting Vale would ship a Go runtime).

## Honest numbers (upstream's own warning)

Style proves nothing about quality: compressed text that loses a symptom, a number or a
negation loses to verbose ([HONEST-NUMBERS.md](https://github.com/JuliusBrussee/caveman/blob/main/docs/HONEST-NUMBERS.md)).

## Upstream license

Derivative of the caveman skill: MIT's copyright and permission notices
travel inside this file, so every copy carries them.

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
