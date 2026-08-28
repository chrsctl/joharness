---
workstream: unsupervised-boundary
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: unsupervised-boundary
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: sonnet
updated: 2026-08-28
next: State the boundary by role with both trees named, in all three places
---

## Goal

Issue #114, filed from the verifier's `r11` against PR #110. The boundary
keeping an unattended session from rewriting the protocol that governs it is
spelled as one path prefix, `.agents/harness/`, and `.claude/agents/` — now
mandatory protocol text — sits outside it.

## Decisions

- Plan filed and claimed in the same branch. Issues outrank plans in the
  queue but nothing builds unplanned; a small ask gets a small plan, and
  decomposing a three-line rule edit into a separate queue round would be
  the ceremony the carve-out exists to avoid. Recorded because it is a
  departure from the usual claim-from-queue path.
- Role WITH extent, not one or the other. Role alone ("protocol text") is
  unenforceable and a session cannot tell what counts; a bare path list goes
  stale the next time protocol text moves. Both gives a literal reader the
  rule and something greppable.
- No mechanical gate. The mode is advisory everywhere else here, and `ci`
  already reds on the specific deletion the issue names (PR #110's
  assertion, mutation-verified at 622/1). A hook that blocks the commit
  would be a fourth limit where the requester declined three on 2026-08-24.

## Rejected

(nothing yet)

## Review

(pending)

## Blockers

None.

## Where to look

- `docs/product/unsupervised-mode.md`, Constraints — the ratified text.
- `joharness.sh`, the unsupervised banner block.
- `.agents/harness/AGENTS.md`, step 2 "Boundary holds".
