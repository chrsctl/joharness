---
plan: simplify-consumer-docs
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: none
scope: .agents/docs/consumer-repos.md, .agents/docs/feedback.md, .agents/docs/caveman.md, .agents/docs/glossary.md
---

## Goal

The user asked to simplify the protocol. `consumer-repos.md` (537 lines)
states its update routes three times and repeats AGENTS.md step 7 twice.
`feedback.md`, `caveman.md` and `glossary.md` carry dated counts and
"built, not adopted" history, which breaks the Status quo rule. caveman.md
breaks its own rule. Say each rule once, at its home.

## Scope

- `.agents/docs/consumer-repos.md`:
  - Update routes: keep the table. The list and the agent-route prose that
    repeat it go.
  - The missing-token warning is stated twice. Keep one.
  - The step 7 merge conditions are stated twice. Point to AGENTS.md step 7,
    keeping the "Local checks" section AGENTS.md cites by name.
  - The Context and Source rules repeat AGENTS.md. Point there.
  - Fix the "`.agents/harness/AGENTS.md`, Harness upkeep" reference: the rule
    is the "Consumer repo:" bullet under "Decide alone".
  - Stays the home of the direction rule.
- `.agents/docs/feedback.md`:
  - Delete history: "true on 2026-08-24"; "Retention was zero" and "seven
    edges"; "decided by counting (2026-10-08, 273 edges)" (keep the rule);
    "how the gap got noticed"; "until that was fixed".
  - Cut the direction-rule and Context-rule copies to pointers.
  - Cut the `analysis` command copy to a pointer at the orchestrated.md
    table row.
  - Renumber the sections into order: today they run 1–4, two unnumbered,
    then 5.
- `.agents/docs/caveman.md`:
  - Delete "770 to 2129 words in 14 days, 2026-08" and the "built, not
    adopted" Vale/textlint history.
  - Delete the "Zone split gets no row" copy; glossary.md is its home.
  - Keep the MIT notice block byte-exact (`selftest/license-notice.sh`).
- `.agents/docs/glossary.md`:
  - Delete the dated grep counts.
  - Reword the role-title row's "sessions live before the emoji" history
    as current rule.

## Assumptions

- A1: `selftest/reading-budget.sh` sets a byte ceiling, upper only, on consumer-repos.md — evidence: `cat .agents/harness/selftest/reading-budget.sh` — confidence: high.
- A2: `selftest/license-notice.sh` needs the MIT block in caveman.md — evidence: `cat .agents/harness/selftest/license-notice.sh` — confidence: high.
- A3: `lint_glossary` reads glossary.md for its banned spellings. Editing a row can change what `ci` bans — evidence: `grep -n 'lint_glossary' joharness.sh` — confidence: medium. Read the function before touching any table row.

## Out of scope

- Other docs: sibling plans simplify-queue-docs and
  simplify-orchestrated-docs own them.
- `.agents/scripts/sync-to-consumer.sh` and the sync behaviour. This plan
  is prose only.
- Adding or removing glossary terms. Only history leaves glossary.md.

## Acceptance

- `git grep -nE '2026-08-24|2026-10-08|770 to 2129|Harness upkeep' .agents/docs/consumer-repos.md .agents/docs/feedback.md .agents/docs/caveman.md .agents/docs/glossary.md`: no output.
- `cat .agents/docs/consumer-repos.md .agents/docs/feedback.md .agents/docs/caveman.md .agents/docs/glossary.md | wc -l`: at most 900 (1051 today).
- `./joharness.sh ci`: `ci: pass`. This includes `ci-glossary`.
- Consumer-side check: the same `./joharness.sh ci` runs in every consumer after sync and lints these files (glossary, anchors).
- `./joharness.sh verify`: `0 failed`.

## Where to look

- `joharness.sh:lint_glossary`: how glossary.md drives `ci`.
- `.agents/harness/selftest/license-notice.sh`: the MIT block.
- `.agents/harness/AGENTS.md:Decide alone`: the "Consumer repo:" bullet.
- `.agents/docs/consumer-repos.md:Name no consumer`: the rule to keep.

## Traps

- The MIT notice in caveman.md is a license condition. Never trim it.
- AGENTS.md step 7 cites consumer-repos.md "Local checks" by name. Keep
  that heading.
- Sibling plans simplify-queue-docs and simplify-orchestrated-docs point
  here for the direction rule. Keep the phrase "direction rule" findable.
