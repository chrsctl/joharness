---
workstream: consumer-bootstrap-robust
status: in-progress
branch: manage/consumer-bootstrap-robust
pr: none
plan: consumer-bootstrap-robust
issue: none
session: https://claude.ai/code/session_01QDNr7h9NRWwvLhFQipZRqU
agent: opus
updated: 2026-10-22
next: Research anchors, write red selftests, then fix bootstrap, sync settings.json, UNREADABLE
---

## Goal

Plan `consumer-bootstrap-robust`: bootstrap must not half-write a target that
holds its own CLAUDE.md/settings.json/.gitattributes; sync ships only the
`hooks` key of `.claude/settings.json`; a failed consumer blob read is
UNREADABLE, never classified; fix the `ci-verify-layers.sh` header comment.
Core-path remainder (ci.yml `[ -f ]` guard) goes to a `human/` pull request.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `.agents/scripts/sync-to-consumer.sh` — AHEAD check, `consumer_blob`.
- `.agents/scripts/bootstrap-consumer.sh` — fresh mode.
