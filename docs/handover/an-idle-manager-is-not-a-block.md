---
workstream: an-idle-manager-is-not-a-block
status: in-progress
branch: an-idle-manager-is-not-a-block
pr: none
plan: an-idle-manager-is-not-a-block
issue: 416
session: https://claude.ai/code/session_01KECCKpVfmSgyebTGcefjNq
agent: sonnet
updated: 2026-10-11
next: Read ci and verify output (run in background), run verifier, record Review, retire plan+workstream, PR Closes #416, merge
---

## Goal

Close the idle-in-progress gap (issue #416) in both roles' rules.

## Review

- r1: (verifier) row 137 had no qualifier, overrode blocked/INVALID BLOCK? and generic idle rows (fixed: keyed on ledger `unratified=`)
- r2: (verifier) row 136 read the bucket against the field line saying it never does (fixed: bucket not consulted)
- r3: (verifier) nudge row recorded nothing, pass 2 had no head to compare (fixed: `unratified=<head>` in ledger grammar)
- r4: (verifier) respawn limit undefined on the new respawn row (fixed: at limit report only)
- r5: (verifier) no-transport case undefined (fixed: report only, no respawn)
- r6: (verifier) manage.md did not say which reason fits a missing tool (fixed: `hardware:`)
- r7: (verifier) Environment note wrapping ragged (no change: wrapped like neighbours)

## Blockers

None.
