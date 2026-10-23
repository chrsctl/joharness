---
workstream: fast-lane
status: in-progress
branch: claude/fast-lane
pr: none
plan: fast-lane
issue: none
session: https://claude.ai/code/session_01PoyAytHA6a4PwcFm6XW6qK
agent: opus
updated: 2026-10-23
next: Build the ci stage, graph-lint case and review tier, then the selftest topic
---

## Goal

A typo fix should not pay the full plan cost. Define a fast lane (`plan:
fast`) narrow enough that `ci` proves a branch qualifies; it skips the plan
file and keeps workstream file, verifier, ci, verify and finish.

## Decisions

- The proposed rule holds; it is ci-provable. A branch is fast-lane when a
  workstream file it ADDED (`fin_own_ws`, read from git so a retired one
  still counts) says `plan: fast`. Then, against the merge base with
  `origin/main`: at most 3 paths changed, none at or under a core path
  (`protocol_paths`), no plan added (`plans_in_diff`). New ci stage
  `fast lane`, after `plans on this branch`; every breach named.
- Counted: `git diff --no-renames --name-only <base> HEAD` minus
  `docs/handover/`. The workstream file is the lane's own cost and is gone
  by merge; deletes and both sides of a rename count as touched.
- A node named `fast` (plan, research or requirement) is red in graph lint:
  a workstream claim resolves research/product stems too, so any of the
  three would turn the lane into a claim on it.
- `review_tier`: `plan: fast` = haiku, over the workstream's `agent:`. The
  bound is what makes one pass enough; a fixed depth is what ci can print.
  The recipe is a floor, never a cap on a deeper pass.
- dispatch, the hook, `free`, janitor: no code change. A scratch clone with
  a pushed `plan: fast` branch showed dispatch prints no row for it and the
  hook prints it like any claim: a stem with no file is no queue item. The
  selftest pins dispatch's silence. Graph lint was the one reader treating
  it as a missing stem (DEAD ... never existed): fixed there.

## Rejected

- Counting the workstream file toward 3: every fast branch would start at
  1 of 3, and the file is deleted before merge anyway.

## Review

- Pending.

## Blockers

None.

## Where to look

- `docs/plans/fast-lane.md` — the item.
