---
workstream: orchestrated-only-docs
status: done
branch: manage/orchestrated-only-docs
pr: none
plan: orchestrated-only-docs
issue: none
session: https://claude.ai/code/session_015Hp3oMVYL5ciQDrvTxJb22
agent: sonnet
updated: 2026-10-10
next: none - retired
---

## Goal

Docs describe one mode (orchestrated). Plan: docs/plans/orchestrated-only-docs.md.

## Review

- (verifier) The one stop deleted, not moved; dangling "edge rule below": restored section in orchestrated.md.
- (verifier) Stale "mode line authority verifies" in three places: reworded to rule files + cap.
- (verifier) Comparisons with other modes survive in orchestrated.md: table header/"New" removed, peer-fleet phrasing cut; history rows and the quoted ask kept.
- (verifier) Dead intra-doc refs ("What the mode changes", "Runs above"): fixed.
- (verifier) Research files cited old line numbers: pointed at `git show 7f63a01a:` instead.
- (verifier) Code and selftest still named the deleted file: repointed with the selftest in the same commit; banner pointer dropped, since the orchestrated selftest forbids the banner naming the design doc (ci red before, `./joharness.sh ci` -> `ci: pass` after, 2026-10-10).
- (verifier) Duplicate row in harness README: merged.
- Left: quoted requester ask at orchestrated.md and Runs rows keep "unsupervised"; joharness.conf lines 73/85 still name the deleted file (core path, human's).
