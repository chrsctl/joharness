---
workstream: requirement-row-claim
status: in-progress
branch: requirement-row-claim
pr: none
plan: requirement-row-claim
issue: none
session: https://claude.ai/code/session_01KGbgAo5HRoJy1hGBGbRy34
agent: opus
updated: 2026-10-10
next: Verifier confirm on r10, then retire + PR
---

## Goal

A pushed workstream file whose `plan:` names a requirement stem must be a
claim on that requirement — in-flight row, slot counted, not offered
UNPLANNED, blocked = held not respawned.

## Decisions

- Claimed requirement stays printed under "Requirements without plans" with
  `claimed on <branch>` (ranked after unclaimed) — dispatch's in-flight walk
  builds rows from that label; `drain_requirement` skips claimed lines and
  the free walk skips every `docs/product/` row (unclaimed ones are offered
  by `drain_requirement` alone).
- Plan/research stem wins over a requirement stem in queue-context too, not
  only in joharness.sh's `for cand` loops: one resolution order everywhere.
- Requirement items in `dispatch_retired_edges` are named but never asked:
  presence on the base proves nothing for a file that outlives its
  planning merge, so `unknown` (24-window ageing) is the only honest state.
- `manage.md` untouched: its "`plan:` names the item" already says it.

## Rejected

- None yet.

## Review

- r1: revert test — `git checkout origin/main -- joharness.sh .agents/harness/queue-context.sh` in a worktree, `bash .agents/harness/selftest.sh` → 2458 passed, 7 failed (the five claim cases, the lint claim case, the reworded dead-claim message); restored → 2465 passed, 0 failed. Tests pin the fix. (no change)
- r2: (verifier) planning branch past its retire commit vanishes: workstream born+retired nets to absent, a planning pass deletes no plan, so `dispatch_retired_edges` skips it and the requirement is offered UNPLANNED to a second planner for the whole PR window. (fixed — `dispatch_retired_edges` reads the requirement off the plans the branch ADDS; `drain_requirement` withholds edge items; selftest case, fails on round-1 code)
- r3: (verifier) `docs/product` candidate in `dispatch_retired_edges` makes a sweep of an inherited planning record `mid-merge` for as long as the branch stands — a requirement stays on main past its planning merge, so the leftover test never fires; same pass still offers the requirement. (fixed — a `docs/product` item is never asked: state `unknown`, holds while young, leftover past 24 windows; selftest cases fresh + 30h, fail on round-1 code)
- r4: (verifier) queue-context gates (`plan the requirements above`, `Plus one planning session`, Edge reached, open-question exit) read `$unplanned` non-empty even when every requirement in it is claimed — non-orchestrated session still sent to plan it. (fixed — gates read `unplanned_free`, claimed lines dropped; selftest reads the hook directly, fails on round-1 code)
- r5: (verifier) free-walk `docs/product/*` skip pinned by no test: removed, unclaimed requirement offered twice, selftest still 2465/0. (fixed — refute the `(agent:` row + pin `1 free item(s) now`; skip deleted → 2 of them FAIL)
- r6: (verifier) raw `priority:` in the requirement label can forge `claimed on <branch>` and a fake in-flight row; lint gates main only. (fixed — `rprio` validated to normal|urgent; selftest case, validation deleted → 2 FAIL)
- r7: (verifier) `cmd_janitor` comment still says "two-candidate loop". (fixed)
- r8: (verifier, round 2) r2's added-plans scan makes a clerk's open PR — or any plan-only branch with no workstream file whose plans name a base requirement — hold a slot under a `req` title no live session carries, so the health table reads it gone and respawns onto a live branch. (fixed — the scan reads the branch's OWN retired workstream file instead: born and deleted on the branch, so absent from base..tip but present in `git log --diff-filter=D base..tip`; only `plan: <requirement>` there names an item. Clerk `plan: none` → no row, as on base; selftest case)
- r9: (verifier, round 2) a planning PR left open past 24 stall windows ages to leftover and its requirement is offered again. (wontfix — the documented trade, same ageing as every unaskable edge; README says it)
- r10: (verifier, round 3) r8's `git log` simplifies away the retire commit once the planning branch merges `main` (step 7 reconcile) after `main`'s `docs/handover` changed: merge TREESAME to its 2nd parent, branch history pruned, row gone, requirement offered again. (fixed — `--first-parent`, the verifier's `--full-history` dropped as redundant: `bash .agents/harness/selftest.sh` 2026-10-10 — no flag: reconcile case FAILS (2482/3); `--full-history` alone: merged-in case FAILS (2483/2); `--first-parent` alone: 2485/0. Selftest cases reconcile + merged-in branch. A branch FAST-FORWARDED onto an unmerged planning branch shares its first-parent line and reads as that planner continued — a stacked branch, accepted)

## Blockers

None. `./joharness.sh verify` local run 2026-10-10: 2 passed, 4 failed —
every fail a docker registry/egress check; `docker pull alpine:3` returns
`429 Too Many Requests` from registry-1.docker.io. Diff touches no
`.agents/env/` file; step 7 needs the PR head's CI verify job read instead.

## Where to look

- `docs/plans/requirement-row-claim.md` — Scope lists every site.
