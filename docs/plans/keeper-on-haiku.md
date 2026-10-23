---
plan: keeper-on-haiku
urgency: normal
agent: haiku
effort: medium
needs: none
requirement: none
issue: none
scope: .agents/docs/orchestrate-reference.md, .agents/docs/orchestrated.md, .agents/harness/selftest/orchestrated.sh
---

## Goal

The repo owner decided (chat, 2026-10-23) that the keeper role runs on the
haiku tier instead of sonnet. The keeper's work is mechanical and fully
specified (`.claude/commands/keeper.md`): one `list_triggers`, a few
`get_session`, then a one-line report or one `create_session`; its SWAP
path (retitle, `create_session` with a prompt edited by fixed line rules,
retitle back on refusal) is the one branchy part, accepted by the owner. A tier
downgrade is a money decision, humans only
(`.agents/docs/agent-selection.md`, Selection rules); this plan records
the human's decision and changes the two places that name the keeper's tier.
Only keepers created after the merge run on haiku: a running keeper keeps
the model it was created with until the next REGISTER or replace.

## Scope

- `.agents/docs/orchestrate-reference.md` — in REGISTER step 2, the
  sentence `` `model` = the Lineup's `sonnet` (the role is low tier; never
  the registering session's model) `` becomes `` `model` = the Lineup's
  `haiku` (the role is mechanical; never the registering session's model) ``.
  Nothing else in the file changes.
- `.agents/harness/selftest/orchestrated.sh` — the heartbeat-check needle
  that pins that sentence follows it: `sonnet` (the role is low tier; …)
  becomes `haiku` (the role is mechanical; …). The pin stays; only its
  text moves.
- `.agents/docs/orchestrated.md` — in the `## Roles` table, the `keeper`
  row's Tier cell `sonnet` becomes `haiku`. Nothing else in the row or file
  changes.

## Out of scope

- `.claude/commands/keeper.md` step 3 (`model` = the Lineup's `sonnet`):
  that is the model of the ORCHESTRATOR the keeper starts, not the keeper's
  own. Unchanged.
- The tier of any other role (orchestrator, curator, freer, surveyor,
  clerk, scout, conduct, manager, worker, verifier). Unchanged.
- `.agents/docs/agent-selection.md` Lineup table and selection rules.
  Unchanged.
- Archiving, replacing or re-registering the live keeper session or the
  heartbeat Routine. A human does that if they want the switch before the
  next replace.
- `joharness.sh`, any selftest but the one pin above, any core path (`./joharness.sh
  protocol-paths`).

## Acceptance

- `grep -n "Lineup's \`haiku\`" .agents/docs/orchestrate-reference.md` —
  exactly one line, inside REGISTER step 2.
- `grep -c "Lineup's \`sonnet\` (the" .agents/docs/orchestrate-reference.md`
  — prints `0`.
- `grep -n '^| keeper | haiku |' .agents/docs/orchestrated.md` — exactly
  one line.
- `grep -n "Lineup's \`sonnet\`" .claude/commands/keeper.md` — still
  exactly one line (step 3, unchanged).
- `git diff --stat origin/main...HEAD -- . ':!docs/'` — lists only the three
  scoped files.
- `./joharness.sh ci` — prints `ci: pass`. Consumer-side check: the
  orchestrated selftest pins the REGISTER sentence and ships with the
  harness, so a consumer's own `ci` reds if its synced copy drifts.
- `./joharness.sh verify` — `0 failed`.

## Where to look

- `.agents/docs/orchestrate-reference.md:REGISTER` — step 2, the
  `create_session` for the keeper.
- `.agents/docs/orchestrated.md:Roles` — the role/tier table, `keeper` row.
- `.claude/commands/keeper.md:Run` — step 3: the orchestrator's model, the
  line NOT to change.
- `.agents/docs/agent-selection.md:Selection rules` — "Never downgrade to
  save cost — money, humans only": why the Goal names the human decision.

## Traps

- Never downgrade to save cost on your own: this downgrade is the human's,
  recorded in Goal; do not extend it to any other role.
- Do not edit `keeper.md` step 3 — it sets the orchestrator's model, a
  different role.
- No commit to a core path (`./joharness.sh protocol-paths`).
