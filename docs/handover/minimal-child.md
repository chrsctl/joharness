---
workstream: minimal-child
status: in-progress
branch: claude/celluloid3-update-occ76a
pr: 49
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

- r1: the seeded `.github/workflows/ci.yml` runs the selftest directly, so a
  consumer that deletes it goes red on a file it is no longer sent. Canonical's
  own copy guards the step now, and the seed is a verbatim copy — but a
  consumer seeded BEFORE this must patch its own `ci.yml`, because that file
  is consumer-own and never synced. celluloid3's cleanup carries the patch.
  (fixed here, flagged for existing consumers)
- r2: `CANONICAL_REPO: owner/repo  # comment` would have ridden the comment
  into the clone URL. First token only now. (fixed)
- r3: the `upgrade` EXIT trap referenced a `local`, which is out of scope when
  the trap fires — `set -u` then made the cleanup itself the error. Caught by
  running it; global with a guarded expansion now. (fixed)
- r7: the "present but unrunnable selftest reds ci" case went red on the
  Windows runner: NTFS under Git Bash reports every file executable, so
  `chmod -x` never creates the state the case asserts against. Skipped where
  the bit is not real — the same platform limit the exec-bit repair case
  already skips for. (fixed)
- r4: `report_canonical_only` lists `-type f`, so a symlink under
  `.agents/scripts/` in a consumer goes unreported. Matches the layer report's
  shape and no consumer has one. No change.
- r5: dropping `.agents/scripts` from `DIRS` also drops it from the
  dirty-canonical guard. Correct by construction — nothing there ships, so
  uncommitted work in it cannot reach a consumer. No change.
- r6: `upgrade` clones over HTTPS with whatever credentials the environment
  holds; against a private canonical outside a credentialed sandbox it fails
  with git's own error. Accepted: the alternative is this command growing a
  token story that `update.yml` already owns.

## Blockers

None.

## Where to look

- `.agents/scripts/sync-to-consumer.sh` — `CANONICAL_ONLY` skip list and its
  report.
- `joharness.sh` — `cmd_upgrade`, and the `ci` selftest guard.
- `.github/workflows/ci.yml` — the windows job must tolerate a repo with no
  selftest; it is seeded verbatim into children.
