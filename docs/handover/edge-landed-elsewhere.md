---
workstream: edge-landed-elsewhere
status: in-progress
branch: edge-landed-elsewhere
pr: none
plan: edge-landed-elsewhere
issue: 594
session: https://claude.ai/code/session_013k9uhKZdpmecdnYEgGw8kZ
agent: opus
updated: 2026-10-24
next: Spawn the verifier at the review tier, record findings, then step 7
---

## Goal

Edge listing (and `dispatch` lead_why) states what git proves: "N commits
after merged PR #n", and "plan gone from main: landed elsewhere? confirm in
merged history, then release" (issue #594).

## Decisions

- A1: confirmed — `handover-context.sh` builds `lead_why="status done and unmerged"` in its second loop.
- A2: confirmed — first-parent `Merge pull request #N from` subjects on this repo's main; read once into `base_merges`, no GitHub call.
- A3: confirmed — `cmd_dispatch` seds the one `FINISH BEFORE STARTING:` line from the hook; it shows only the lead entry, so each fact is asserted on the lead line in the selftest, not via a two-case dispatch fixture.
- Facts computed in `edge_facts`, second loop, ranks 0-2 only (displayed entries; one git process set each). `plan:` rides as a 16th row field after `pushed_rel`, so sort keys are untouched.
- Plan-gone check uses `--full-history -m` like `dispatch_branch_plans` and a `:(literal)` pathspec; it skips only a branch that still CARRIES the plan file atop a delete its merge base already holds (a reused stem). A branch that merged main in no longer carries the file, so it still gets the line.
- `pr_num` reads only `/pull/N` URLs (one trailing slash allowed); other URLs print as before.
- Dispatch's `plans on a branch ... held Nd` line (issue case 2) is in `joharness.sh`, outside scope and shared with `block-names-awaited-pr`: follow-up plan `docs/plans/dispatch-held-merged-pr.md`.

- Measured 2026-10-24: `./joharness.sh ci` on this head = `ci: pass`; same with `handover-context.sh` from origin/main = 6 new cases FAIL; `./joharness.sh verify` = `6 passed, 0 failed`.

## Rejected

- Asserting on `dispatch` with case 1 and case 2 in one fixture: dispatch prints one lead, so case 2 never shows (plan-checker r2).

## Review

- r1: (plan-checker) dispatch's "held" text for case 2 is in joharness.sh, outside scope (fixed: follow-up plan dispatch-held-merged-pr)
- r2: (plan-checker) acceptance 3 cannot pass: dispatch shows one lead entry (fixed: selftest asserts each fact on the lead line; A3 decision)
- r3: (plan-checker) issue case 1 may be a branch-added plan, which prints nothing new (no change: the plan's rule; dispatch already prints DONE ON MAIN for a branch-added plan main retired)
- r4: (plan-checker) acceptance items name no command or failure line (no change: ci and verify counts are the gates; revert run recorded here)
- r5: (plan-checker) plain git log --diff-filter=D lacks --full-history -m and a reused-stem guard (fixed: both, with an lreuse fixture)
- r6: (plan-checker) anchor handover-context.sh:rank names no symbol; README has no status table (no change: plan retires with this PR; README line sits under the in-flight rank table)
- r7: (plan-checker) research and product claims get no plan-gone text (wontfix: plan scopes docs/plans only)
- r8: (plan-checker) tree changed while the plan-checker ran (no change: the checker read HEAD; the verifier runs on a still tree)
- r9: (verifier) merge-base guard hid plan gone on a branch that merged main in (fixed: skip only when the branch still carries the file; lrec fixture)
- r10: (verifier) pr: URL with a trailing slash dropped out of rank 2 (fixed: strip one slash first; lslsh fixture)
- r11: (verifier) --full-history -m untested (fixed: evil-merge fixture levil fails without -m)
- r12: (verifier) status done gate on plan gone untested (fixed: lrevw review fixture)
- r13: (verifier) most new refutes pass without the change (no change: each new expect fails without its code, mutation-checked; refutes guard over-reporting)
- r14: (verifier) plan names are pathspec globs (fixed: :(literal) pathspec)
- r15: (verifier) pr_num read issue URLs as pull requests (fixed: only /pull/N)
- r16: (verifier) follow-up plan's consumer-side acceptance cannot run in its own branch (wontfix: ci ship-scope asks a shipping plan to name the consumer check)

## Blockers

None.

## Where to look

- `.agents/harness/handover-context.sh:rank` — EDGE and lead_why lines.
