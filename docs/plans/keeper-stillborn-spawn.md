---
plan: keeper-stillborn-spawn
urgency: urgent
agent: sonnet
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: .claude/commands/keeper.md, .agents/docs/orchestrated.md, shared:.agents/harness/selftest/orchestrated.sh, shared:.agents/harness/selftest/reading-budget.sh
---

## Goal

chrsctl/gx, 2026-11-08: the keeper's context auto-compacted, the next SWAP
called `create_session` without `source_url`, the successor started with no
checkout, and six hourly wakes found NOT LIVE yet started nothing and pushed
nothing: 5 h with no orchestrator. Close the four root causes: rules lost at
compaction, no Source check on keeper spawns, NOT LIVE not binding, no
escalation.

## Scope

- `.claude/commands/keeper.md` — step 1 re-reads the file whole every wake;
  step 2 narrows `list_triggers` and treats a `config:no-git-repo` 🎼 session
  as a failed spawn; step 3 binds on NOT LIVE, spells the Source check and the
  did-not-start push; SWAP step 2 runs the same Source check.
- `.agents/docs/orchestrated.md` — the why: compaction is the keeper's
  context bound, rotation rejected for lineage depth.
- `.agents/harness/selftest/orchestrated.sh` — pins for every new rule,
  refutes for the cmp-then-follow text.
- `.agents/harness/selftest/reading-budget.sh` — keeper.md bound re-counted
  (the rules must live in the one file the keeper reads).

## Assumptions

- A1: the keeper reads only keeper.md, its triggers, sessions it names and the
  Lineup — evidence: .agents/docs/orchestrated.md:keeper — confidence: high
- A2: lineage depth is capped at 8 and every create_session child sits one
  level deeper — evidence: git show 8ed07695; .agents/docs/orchestrated.md:Lineage stays flat — confidence: high
- A3: the keeper has no archive_session; retitling is how it retires a
  session — evidence: .claude/commands/keeper.md:Tools — confidence: high
- A4: list_triggers takes `enabled` and `recurring` filters — evidence: the
  Claude Code Remote list_triggers schema — confidence: high

## Out of scope

- Keeper rotation (self-spawned or via the orchestrator's REPLACE): each
  rotation deepens lineage; at cap 8 the fleet strands within 2 to 4 rotations.
- Editing chrsctl/gx; it syncs.
- The orchestrator's own Source check (`orchestrator-reference.md`), already present.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed.
- `bash .agents/harness/selftest.sh` with keeper.md from origin/main — the new
  keeper pins fail.

## Escape

Entry, Gate, Route answered in the pull request body.

## Where to look

- `.claude/commands/keeper.md:Not LIVE` — step 3.
- `.agents/docs/orchestrator-reference.md:Source check` — the orchestrator's version.
- `.agents/harness/selftest/orchestrated.sh:keepfold` — keeper pins.

## Traps

- No core path edits (`joharness.conf`, `.claude/settings.json`, `.github`).
- Never skip or disable a test to get green.
