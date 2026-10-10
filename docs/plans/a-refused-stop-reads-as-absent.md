---
plan: a-refused-stop-reads-as-absent
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 249
scope: shared:.claude/commands/orchestrate.md, shared:.agents/docs/orchestrated.md, shared:.agents/harness/selftest/orchestrated.sh
---

## Goal

Issue #249: `archive_session` was refused by the permission classifier
(`Interfere With Workloads`) on every attempt in a consumer run, and a
plain `kill` was refused the same way. The health table orders
`archive_session` and `interrupt_session` (dead row, KILL, LOOP, BLOCKED
BEFORE CLAIM) and has a branch for each tool being ABSENT, none for a call
being REFUSED. A refused stop has no written outcome, so the orchestrator
improvises. Give it one.

## Scope

- `.claude/commands/orchestrate.md` — Tools: one rule, a call refused or
  erroring at run time = that tool absent for that target this pass; take
  its row in the OPTIONAL table. Say which call was refused in the report.
  Respawn-after-archive rows then follow the `archive_session` absent row
  (left in place, report, respawn); interrupt-before-KILL follows the
  `interrupt_session` absent row (no replace, `status: blocked`).
- `.agents/docs/orchestrated.md` — "The kill, and why the handover comes
  first": one line, why refused = absent (issue #249, two refusals).
- `.agents/harness/selftest/orchestrated.sh` — pin the refused-equals-absent
  sentence in orchestrate.md.

## Out of scope

- Duplicate-by-branch check, death signature on `connection_status`, LOOP
  precondition: withdrawn after review in PR #253; do not re-add.
- Frozen `cost_usd` as death evidence: open research
  `docs/research/frozen-cost-is-not-death-yet.md`.
- Creating a heartbeat Routine: operator action, money
  (`.agents/docs/orchestrated.md`, "Heartbeat").
- Retry loops on a refused call.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- `git grep -n -i "refused" -- .claude/commands/orchestrate.md` — hit in
  Tools section.
- New selftest case FAILS with the orchestrate.md sentence removed.

## Where to look

- `.claude/commands/orchestrate.md` — Tools OPTIONAL table rows
  `interrupt_session`, `archive_session`; step 2 rows `dead:` and `gone`;
  KILL paragraph.
- `.agents/docs/orchestrated.md` — "The kill, and why the handover comes
  first".
- `.agents/harness/selftest/orchestrated.sh` — `orctext` / `orcfold`
  expect/refute cases, shape to copy.

## Traps

- Refused stop never licenses a second manager over a session that may be
  live: interrupt refused = no replace.
- Needle grep-checked against wrapped file text before commit (selftest
  comment on two that never matched).
- No commit under `./joharness.sh protocol-paths`.
