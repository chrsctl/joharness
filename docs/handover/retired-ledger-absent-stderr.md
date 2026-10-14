---
workstream: retired-ledger-absent-stderr
status: review
branch: claude/retired-ledger-absent-stderr
pr: none
plan: retired-ledger-absent-stderr
issue: none
session: https://claude.ai/code/session_01TqtiuCHRzVHgqz4DSRHHxd
agent: sonnet
updated: 2026-10-14
next: Retire, open PR, merge when GitHub checks are green
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

- r1: clean pass at sonnet, no findings; the whole-output refute is broader than the fix needs and still catches the regression (verifier) (no change)
- r2: `./joharness.sh verify` red here on the docker layer: Docker Hub answers 429 for `alpine:3` from this container, unrelated to the diff; GitHub's ci runs `verify` on the head (self) (no change)

## Blockers

None.

## Where to look

- `joharness.sh` — the branch-own-ledger arm in the plans-on-this-branch stage.
- `.agents/harness/selftest/retired-ledger.sh` — the fixture.
