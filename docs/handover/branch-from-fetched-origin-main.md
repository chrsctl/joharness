---
workstream: branch-from-fetched-origin-main
status: in-progress
branch: manage-branch-from-fetched-origin-main
pr: none
plan: branch-from-fetched-origin-main
issue: 418
session: https://claude.ai/code/session_018PhRSjdNwbJUif5hRktTJ4
agent: sonnet
updated: 2026-10-11
next: Await ci + verify green, run verifier review, record ## Review, retire files, open PR
---

## Goal

Close the stale-local-`main` trap (issue #418): rule text, hook line, pushed-branch rule.

## Review

- r1: step 3 "never push -f" reads against orchestrate GUARD / janitor force-with-lease (verifier) (fixed)
- r2: merging origin/main in drags stale-base history into the PR (verifier) (wontfix: plan prescribes merge, rebase breaks shared checkouts)
- r3: "fresh origin/main" vs "fresh-fetched" spelling drift (verifier) (fixed)

## Blockers

None.
