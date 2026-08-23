---
workstream: agents-dir-layout
status: review
branch: claude/agents-dir-layout
pr: none
plan: none
session: https://claude.ai/code/session_0178f1MyS7qfR1ovDhqt4pH8
agent: sonnet
updated: 2026-08-23
next: Verify the root AGENTS.md @-import resolves from a dotted path in a FRESH session before merge
---

## Goal

Human: "the harness should end up in a detectable agent structure eg. in
.agents/harness". Both layers now live under one dotted root — a single
place any tool can look to find out this repo runs an agent harness.

## Decisions

- Move in canonical AND consumers, identical paths on both sides. Forced,
  not chosen: the sync engine's `in_history` asks canonical git history
  about the CONSUMER's path. Different spellings per side = every synced
  file reads AHEAD forever, and reconciliation dies. Remapping paths inside
  the engine is the alternative and it is a much bigger tool.
- Both layers, not just `harness/`. The two-layer split is the structure;
  splitting it across two roots to save a smaller diff loses the point.
- Stays at root: `joharness.sh` (human and CI entrypoint), `AGENTS.md`,
  `CLAUDE.md`, `.claude/` (Claude Code reads hooks, commands and skills
  from there — not ours to move), `docs/`, `scripts/`.
- `joharness.sh` grew `AGENTS_ROOT` and `HARNESS_ROOT`. No layer path is
  spelled anywhere else in it, so the next move is one line.
- Sync warns when a consumer still carries root `harness/` or `env/`.
  Keyed on `harness/AGENTS.md` and `env/README.md` existing, never on the
  bare directory: a consumer's own unrelated `env/` must not trip it.
- Branched off `claude/child-repo-updates-5z6m30`, not `main`, because the
  migration step belongs in `docs/consumer-repos.md` and that file exists
  only there. Merge that PR first and this one lands clean on top.

## Rejected

- Teaching the sync engine to delete what canonical dropped, so the old
  tree disappears by itself. That is a general removal feature with a
  general blast radius (a consumer's own files under a synced dir), landing
  inside a layout change. Documented one-time `git rm -r harness env` and a
  warning that repeats until it happens.
- A migration shim (root `harness/` re-exporting `.agents/harness/`). Two
  live spellings is exactly the coupling the move exists to remove.

## Review

None yet — edge-to-main review still owed. Diff is wide (moves plus ~150
re-pointed references); review wants the mechanical pass separated from the
three hand-edited files: `joharness.sh`, `scripts/sync-to-consumer.sh`,
`.agents/harness/README.md`.

## Blockers

One unverifiable-here risk, not a blocker to review: root `AGENTS.md` now
imports `@.agents/harness/AGENTS.md`. This session's context was built
BEFORE the move, so it proves nothing about whether Claude Code resolves an
@-import through a dotted directory. A fresh session in this branch either
shows the harness rules in context or does not. Check before merge.

## Where to look

- `joharness.sh:AGENTS_ROOT` — the only place either layer path is spelled.
- `scripts/sync-to-consumer.sh:DIRS` — `.agents/harness`, `.agents/env`.
  Adding a path here needs the matching fixture stub in the selftest, or
  the run exits 3 MISSING.
- `.agents/harness/selftest.sh:ROOT` — now `../..`, one level deeper.
