---
workstream: loop-autonomy-review
status: in-progress
branch: claude/loop-autonomy-review-toxvcw
pr: none
plan: none
session: https://claude.ai/code/session_01QTY9NV95DPMn45ngwfaJvJ
agent: opus
updated: 2026-08-27
next: Next tick: diff repo state against Findings; go deeper on whatever moved (PRs 81/82, queue, unsupervised branches)
---

## Goal

Requester started a self-paced loop: "Review for autonomy. Research." Each
tick reviews live repo state (PRs, queue, in-flight branches, harness
rules) through the autonomy lens and records what it finds. Research only —
no implementation from this branch. Findings that would evaporate with the
chat land here; this file is the loop's memory between ticks and sessions.

## Decisions

- Findings live in this workstream file, not a research node: the
  research-node shape does not exist until `docs/plans/research-node.md`
  merges. Revisit routing findings there once it does.
- No PR subscription on #81/#82: they are fork PRs this session may not
  drive (own-PR rule); the loop polls state instead of taking watch-posture
  obligations it cannot discharge.

## Rejected

- Treating the hook's handover state as current: it told this session to
  wait on PR 79 first-fork approval — resolved a day before session start.
  Fetch GitHub state every tick; push-time is not liveness (Finding f3).

## Findings

Tick 1, 2026-08-27. Counted from live GitHub state and tree at
764bb19 (origin/main).

- f1: Fork topology breaks step 7 self-merge — observed on PR #79: fork
  session needed human approval for first-fork workflow runs AND human
  merge (chrsctl merged 2026-08-26). Finish ritual broke at that seam:
  workstream file left stale on main, `cleanup` counts 1 removable.
- f2: Fork PRs have no steward by construction: #81 (the fork session's
  own repair of f1's damage: cleanup --apply + audit of #79's guard) is
  open, green, mergeable — base-repo sessions may not drive another
  session's PR, fork session cannot merge. Structural gap: fork PRs are
  human-gated at CI approval and merge, with nobody assigned to notice.
- f3: Handover staleness crosses the fork boundary: base repo's hook can
  never see a fork session's later state. Known rule ("push time not
  liveness") but the fork case has no /who to consult either.
- f4: Endurance chain designed, unbuilt: unsupervised-edge-work →
  mode-toggle (in flight, claude/unsupervised-goal) → unsupervised-heartbeat
  (free, wave 1) → unsupervised-fanout (blocked). Two deliberate human
  ignition points remain even when built: Routine creation (spend) and
  requirement writing (direction). PR #82 is the second gate working as
  designed — a correct stall, not a bug.
- f5: Fan-out width bottlenecked by two monolith files: 10 of 15 free
  plans serialize behind ci-scope-selftest on `joharness.sh` /
  `.agents/harness/selftest.sh` (queue wave listing, session start
  2026-08-27). Effective parallel width = 3 (wave 1). Splitting the
  monoliths is the highest-leverage throughput change; candidate research
  node once that shape exists.
- f6: This loop is itself the gap research-capability measures — findings
  with no in-graph home until research-node merges; this file is the
  stopgap.

## Review

No code on this branch to review; findings above are the deliverable.
Clean pass not applicable yet.

## Blockers

None.

## Where to look

- `docs/product/unsupervised-mode.md` — goal bound + the three declined
  caps; the autonomy contract every finding is judged against.
- `docs/product/research-capability.md` — why these findings need a
  durable home; f6.
- PR #81, #82 (fork: DaniloNaujoksi/joharness) — the live instances of
  f1/f2/f4.
