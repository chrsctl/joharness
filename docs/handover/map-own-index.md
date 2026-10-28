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

- r1: (verifier) spawn prompt carried an operational note (do not run ci) and the workstream path beyond the listed fields (no change: no rationale or findings were passed; noted)
- r2: (verifier) a /map index with a trailing blank on its heading, or an empty file, read as a person's and hid its broken links — trailing blanks trimmed, an empty file is ours; selftest case (fixed)
- r3: (verifier) no case asserted a person's index is never stale — case added (fixed)
- r4: (verifier) `/map <folder>` naming a person's folder is refused only in prose (wontfix: /map is a procedure an agent follows; map never lists such a folder, so no work list carries it)
- r5: mutation — without the ownership check, `ci` 2026-10-28 FAILS 3 new cases (orphan, link-check, current) (no change)
- r6: first `ci` red on c2-run worktree lock: two `ci` runs in parallel shared fixture worktrees; rerun alone (no change)

## Blockers

None.
