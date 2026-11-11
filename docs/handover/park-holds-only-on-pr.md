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
next: Run ci and verify, then the verifier at the review tier
---

## Goal

A parked manager holds its scope only while it waits on a real fix: "They
should hold only if they are waiting for a PR" — a park waiting on an issue
with no PR yet frees everything. Plan carried from branch
plan/core-only-spawns-manager (owner branch; nothing pushed there).

## Decisions

- Carried plan: own branch from origin/main, plan copied; retire appends the stem to docs/plans/RETIRED.md.
- A1: confirmed — `joharness.sh:cmd_dispatch` free loop: a holder not in `blocked_claims` sets `hold_live=1` → `HOLD — overlaps`; selftest dispatch-park.sh "a plan overlapping a parked item is held".
- A2: confirmed — in `blocked_claims` the overlap row reads `overlaps … BLOCKED on a human: spawn`; the claim row, its RESUME/RECHECK classification and slot accounting never read `blocked_claims`.
- A3: confirmed — `plan_names_issue` reads `git show <rev>:<path>`; dispatch primes `BASE_ISSUES` from one `git grep` on the base.
- Plan refuted in two places, fixed on the branch: (a) scope named `.agents/docs/orchestrate-reference.md`, which does not exist — it is `orchestrator-reference.md`; (b) "a `core path: waiting on #N` block keeps holding its scope" is false today: while #N is open it is released as any human block. "Unchanged" governs: this build does not touch it; flagged in the PR body for the human.
- Fail closed: `dispatch_defect_state` exports `DS_NAMED` = 1 / 0 / ? (base or live-branch plan scan unreadable). Only 0 releases; classification (UNPLANNED, RECHECK) keeps reading its own `named`, unchanged.
- Build done inline, not by workers: one function pair and one case arm in one file, the selftest depends on the exact row text.
- Fail-closed test proven: with `[ "$BASE_ISSUES_ERR" -eq 0 ] || unk=1` mutated away, selftest 2026-11-11 read `4302 passed, 2 failed` (the two fail-closed cases); restored, `4304 passed, 0 failed, 1 skipped`.

## Review

- r1: (plan-checker) acceptance ran dispatch-park.sh alone, which cannot run alone (fixed: acceptance runs .agents/harness/selftest.sh)
- r2: (plan-checker) fail-closed trap contradicts reusing plan_names_issue, which fails open (fixed: DS_NAMED with `?` on any failed read; only 0 releases)
- r3: (plan-checker) DEFECT_STATE carries no named bit for PARKED (fixed: plan names DS_NAMED export)
- r4: (plan-checker) row text `waits for <plan>` needs a stem no reader keeps (fixed: generic text, both row texts spelled)
- r5: (plan-checker) hold until RESUME fires is ambiguous (fixed: held through RESUME, as today)
- r6: (plan-checker) fixture acceptance has no command, row text or failure (fixed: selftest cases with exact rows and failures)
- r7: (plan-checker) consumer-side check after sync has no command here (fixed: kept as a runnable command with its output and failure, run by the consumer's sync pull request — ci's ship-scope stage says a SHIPS plan owes one)
- r8: (plan-checker) acceptance lacks failure output and printed results (fixed: `ci: pass`, `0 failed`, failures named)
- r9: (plan-checker) needs: none while starved-counts-green-runs also scopes joharness.sh (wontfix: both mark it shared:, a reconcile merge is the expected path)
- r10: (plan-checker) "only UNREADABLE, STUCK, UNPLANNED join blocked_claims" is true only inside the defect arm (fixed: worded so)
- r11: (plan-checker) Goal's "plan or pull request" and RECHECK left implicit (fixed: git-only reading spelled; RECHECK left out on purpose, said)
- r12: (plan-checker) which of the two PARKED row texts changes is unsaid (fixed: both spelled)
- r13: (plan-checker) round 2: what counts as a failed read (grep exit 1, a missing live plan) undecided (fixed: grep exit above 1 or no base ref; live plan unreadable by cat-file)
- r14: (plan-checker) round 2: acceptance items 3-5 and ci line state no failure (fixed: failures named)
- r15: (plan-checker) round 2: fail-closed fixture recipe unsaid (fixed: a git on PATH exiting 2 on grep)
- r16: (plan-checker) round 2: selftest prints `… 0 failed, N skipped`, not ending `0 failed` (fixed: "prints")
- r17: (plan-checker) round 2: needs: none beside starved-counts-green-runs on joharness.sh (wontfix: as r9, shared: marks the reconcile)
- r18: (plan-checker) round 2: anchor joharness.sh:dispatch names no function (fixed: cmd_dispatch)
- r19: (plan-checker) round 2: gx incidents and requester quote unverifiable here (wontfix: the requester's record, outside this checkout; the code path is verified)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — parked-row `case "$dst"` and `blocked_claims`.
