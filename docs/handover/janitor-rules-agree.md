---
workstream: janitor-rules-agree
status: in-progress
branch: janitor-rules-agree
pr: none
plan: janitor-rules-agree
issue: none
session: https://claude.ai/code/session_01SgfwCMLkTYEfA1n5WW3MvM
agent: sonnet
updated: 2026-10-10
next: Await verifier + ci; record Review; retire plan+workstream files; PR; merge.
---

## Goal

Make janitor.md agree with itself and with cmd_janitor; stop FAILED row releasing throttled sessions (#293, #291, #284).

## Review

- r1: (verifier) orchestrate.md health rows (~141, 187, 328) still say FAILED twice = confirmed dead, no throttled pointer (wontfix: plan puts them out of scope; field-table sentence says no row may act on it)
- r2: (verifier) janitor.md FAILED row verdict cell still said release (fixed: split into own throttled row)
- r3: (verifier) joharness.sh footer "confirmed twice = gone" contradicts (wontfix: owned by janitor-zero-candidate-says-why)
- r4: (verifier) new lines unwrapped (fixed)
- r5: (verifier) step 3 wording unchecked (no change needed: janitor.md:84 carries it); `./joharness.sh ci` -> `ci: pass` 2026-10-10

## Blockers

None.
