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

- r1: new selftest cases red on the tests-only commit: `bash .agents/harness/selftest.sh` 2026-10-22 = 3016 passed, 10 failed, all 10 the new cases (no change)
- r2: (verifier) own-layer deletion refute passed without the fix: layer had no canonical history (fixed: cases use layer aaa and canonical-only .agents/scripts/bootstrap-consumer.sh, both with history)
- r3: (verifier) bootstrap refusal advised moving .gitattributes/settings into AGENTS.md and dropped the jq-absent note (fixed: per-kind advice, engine note lines passed through)
- r4: (verifier) unreadable settings.json read as AHEAD not JSON (fixed: unreadable checked first)
- r5: (verifier) empty settings.json reported as hooks AHEAD (fixed: empty = AHEAD not valid JSON, case added)
- r6: (verifier) canonical settings.json parse failure died mid-write with exit 1 (fixed: checked in preflight)
- r7: (verifier) update.yml labels exit 2 as AHEAD, summary line omits UNREADABLE (wontfix: update.yml is a core path; the engine logs the UNREADABLE count on its own line)
- r8: (verifier) hooks insert and canonical-without-hooks paths untested; only one jq branch runs per machine (fixed: both paths have cases; the branch split stays, jq cannot be hidden from PATH without rebuilding it)
- r9: ci shellcheck SC2012 on a new test message (fixed: ls dropped)

## Blockers

None.

## Where to look

- `.agents/scripts/sync-to-consumer.sh` — AHEAD check, `consumer_blob`.
- `.agents/scripts/bootstrap-consumer.sh` — fresh mode.
