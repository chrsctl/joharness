---
plan: drain-loop
urgency: normal
agent: opus
effort: medium
needs: none
requirement: none
scope: joharness.conf, .agents/scripts/bootstrap-consumer.sh, .agents/harness/selftest/bootstrap-consumer.sh
---

## Goal

Human ask, 2026-10-07: "Add an infinity loop to drain … like the normal loop
just with parallelity 1 … still cheap orchestrator." The normal loop is
`/orchestrate`: a low-tier session spawns one manager per item at the item's
tier and loops to DRAINED. Parallelity 1 = `JOHARNESS_MAX_MANAGERS=1`. The
human chose the config route over rewriting `/drain`.

## Scope

- `joharness.conf` — `JOHARNESS_MODE=orchestrated`, `JOHARNESS_MAX_MANAGERS=1`,
  and a comment naming the flip and how to revert it.
- `.agents/scripts/bootstrap-consumer.sh` — whole-clone strip also drops
  `JOHARNESS_MAX_MANAGERS`: joharness only (human, 2026-10-07). Sync never
  copies the conf; a whole clone did.
- `.agents/harness/selftest/bootstrap-consumer.sh` — pins that strip.

## Out of scope

- `.claude/commands/drain.md`, `orchestrate.md`, `manage.md`, `joharness.sh`
  — the machinery exists; no change.
- Relaxing the `authority` bound. Managers keep refusing without
  orchestrated + VERIFIABLE; this merge is what makes it VERIFIABLE.
- Creating a heartbeat Routine (operator action, money).

## Acceptance

- `./joharness.sh dispatch` — `cap       : 1 manager(s) at once`.
- `./joharness.sh start` — routes to `.claude/commands/orchestrate.md`.
- `./joharness.sh ci` — `ci: pass`.

## Where to look

- `.claude/commands/orchestrate.md` — the loop this selects.
- `joharness.sh:cmd_dispatch` — reads the cap.

## Traps

- `joharness.conf` is protocol text: supervised, human-asked — fine.
- Under orchestrated every protocol-path plan is SUPERVISED ONLY; say so to
  the human, never hide it.
