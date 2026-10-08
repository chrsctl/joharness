---
plan: lineup-current-generation
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: scout-role
scope: .agents/docs/agent-selection.md
---

## Goal

Human ask, 2026-10-08: evaluate cheaper tiers and Anthropic's usage-limit
best practices (support.claude.com article 9797557) for the Joharness
workflow, then apply. Biggest free lever found: the Lineup still maps tiers
to `claude-haiku-4-5` / `claude-sonnet-5` / `claude-opus-5` while the 5.5
generation is served at lower or equal price. Requirement `scout-role`
candidate 2 names the same edit. This plan makes it, and writes down the
cost levers a session can pull without a tier downgrade.

## Scope

- `.agents/docs/agent-selection.md` — Lineup rows to `claude-haiku-5-5`,
  `claude-sonnet-5-5`, `claude-opus-5-5`, prices and context from the
  claude-api skill cache dated 2026-10-06; drop the expired sonnet intro
  price; haiku row states the 100K-prompt price step. New section `## Cost
  levers`: cache expiry on idle, context size as the bill, effort not
  crossing a spawn, subscription limits shared across a fleet.

## Out of scope

- Any tier downgrade of a role or plan. Money, human only.
- `scout-role` requirement file and its other candidates — the scout's.
- Protocol paths (`./joharness.sh protocol-paths`). Follow-ups that need
  them are separate plans.

## Acceptance

- `grep -c 'haiku-4-5\|claude-sonnet-5`\|claude-opus-5`' .agents/docs/agent-selection.md` — `0`.
- `grep -c 'claude-haiku-5-5\|claude-sonnet-5-5\|claude-opus-5-5' .agents/docs/agent-selection.md` — `3` or more.
- `./joharness.sh ci` — `ci: pass`.

## Where to look

- `.agents/docs/agent-selection.md:Lineup` — the table.
- `docs/product/scout-role.md:Evidence` — prices and the run costs cited.

## Traps

- Measured number carries what produced it, same sentence.
- Never downgrade to save cost — that decision is money, humans only.
