---
workstream: protocol-boundary-core-only
status: in-progress
branch: claude/protocol-boundary-core-only
pr: none
plan: protocol-boundary-core-only
issue: none
session: https://claude.ai/code/session_013Bg636JRhWFWgWW26RWefB
agent: opus
updated: 2026-10-08
next: Collect worker selftest re-pins, full selftest, ci, verify, verifier
---

## Goal

Requester, 2026-10-08: remove most restrictions; joharness builds itself
under orchestrator. Shrink the protocol boundary to the core paths
(`joharness.conf`, `.claude/settings.json`, `.github`), drop the
requirement-writing ban, add CODEOWNERS. Built supervised (human present,
said "Okay" in session) — the last plan that needs it.

## Decisions

- User-visible wording says "core path(s)" instead of "protocol text" in the
  guard fact, the queue mark, drain's and dispatch's NOT YOURS lines and the
  compaction reminder. Kept "protocol text" would now name a thing that is
  allowed. Marker word `SUPERVISED ONLY` kept (plan: orchestrated-only
  renames it).
- `protocol_paths` keeps its name (plan); `.github` is a TREE whose name
  starts with a dot, so the guard selftest's file/tree switch became `?*.*`.
- The guard selftest's "every shipped .claude tree is inside the boundary"
  case is INVERTED, not deleted: it now pins that no shipped tree is
  re-listed, because re-listing one re-blocks the canonical's whole queue
  silently. Requirement-lint cases rewritten to pin the stage's absence.
- Widened beyond the plan's scope, two lines: `.agents/docs/feedback.md` and
  `.agents/docs/product/README.md` both cited the deleted
  `lint_requirement_writes` as live.
- Fallback in handover-guard.sh (`trees=".agents/harness"` when the
  entrypoint cannot list) left as is: it serves OLD entrypoints, whose own
  boundary did include that tree.

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:protocol_paths` — the list every reader shares.
