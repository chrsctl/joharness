---
workstream: retired-ledger-absent-stderr
status: in-progress
branch: claude/retired-ledger-absent-stderr
pr: none
plan: retired-ledger-absent-stderr
issue: none
session: https://claude.ai/code/session_01TqtiuCHRzVHgqz4DSRHHxd
agent: sonnet
updated: 2026-10-14
next: Add the failing selftest arm, then guard the read in joharness.sh
---

## Goal

A consumer (chrsctl/gx, 2026-10-14) saw `./joharness.sh ci` print
`joharness.sh: line N: .../docs/plans/RETIRED.md: No such file or directory`
once per plan its branch added, whenever the branch's tree has no ledger.
The verdict was right; the noise reads as a harness fault. Fix it in
canonical first, then it syncs out.

## Decisions

- Cause: `retired_ref ... <"$file" 2>/dev/null` — bash applies redirections
  left to right, so the input redirect fails before stderr is silenced.
  Guard with `[ -f ]` rather than reorder the redirects: an absent ledger
  is a normal state and should not be an attempted read at all.

## Rejected

None yet.

## Review

One bullet per finding, written BEFORE its fix, committed WITH it, in exactly
the form `- rN: text (fixed|wontfix: why|no change)` — `ci` checks it. Tag the
verifier's findings `(verifier)`. Clean pass = one bullet saying so. Remove
this paragraph when you add the first bullet.

## Blockers

None.

## Where to look

- `joharness.sh` — the branch-own-ledger arm in the plans-on-this-branch stage.
- `.agents/harness/selftest/retired-ledger.sh` — the fixture.
