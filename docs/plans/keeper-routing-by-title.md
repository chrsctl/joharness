---
plan: keeper-routing-by-title
urgency: urgent
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: .claude/commands/orchestrate.md, .agents/docs/orchestrated.md, .agents/harness/selftest/orchestrated.sh
---

## Goal

gx, 2026-10-16 18:20-18:24: orchestrator sessions read the first line of
`orchestrate.md` ("Argument `keeper` ... this session is the keeper") as a
notice that they were the keeper. Each one ran the Keeper section and
started another `/orchestrate`; ten sessions chained until lineage 8/8, and
the hand-off successor's ledger was dropped. Route the keeper role by the
session's own title, never by prompt text.

## Scope

- `.claude/commands/orchestrate.md`: routing line reads `get_session` title;
  `keeper: <owner/repo>` alone runs "## Keeper"; any other title never does.
  The Keeper section opens with the same guard.
- `.agents/docs/orchestrated.md`: Heartbeat, one sentence on the routing.
- `.agents/harness/selftest/orchestrated.sh`: needles for both guards, a
  refute for the old line.

## Out of scope

- Re-enabling gx's heartbeat (the human's).
- The dropped ledger of that incident: an orchestrator routed right keeps
  its own; nothing here rebuilds a lost one.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- SHIPS: after the gx sync, `./joharness.sh ci` in gx — `ci: pass`, its
  selftest pinning the title routing.
