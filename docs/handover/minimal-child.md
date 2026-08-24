---
workstream: minimal-child
status: in-progress
branch: claude/celluloid3-update-occ76a
pr: none
plan: none
session: https://claude.ai/code/session_01JoK1BRUuDsQ2VR9zbJMKHD
agent: opus
updated: 2026-08-24
next: Implement the canonical-only skip list in the sync engine, then joharness.sh upgrade, then ci and the seeded ci.yml guards
---

## Goal

Human: a child repo should carry a minimal config after initialization, and
still be able to update/upgrade. celluloid3 carries 320K under `.agents/`:
84K of `selftest.sh` (canonical's own regression suite) and 48K of
`sync-to-consumer.sh` + `bootstrap-consumer.sh`, both of which REFUSE to run
in a consumer — 41% of the tree is code a child can never execute.

## Decisions

- Canonical-only set = `.agents/harness/selftest.sh` and `.agents/scripts/`.
  Chosen by the same test as the layers: does the child run it? The two sync
  tools die on a missing `JOHARNESS_CANONICAL=1`, and the selftest tests
  harness code a child never edits.
- Protocol docs under `.agents/docs/` STAY. They are the rulebook every
  session reads; a child without them has dangling links in its own
  AGENTS.md.
- `joharness.sh upgrade` is what keeps the second half of the ask true: a
  child that no longer carries the sync engine can still fetch canonical and
  run ITS engine, one command, no recipe to follow.
- Canonical address comes from `.github/workflows/update.yml`'s
  `CANONICAL_REPO`, the child's existing single source of truth for it
  (a fork names its own there). No second key in `joharness.conf`.
- Existing children keep those files until a human deletes them — same rule
  as unused layers: removals never travel.

## Rejected

- Fetching the harness into a gitignored cache at session start, leaving
  ~6 files in the child. Claude Code discovers `.claude/commands/` and
  `.claude/skills/` from the repo tree, and the hooks in
  `.claude/settings.json` are repo paths — a cache would not be found, and
  session start would need network to work at all.
- Dropping `.agents/docs/`. The child runs the same protocol; the docs are
  what the protocol IS.

## Review

## Blockers

None.

## Where to look

- `.agents/scripts/sync-to-consumer.sh` — `CANONICAL_ONLY` skip list and its
  report.
- `joharness.sh` — `cmd_upgrade`, and the `ci` selftest guard.
- `.github/workflows/ci.yml` — the windows job must tolerate a repo with no
  selftest; it is seeded verbatim into children.
