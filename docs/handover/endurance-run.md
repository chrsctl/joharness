---
workstream: endurance-run
status: in-progress
branch: claude/endurance-run
pr: none
plan: docs/plans/unsupervised-endurance.md
issue: 165
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Merge the setup (PR 173), spawn the fleet, measure until it stops on its own.
---

## Goal

Measure the bullet the requirement's Goal is built on: started once, the
fleet keeps going for hours with no human turn, for as long as a goal is
open.

## Authorisation

"Implement unsupervised endurance", 2026-08-31, after "Flip the mode"
earlier the same day and after issue #165 put the cost in front of the
requester.

## Decisions

- **This branch holds the CLAIM and stays unmerged during the run.** Merging
  it would free `unsupervised-endurance` and let a spawned session claim the
  run it is inside.
- **Setup is a separate branch** (PR 173): the committed mode flip, and a
  plan recorded while sizing the run.

## Review

To be recorded before the merge.

## Blockers

None.
