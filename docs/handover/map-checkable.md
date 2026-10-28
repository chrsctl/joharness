---
workstream: map-checkable
status: in-progress
branch: claude/map-checkable
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01W18Uk51vWUnKgHZiX9b4KR
agent: sonnet
updated: 2026-10-28
next: ci alone, mutation check, verifier at haiku, finish, PR, merge; then sync gx and re-run /map on gx PR 1050
---

## Goal

First full `/map` in a consumer (its draft PR 1050): mechanics held, content
did not. A sonnet reviewer sampling 10 indexes found 34 problems, about 8 flat
wrong, nearly all in Invariants and Side effects prose no check reads. The
run also hit five harness defects: dotted symbols rejected, repo-root paths
rejected, `host:port` read as `file:symbol`, no `git add` step, read cap not
kept. Fix: an index states only what a reader can check.

## Decisions

- Drop Invariants and Side effects rather than demand a citation per claim: a
  citation proves the symbol exists, not that the sentence about it is true
  (the run's `_RETRYABLE` line cited a real symbol and was wrong).
- Interface text is at most 8 words from the symbol's name, signature or
  docstring; Verify only a command the repo already runs, naming where.

## Review

- r1: mutation — new selftest against origin/main's joharness.sh, `ci` 2026-10-28: 3 cases FAIL (dotted symbol, repo-root path, address); the fourth (Interface-only) passed without the fix because `make x:nosuch` never matched a file — now `f.txt:nosuch` under `## Verify` (fixed)
- r2: mutation re-run with r1's fix, `ci` 2026-10-28: all 4 new cases FAIL against origin/main's joharness.sh; head `ci: pass` (no change)
- r3: (verifier) spawn prompt carried the head sha beyond the listed fields (no change: no rationale or findings passed)
- r4: (verifier) `api.example.com:443` still read as file:symbol — an all-digit symbol is a port, never a symbol; case added (fixed)
- r5: (verifier) `t.py:Missing.permits` passed on `permits` alone — every dotted part must be in the file; case added (fixed)
- r6: (verifier) caps in map.md (8 lines, 8 words, 12 words, 8 folders) have no counting command (wontfix: cost guidance for workers, not a correctness claim; correctness is the reference check)
- r7: (verifier) worker-prompt rules and the gx evidence are not re-taken in this checkout (no change: the gx re-run of /map measures them)

## Blockers

None.
