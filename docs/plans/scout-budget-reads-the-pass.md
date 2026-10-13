---
plan: scout-budget-reads-the-pass
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 453
scope: shared:.claude/commands/scout.md, shared:joharness.sh, .agents/harness/selftest/scout.sh
---

## Goal

`.claude/commands/scout.md` §3 stops outside reads when `get_session`'s
`usage.cost_usd` reaches the budget, and §6's `cost:` line copies that
number. Issue #453 measured two defects on a consumer pass: the reading
did not move inside one turn (four reads at $2.09, $4.06 at exit), and it
is the session total, so work done before `/scout` began ($2.09 of sync and
merges) counts against the pass. `./joharness.sh scout` prints `budget 10
USD a pass`, a per-pass meter the control plane does not provide.

Decided by the clerk: the pass meters a DELTA from a reading taken at
claim time, and the command says the reader lags within a turn, so the stop
is a floor, not a ceiling. USD stays the unit (no new knob: the conf is a
core path).

## Scope

- `.claude/commands/scout.md` §1 (claim) — take `get_session` (no `session_id`) once at claim; record `usage.cost_usd` and the UTC time in the claim's `## Decisions` as the claim reading.
- `.claude/commands/scout.md` §3 — the stop compares `cost_usd − claim reading` to the budget; one sentence: the reader may not move inside a turn, so check before each BATCH of outside reads and end the turn between batches; a reading unchanged since the last check is named as such in `## Decisions`.
- `.claude/commands/scout.md` §6 and the report section — `cost:` becomes the delta, written `cost: <delta> USD (get_session usage.cost_usd <exit> − <claim>, <UTC date>)`; the report states the same delta.
- `joharness.sh` — `cmd_scout`'s `research  :` line says `budget <N> USD a pass, metered from the claim reading` (exact wording yours; it must not promise a live per-pass meter).
- `.agents/harness/selftest/scout.sh` — assert the new `research  :` wording.

## Out of scope

- A count-of-reads cap or any new `JOHARNESS_*` knob: `joharness.conf` is a core path.
- Changing `get_session` or the control plane.
- The scout's read list (§2) — plan `scout-built-check` owns that.

## Acceptance

- `./joharness.sh scout | grep 'research  :'` — names the claim reading; does not read only `budget 10 USD a pass`.
- `bash .agents/harness/selftest/scout.sh` — passes; FAILS against the old wording.
- `grep -n 'claim reading' .claude/commands/scout.md` — hits in §1, §3 and §6.
- `./joharness.sh ci` — `ci: pass`; `./joharness.sh verify` — `0 failed`.
- Plan ships (scout.md and joharness.sh sync): consumer check = the consumer's `./joharness.sh scout` prints the new `research  :` line.

## Where to look

- `.claude/commands/scout.md` — §1 claim steps, §3 "Before EACH outside read", §6 `cost:` line, the report's `usage.cost_usd … at exit`.
- `joharness.sh:cmd_scout` — the `research  :` printf.
- `.agents/harness/selftest/scout.sh` — existing assertions on `cmd_scout` output.

## Traps

- Test for a fix must FAIL without it.
- Never edit `joharness.conf` (core path); no new knob.
- `scout.md` and `joharness.sh` are `shared:`: merge `origin/main` in before the pull request.
- Glossary spellings: `ci` fails a contested term spelled another way.
