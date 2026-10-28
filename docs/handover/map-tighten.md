---
workstream: map-tighten
status: in-progress
branch: claude/map-tighten
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01W18Uk51vWUnKgHZiX9b4KR
agent: sonnet
updated: 2026-10-28
next: ci, verifier at haiku, finish, PR, merge, sync into gx
---

## Goal

User ask: tighten `/map` with what its second consumer run reported. A 6-file
read cap stopped a worker before the entry files (two folders redone at
sonnet); "deepest first" had no effect on workers running in parallel; `map`
reads `stale` until the files are committed, so the re-check only read clean
after the commit; workers could not overwrite an index with a write tool
that refuses unread files.

## Decisions

- Workers run at any depth in parallel; only `## Folders` depends on
  children, and the session writes it after all return.
- Cap 8 files, entry points first, and a capped worker writes from what it
  read rather than nothing.
- Commit before the re-check, and the re-check now also refuses `stale`.

## Review

## Blockers

None.
