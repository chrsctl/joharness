---
workstream: known-red-base-is-the-consumers
status: in-progress
branch: known-red-base-is-the-consumers
pr: none
plan: known-red-base-is-the-consumers
issue: none
session: https://claude.ai/code/session_01T1Uueeti8hGcm6dZTLnX2F
agent: haiku
updated: 2026-10-10
next: Spawn the verifier on the branch diff, record its findings under ## Review, then retire the plan and workstream files and open the pull request.
---

## Goal

Issue #305, option 1. In a consumer with a red base branch, managers rebuild
the same baseline and re-run the suite to attribute the same pre-existing
failures. Say once that the record is the consumer's, and step 7 still binds.

## Decisions

- Doc-only change, one section, placed before "## The sync pull request:
  drive it to merged". Plan scope is `shared:.agents/docs/consumer-repos.md`.
- No harness reader, no GitHub read (#305 options 2 and 3 are out of scope).

## Rejected

None yet.

## Review

## Blockers

None.

## Where to look

- `.agents/docs/consumer-repos.md:324` — `## The sync pull request: drive it to merged`, the anchor the new section precedes.
- `.agents/harness/AGENTS.md` — step 5 and step 7 (infrastructure reading re-derived at every check).
- `.agents/docs/feedback.md` — "Trust counted numbers, never written numbers".
