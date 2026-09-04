---
workstream: conf-keys-on-update
status: in-progress
branch: claude/drain-session-access-r80jpt
pr: none
plan: conf-keys-on-update
issue: none
session: https://claude.ai/code/session_01HkdcTFBBEsYFS3MKbxjZ3R
agent: sonnet
updated: 2026-09-04
next: Write conf-keys.sh, then the sync report stage, then the ask, then the cases.
---

## Goal

First contact asks about every switch; update asks about nothing. A child
bootstrapped before a key existed never learns of it, and `JOHARNESS_MODE`
landed this week, so every child older than that is in that position now.

## Decisions

- **One declaration, sourced by both scripts.** The list already exists twice
  in the bootstrap alone (the interview and the seed heredoc) and a third copy
  in the sync would be the drift this repo keeps paying for. A selftest case
  reds if the seeded conf and the declaration name different keys.
- **`.agents/scripts` is canonical-only**, proven by `CANONICAL_ONLY_DIRS` in
  the sync engine. So the declaration reaches every consumer's update by being
  in canonical, and nothing new ships.
- **Report always, ask only with a terminal, write only what was answered.**
  `update.yml` runs on a cron with nobody to ask, and it already carries the
  sync report into its pull request body, so the report is the channel that
  works everywhere and the ask is a bonus for a human running the sync.
- **Append, never overwrite.** The conf is consumer-own. A key the consumer
  already holds is not re-asked and not touched.

## Rejected

- (to fill as the build finds them)

## Review

(to fill at step 5)

## Blockers

None.

## Where to look

- `.agents/scripts/sync-to-consumer.sh` — report stages live near the end.
- `.agents/scripts/bootstrap-consumer.sh` — the interview and the seed.
