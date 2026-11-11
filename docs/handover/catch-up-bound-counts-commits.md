---
workstream: catch-up-bound-counts-commits
status: in-progress
branch: manager/catch-up-bound-counts-commits
pr: none
plan: catch-up-bound-counts-commits
issue: none
session: https://claude.ai/code/session_01J1YMK5pHjzAh4525PuCj4d
agent: sonnet
updated: 2026-11-11
next: Verify (ci, review), open PR, merge
---

## Goal

Settle whether CATCH-UP's commit bound measures how far the base moved when a
consumer's merged PRs carry several commits each; graduate the answer.

## Decisions

- Answer: the bound counts commits, not pull requests (graduated to consumer-repos.md). Follow-up plan catch-up-print-merge-count prints both numbers; the knob is unchanged until merge-count evidence exists.

## Review

- r1: doc stated the merge count as printed today, code does not (verifier) (fixed: reworded to name the plan, until it lands commits only)
- r2: plan acceptance left N unspecified, second line untested, consumer check not self-contained (verifier) (fixed: plan rewritten)
- r3: 3-4 PRs arithmetic is 2.5-4 (verifier) (fixed)
- r4: gx figures cannot be re-run here (verifier) (no change: marked GROUNDED/WEAK per who re-took them, in the doc)

## Blockers

None.

## Where to look

- `joharness.sh:checks_catch_up` — the `rev-list --count` bound.
- `.agents/docs/consumer-repos.md` — § Local checks, graduation target.
