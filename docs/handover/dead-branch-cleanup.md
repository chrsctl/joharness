---
workstream: dead-branch-cleanup
status: review
branch: claude/delete-merged-remote-branch-61qy2f
pr: none
plan: none
agent: sonnet
updated: 2026-08-23
session: https://claude.ai/code/session_01MhevorBe88x3x2wiVMFGJb
next: Open PR, merge. Human: enable repo setting "Automatically delete head branches", run the delete command the hook prints once.
---

## Goal

Finish protocol told the session to delete the merged remote branch. A remote
session cannot: the permission classifier blocks `git push --delete`, the
GitHub MCP set has no branch-delete tool, and the human ruled session-side
deletion out. Make the protocol match reality — deletion is the human's job
(Delete-branch button on the merged PR page, or the repo's auto-delete
setting) — and make standing deadwood visible instead of silently rotting.

## Decisions

- Hook (`handover-context.sh`) collects branches merged into the base but
  still standing on origin, prints them as one ready-to-run
  `git push origin --delete ...` line for the human. Same philosophy as the
  main rot check: make rot visible, don't trust discipline.
- Only `origin/*` refs counted (fork copies skipped), base branch excluded —
  `origin/main` is trivially its own ancestor.
- Docs updated to match: `harness/AGENTS.md` Loop step 7,
  `docs/product/README.md` Branch flow "Finish".

## Rejected

- Session-side `git push --delete` (retry or permission grant) — human
  declined it ("No in child repos"); now codified as never.
- Enabling "Automatically delete head branches" from the session — GitHub MCP
  exposes no repo-settings tool; one human click in Settings → General.
- Listing dead branches one per line — a dozen lines of context every session
  start; one command line carries the same information and is directly
  runnable.

## Blockers

None.

## Where to look

- `harness/handover-context.sh` — dead-branch collection in the other-branch
  loop, output block after the main rot check.
- `harness/selftest.sh` — "handover-context.sh dead branches" step.
