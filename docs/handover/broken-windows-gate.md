---
workstream: broken-windows-gate
status: in-progress
branch: claude/broken-windows-gate-mgr
pr: none
plan: broken-windows-gate
issue: none
session: https://claude.ai/code/session_01HGTPqiqvLRRKSqLu3R3KhF
agent: sonnet
updated: 2026-10-23
next: Read /tmp/ci.out (full ci running; rerun ./joharness.sh ci if gone). Fix failures, run verify, verifier review, retire plan+ws, PR, merge
---

## Goal

Make "never skip/disable a test" a ci check: added skip marker or TODO/FIXME in non-md file reds ci unless `## Review` waives the path.

## Decisions

- Lint is ci_broken_windows in joharness.sh; waivers read from fin_own_ws files via lint_ws_content. Markers built from parts so the file never trips itself. Selftest topic broken-windows.sh registered after ci-churn. README bullet added. Built, ci result not yet confirmed.

## Rejected

## Review

- r1: .only( / @skip( / XXX hit legitimate code (ORM, GraphQL, placeholders) (verifier) (wontfix: plan lists these markers; path waiver is the plan's answer)
- r2: waiver sed takes the LAST "window" in a bullet, no word boundary, trailing comma kept (verifier) (fixed)
- r3: git-quoted paths (quote or tab in name) never match a waiver (verifier) (wontfix: rare; git quoting only for such names, path waiver for them out of scope)
- r4: noprefix config makes the b/ strip eat a real b/ directory (verifier) (fixed)
- r5: awk -v expands backslashes in waived paths (verifier) (fixed)
- r6: sync/copy tasks have no workstream file to waive in (verifier) (no change: no tracked non-md file carries a marker today)

## Blockers

None.

## Where to look

- `joharness.sh:lint_ws_in_diff`
