---
workstream: extensions-research
status: review
branch: claude/extensions-research-ihryow
pr: none
plan: none
agent: sonnet
updated: 2026-08-23
next: Human trims — delete any docs/product/ proposal not wanted, merge rest. Merge = ratification; queue hook picks survivors up.
---

## Goal

Task: research harness, propose useful extensions. Proposal in repo's own
shape: one requirement file per proposal under `docs/product/`, this
branch's PR = the proposal, merge = ratification. Product direction stays
human's (docs/product/README.md: add via PR = human's call).

## Decisions

- Requirements, not plans. Decomposition comes after ratification, per
  hierarchy — plans now would pre-commit implementation before direction
  exists.
- Rank (chat + PR body carries reasoning): graph-edge-lint first — silent
  edge kill makes queue lie, exact failure class the ceiling gate exists
  for. Then handover-stop-guard, pr-steward-skill,
  plan-authoring-command. download-integrity + bootstrap-purge-guard =
  security-sweep follow-ups filed so they outlive that merged workstream
  file, not new ideas.
- Deleted churn-hard-ceiling.md + security-sweep.md leftovers (hook
  flagged, merged = finished). Keepers already graduated: ceiling
  documented in docs/agent-selection.md; sweep follow-ups = the two
  requirements here.

## Rejected

- refs/claims mutual exclusion — rejected in docs/handover/README.md
  already; nothing changed since.
- GitHub issue list in session-start hook — shell hook cannot reach MCP,
  gh CLI absent in remote sandbox. Signal present locally, absent
  remotely = inconsistent; pointer stays.
- Consumer fleet registry (which repos consume, at what version) — state
  store, rots; update.yml pull requests already surface drift per
  consumer.
- Sharper churn metric (revert detection, not commits-per-file) — ceiling
  landed days ago; sharpen only after it misfires, backtest first.
- Second env layer to prove the contract — no consumer demand; layer built
  for proof alone = unexercised code shipped to every consumer.
- PreToolUse guard enforcing lazy-md read-first — cannot verify a read
  happened; signal wrong both directions, same failure class as push-time
  liveness.
- Scheduled sandbox verify (Routine runs smoke test weekly, opens issue on
  red) — real gap: `verify` needs sandbox, GitHub CI cannot run it, so it
  runs only when a session remembers. Costs money (scheduled sessions) =
  human-only decision. Flagged, not filed; say the word, becomes a
  requirement.

## Blockers

None.

## Where to look

- `docs/product/graph-edge-lint.md` + five siblings — the proposals.
- `joharness.sh:cmd_ci` — where graph-edge-lint would live.
- `scripts/sync-to-consumer.sh:DIRS` — steward skill needs
  `.claude/skills` added there.
