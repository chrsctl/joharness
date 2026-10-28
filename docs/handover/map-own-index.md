---
workstream: map-own-index
status: in-progress
branch: claude/map-own-index
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01W18Uk51vWUnKgHZiX9b4KR
agent: sonnet
updated: 2026-10-28
next: ci, mutation check, verifier at haiku, finish, PR, merge; then re-sync gx
---

## Goal

Defect found syncing #673 into a consumer: it keeps hand-written `INDEX.md`
files in `docs/`, `docs/adr/`, `docs/phases/`. `map` listed them as orphans
and `/map` deletes orphans, so the first run would delete a person's docs; a
hand-written `INDEX.md` in a product folder would be written over. Only an
`INDEX.md` whose first line is `# <dir>/` (what `/map` writes) is ours.

## Decisions

- Signature over a second file name: the name stays `INDEX.md`, and a
  person's file is never touched, never listed, and covers its folder.

## Review

## Blockers

None.
