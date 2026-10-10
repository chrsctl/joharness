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
next: Read full ci + verify results and the opus verifier; record findings in ## Review, fix, then retire + PR
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

- r1: (verifier) authority diffs the tree against the origin/<base> TIP, so a
  clean checkout merely BEHIND it reads NOT VERIFIABLE naming files it never
  edited (scratch clone, another clone pushes a harness edit, fetch). (fixed:
  diff against `merge-base HEAD origin/<base>`; selftest case added)
- r2: (verifier) VERIFIABLE ignores role files, .claude/settings.json and
  joharness.conf — `{}` in settings.json unwires the Stop guard and still
  reads VERIFIABLE. (fixed: AUTHORITY_PATHS adds .claude and joharness.conf —
  every file a session's rules come from; selftest case added. Ignored files
  stay excluded: .claude/settings.local.json is per-user and gitignored, and
  counting it would make every human checkout NOT VERIFIABLE — wontfix)
- r3: (verifier) role commands say "anything else = stop" but authority on a
  branch carrying its own harness edits reads NOT VERIFIABLE — a respawn that
  checks out first, or a compacted manager re-running step 0, stops. (fixed:
  manage.md and orchestrate.md's respawn prompt order authority BEFORE the
  checkout, once per session; a re-run after own edits is not a stop)
- r4: (verifier) scout.md human-start keys on `scout     : DUE`, which
  dispatch prints even when suppressed. (fixed: key on `scout DUE: spawn`)
- r5: (verifier) perf comment's "36 now" is arithmetic, not a count; the
  guard state table predates the deleted `mode` call. (fixed: wording says
  what was and was not re-counted)
- r6: (verifier) comments still describe `drain` as a live entrypoint and
  budget (joharness.sh perf block, DRAIN_FETCH, curate/rot comments). (fixed)
- r7: (verifier) sync names `JOHARNESS_MODE=orchestrated` obsolete while
  joharness.sh is silent on it. (wontfix: the plan names the KEY obsolete in
  any value; the entrypoint's silence on `orchestrated` exists so the
  canonical's own conf line — a core path only a human deletes — does not
  warn in every session. The sync tells the human to delete it; same answer.)

## Blockers

None.

## Where to look

- `joharness.sh:run_mode`, `joharness.sh:unattended` — the switch.
