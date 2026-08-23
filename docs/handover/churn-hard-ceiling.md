---
workstream: churn-hard-ceiling
status: in-progress
branch: claude/churn-hard-ceiling
pr: none
agent: sonnet
updated: 2026-08-23
next: none — ceiling gate + docs + selftests landed, ci green; opening the PR
---

## Goal

Human feedback: the Loop's Verify step is its weakest node. Everything past
`ci` — review depth, the churn stop, recording findings — is honor-system,
asked of the session least able to police itself. The churn measure (already
in `ci`) is the one machine-read signal there, but it only ever warns, and a
warning is ignored by exactly the session it describes. Give it teeth for the
pathological case without recreating the soft-metric rot the ledger already
rejected.

## Decisions

- Two tiers on the existing churn count (max commits per file since merge-base,
  a raw git fact — not a self-maintained field, so not gameable with filler).
  From `JOHARNESS_CHURN_THRESHOLD` (5) up: warning, unchanged — whether the
  churn is real is the session's judgment call. From a ceiling
  (`JOHARNESS_CHURN_LIMIT`, default 2x the threshold) up: `ci` fails. Backtest
  over every merge on main: the runaway sync branch peaked at 13, every other
  merge <= 4, so the ceiling fires on the one pathological case and nothing
  else.
- The gate is the point: the churning session cannot see its own churn, so the
  one check it cannot skip (`ci`) fails for it.
- Escape hatch is deliberate and visible: `JOHARNESS_CHURN_LIMIT=0` lifts the
  gate for a genuine large rework — an on-the-record act, not a silent skip.

## Rejected

- A hard `ci` gate counting review rounds against recorded findings lines. The
  review-ledger work already rejected it: soft metric over prose, gameable with
  filler, recreates the status-field rot. The churn count is a hard git fact,
  which is why a gate on it is defensible where a gate on findings is not.
- Red-gating from the warning threshold up. That would fail the ambiguous
  judgment-call band Chris deliberately left to the session; the ceiling exists
  precisely to separate "maybe churn" from "definitely churn".

## Blockers

None.

## Where to look

- joharness.sh — the churn block in `cmd_ci`, second tier + `rc=1`.
- docs/agent-selection.md — the review-churn rule, ceiling documented.
- harness/selftest.sh — ci-churn block: gate fails ci, override sets the
  ceiling, ceiling=0 lifts it, warn band stays green.
