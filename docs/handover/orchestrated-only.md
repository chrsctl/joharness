---
workstream: orchestrated-only
status: in-progress
branch: claude/orchestrated-only
pr: none
plan: orchestrated-only
issue: none
session: https://claude.ai/code/session_015NtQ5zqgi5mjrZ9Xkofo2K
agent: opus
updated: 2026-10-10
next: Selftests — fan out per file set once the branch failure list is in
---

## Goal

Requester, 2026-10-08: "Only orchestrator mode should be left over" —
everywhere, consumers included, fail-closed default gone. One mode:
`/manage <item>` = manager, anything else = orchestrator.

## Decisions

- `JOHARNESS_RUN_MODE` is no longer exported or read: the three hooks take
  the orchestrated path unconditionally. One mode = nothing to pass.
- `joharness.sh mode` subcommand deleted (its one reader, the Stop guard,
  now applies the core boundary unconditionally).
- `HANDOVER_SCOPE` stays two-valued: `dispatch` runs handover-context.sh
  with the default `all` (edge, claims), so the fleet walk is NOT reachable
  only from supervised. Session start keeps `branch`.
- Obsolete key: `mode_obsolete` returns the raw value when set and not
  `orchestrated`; session-start prints the line into context, `start`
  warns on stderr. Never fails.
- `authority`: VERIFIABLE iff `git diff origin/<base> -- joharness.sh
  .agents/harness` (working tree) and untracked files there are empty;
  origin/<base> unreadable = UNVERIFIED; drift = NOT VERIFIABLE + paths.
- `drain_supervised_only` -> `drain_core_only`; row label `CORE ONLY`.
  `drain_plan`, `drain_next`, `drain_free_others`, `drain_scout_block`
  deleted with `cmd_drain` (no caller left).
- `== dispatch` header drops `(mode: ...)`; the NOT ORCHESTRATED stop goes.
- perf: `drain` row deleted (subject gone); queue rows collapse to one;
  guard row unpinned; budgets re-counted.
- Selftests outside the plan's `scope:` that call `drain` or pin a mode
  (analysis, janitor, scout, protocol-boundary, num-knob, ...) are edited
  too: leaving them red is not an option. Scope widening recorded here.

## Rejected

- (none yet)

## Review

## Blockers

None.

## Where to look

- `joharness.sh:run_mode`, `joharness.sh:unattended` — the switch.
