---
workstream: agents-dir-layout
status: review
branch: claude/agents-dir-layout
pr: none
plan: none
session: https://claude.ai/code/session_0178f1MyS7qfR1ovDhqt4pH8
agent: sonnet
updated: 2026-08-23
next: Merge when GitHub checks green (step 7 conditions; ci and verify owed green first)
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

`/code-review` (high) on full diff vs `main`, round 1:

- r1: legacy-layout warning keyed on `env/README.md` merely existing — a
  consumer's OWN file at that path would draw `git rm -r env` advice at
  consumer files. Old-path files now blob-vouched via `in_history`, the
  same rule every stale-vs-AHEAD call uses; shallow canonical degrades to
  silence. (fixed)
- r2: warning not gated on the new tree standing — a `--dry-run` before
  the first sync places nothing, so "nothing reads the old tree" would
  advise deleting the LIVE harness. Gated on
  `DEST/.agents/harness/AGENTS.md` existing. (fixed)
- r3: `.agents/env/README.md` caveman link broke in the move
  (`../docs/` is one level short from the new depth). (fixed)
- r4: `@.agents/harness/AGENTS.md` import unverified through a dotted
  dir. Verified empirically: CLI 2.1.241, scratch project with the exact
  chain `CLAUDE.md → @AGENTS.md → @.agents/harness/AGENTS.md`, sentinel
  in the imported file comes back from a fresh `claude --print`. (fixed)
- r5: `.agents/env/k8s/AGENTS.md` self-link `(.agents/env/k8s/README.md)`
  resolves nested from inside its own dir; same defect was fixed in the
  docker sibling, this one missed. (fixed)
- r6: "remedy names only what exists" test needle was a substring of the
  failure-mode output — could never fail. Needle pins the remedy tail;
  fixture canonical grew pre-move history so blob-vouching is testable,
  plus consumer-own-content and dry-run-gate cases. (fixed)
- r7: recorded in `consumer-repo-entrypoint.md` (hardcoded canonical URL;
  fixed on that branch, merged in).

Repo-wide relative-link audit after r3/r5: 0 broken.

## Blockers

None.

## Where to look

- `joharness.sh:AGENTS_ROOT` — the only place either layer path is spelled.
- `scripts/sync-to-consumer.sh:DIRS` — `.agents/harness`, `.agents/env`.
  Adding a path here needs the matching fixture stub in the selftest, or
  the run exits 3 MISSING.
- `.agents/harness/selftest.sh:ROOT` — now `../..`, one level deeper.
