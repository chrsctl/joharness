---
workstream: park-holds-only-on-pr
status: in-progress
branch: manager/park-holds-only-on-pr
pr: none
plan: park-holds-only-on-pr
issue: none
session: https://claude.ai/code/session_01J1YMK4dqucWtcTNf81wHy8
agent: opus
updated: 2026-11-11
next: Run plan-checker on the plan, then build joharness.sh DS_NAMED and the selftest cases
---

## Goal

A parked manager holds its scope only while it waits on a real fix: "They
should hold only if they are waiting for a PR" — a park waiting on an issue
with no PR yet frees everything. Plan carried from branch
plan/core-only-spawns-manager (owner branch; nothing pushed there).

## Decisions

- Carried plan: own branch from origin/main, plan copied; retire appends the stem to docs/plans/RETIRED.md.
- A1: confirmed — `joharness.sh:dispatch` free loop: a holder not in `blocked_claims` sets `hold_live=1` → `HOLD — overlaps`; selftest dispatch-park.sh "a plan overlapping a parked item is held".
- A2: confirmed — in `blocked_claims` the overlap row reads `overlaps … BLOCKED on a human: spawn`; the claim row, its RESUME/RECHECK classification and slot accounting never read `blocked_claims`.
- A3: confirmed — `plan_names_issue` reads `git show <rev>:<path>`; dispatch primes `BASE_ISSUES` from one `git grep` on the base.
- Plan refuted in two places, fixed on the branch: (a) scope named `.agents/docs/orchestrate-reference.md`, which does not exist — it is `orchestrator-reference.md`; (b) "a `core path: waiting on #N` block keeps holding its scope" is false today: while #N is open it is released as any human block. "Unchanged" governs: this build does not touch it; flagged in the PR body for the human.
- Fail closed: `dispatch_defect_state` exports `DS_NAMED` = 1 / 0 / ? (base or live-branch plan scan unreadable). Only 0 releases; classification (UNPLANNED, RECHECK) keeps reading its own `named`, unchanged.
- Build done inline, not by workers: one function pair and one case arm in one file, the selftest depends on the exact row text.

## Review

None yet.

## Blockers

None.

## Where to look

- `joharness.sh:dispatch` — parked-row `case "$dst"` and `blocked_claims`.
