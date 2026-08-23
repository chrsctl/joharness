---
workstream: consumer-repo-entrypoint
status: review
branch: claude/child-repo-updates-5z6m30
pr: none
plan: none
session: https://claude.ai/code/session_0178f1MyS7qfR1ovDhqt4pH8
agent: sonnet
updated: 2026-08-23
next: Merge when GitHub checks green (step 7 conditions; verify already green locally)
---

## Goal

Human asked twice how to update a child repo, then asked for a single entry
point file. Answer lived in five places — root `README.md`, the two script
headers, `update.yml` comments, `docs/product/README.md` Reconciliation —
and none of them held the agent-in-the-consumer route at all.

## Decisions

- `docs/consumer-repos.md`, not `docs/sync.md`: covers create, update and
  reconcile, so naming it after one verb undersells it.
- Opens by equating consumer = child. Repo says "consumer", humans say
  "child"; a grep for either must land here.
- Added to sync `FILES`, so consumers carry it. A consumer session doing a
  sync reads its own copy — that is the whole point of an entry point.
- Pointers replace prose at the five old sites, not additions. Caveman
  "state each fact once"; two copies of the token rules is how one goes
  stale.
- `harness/AGENTS.md` gets one pointer on the existing copy-or-sync bullet.
  It loads every session, so it earns exactly one line.
- Fixed while here: `harness/README.md` NOT-harness-owned list named
  `ci.yml` but not `update.yml`. Both are seeded-once, consumer-own.

## Rejected

- Doc under `harness/`. It is instructions ABOUT the harness copy, not part
  of the protocol every session runs; `docs/` is where `caveman.md` and
  `agent-selection.md` already sit, and both sync the same way.
- Leaving it joharness-only (not in `FILES`). Then the agent that most
  needs it — one sitting in a consumer with no canonical checkout — is
  exactly the one that cannot read it.

## Review

- r1: agent route hardcoded `chrsctl/joharness` in a file that syncs to
  every consumer — a fork's consumer following it verbatim clones the
  wrong canonical and reads honest files AHEAD forever. Route now derives
  the address from the consumer's own `update.yml` `CANONICAL_REPO`.
  (fixed)

## Blockers

None.

## Where to look

- `scripts/sync-to-consumer.sh:FILES` — adding a path here means both
  selftest fixture stub loops need it too, or the run exits 3 MISSING.
- `harness/selftest.sh:1085` and `:1463` — those two loops.
