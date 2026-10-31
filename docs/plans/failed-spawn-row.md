---
plan: failed-spawn-row
urgency: urgent
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: .claude/commands/orchestrator.md, .agents/docs/orchestrator-reference.md, .agents/harness/selftest/orchestrated.sh
---

## Goal

Human's order, defect seen in consumer chrsctl/gx on 2026-10-31: three
manager spawns made without `source_url` started with no checkout, stopped
unclaimed in ~30 s, and every later orchestrator kept them as `<stem>@new`,
counted them in `JOHARNESS_PENDING_SPAWNS`, and spawned nothing for ~2 h.
No health-table row freed an `@new` entry whose session ran and ended
unclaimed, and none notified the human. Make a failed spawn free its slot,
catch a spawn with no checkout at spawn time, and pin that every
slot-holding ledger entry has a way out.

## Scope

- `.agents/docs/orchestrator-reference.md` — § Unclaimed spawn rows: a FAILED
  SPAWN row (ended, unclaimed = archive, plain spawn, counted, no-source note);
  past the limit = notify once, drop the entry, ledger it run-scoped so §3
  spawns it no more this run. § Create session: the source check at spawn.
- `.claude/commands/orchestrator.md` — §1 count, §3 skip and spawn check,
  §4 ledger key, the exit rule for slot-holding entries.
- `.agents/harness/selftest/orchestrated.sh` — pin the needles and a table
  check: every Unclaimed spawn row frees, spawns, notifies or records a look.

## Assumptions

- A1: create_session's result may not carry `session_context` — evidence:
  tool description "Returns the new session's ID and status" — confidence:
  medium. So the check reads `get_session` on the new id when absent.

## Out of scope

- `joharness.sh` dispatch code: the count is the orchestrator's input.
- Core paths.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed.
- The new table check fails on `origin/main`'s reference.
- Consumer side: none runs (the selftest is canonical-only); consumers get
  the protocol text at sync, pinned here by the canonical selftest.

## Where to look

- `.agents/docs/orchestrator-reference.md:## Unclaimed spawn rows` — the rows.
- `.agents/harness/selftest/orchestrated.sh:STILLBORN` — needle pins.

## Traps

- Glossary spellings; caveman style; never edit a core path.
