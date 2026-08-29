---
workstream: unsupervised-edge-work
status: in-progress
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: unsupervised-edge-work
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Add selftest fixtures for both edge paths in both modes, then review.
---

## Goal

`docs/plans/unsupervised-edge-work.md`. Under supervised the queue edge is
where a session stops and asks. Under unsupervised it is where work begins:
research the repo against a CLOSED source list, write plan files, open a
pull request. Unless the sweep is dry, which is where the mode stops.

## Decisions

- Claimed at the plan's own tier (opus). No escalation needed.
- Checked every remote branch for a competing claim before cutting. Free.

- The hook NAMES the sweep; it does not run it. The plan says the edge
  prints the terminal line "UNLESS the sweep is dry", which requires the
  hook to know. Knowing means running `./joharness.sh sources`, measured
  2026-08-29 at **78s against session-start's 3s** — 26x, at every session
  start, and it runs `ci` so the 700-fork budget goes with it. The plan's
  own Traps say hook output is paid every session, and this hook already
  makes GitHub a pointer for the same reason. Deviation from the plan's
  letter, recorded rather than quietly taken.

## Rejected

- Verifying "supervised is byte-identical" on this repo alone. The diff came
  back IDENTICAL while the code was fatally broken: `qc_mode` was used at
  the no-plans edge and defined 40 lines below it, so under `set -u` the
  hook died — but this repo HAS plans, so that branch is never reached and
  the comparison never executed the changed line. A fixture with no plans
  found it in one run. A passing check on a state that cannot reach the
  change is worse than no check.

## Review

Not yet run: no edge, no pull request open.

## Blockers

None. `needs: unsupervised-sources` cleared when #120 merged and deleted
that plan file — file existence IS the edge, so the block is gone.

## Where to look

- `.agents/harness/queue-context.sh` — the two edge paths and the no-plans
  branch whose unplanned-requirements arm must keep winning.
- `joharness.sh:cmd_sources` — the sweep this reads, shipped in #120.
