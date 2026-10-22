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
next: Selftest green check, then ci, verify, verifier review, retire
---

## Goal

Plan `consumer-bootstrap-robust`: bootstrap must not half-write a target that
holds its own CLAUDE.md/settings.json/.gitattributes; sync ships only the
`hooks` key of `.claude/settings.json`; a failed consumer blob read is
UNREADABLE, never classified; fix the `ci-verify-layers.sh` header comment.
Core-path remainder (ci.yml `[ -f ]` guard) goes to a `human/` pull request.

## Decisions

- No human-remainder pull request: the `ci.yml` `[ -f ]` guard the plan's
  Out of scope asks for is already on `origin/main` (`.github/workflows/ci.yml`,
  the `ci-verify-layers.sh` step). Nothing core-path is left.
- Built by the manager, no workers: all five files are one coupled change
  (bootstrap's preflight reads the engine's AHEAD/UNREADABLE lines), so no
  disjoint split exists.
- settings.json: consumer `hooks` absent/null = nothing of its own to
  overwrite, canonical hooks inserted; consumer hooks matching any historical
  canonical `hooks` (jq -S -c) replaced; anything else AHEAD. Not valid JSON =
  AHEAD. Canonical without hooks deletes the key rather than writing null.
- UNREADABLE counts toward exit 2 (the "not overwritten, look" code); the
  summary line format is unchanged (update.yml carries it), a separate log
  line names the count.
- Bootstrap preflight refusal exits 1 (refused, nothing written) — the
  header's existing meaning of 1.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `.agents/scripts/sync-to-consumer.sh` — AHEAD check, `consumer_blob`.
- `.agents/scripts/bootstrap-consumer.sh` — fresh mode.
