---
workstream: loop-autonomy-review
status: done
branch: claude/loop-autonomy-review-toxvcw
pr: none
plan: none
session: https://claude.ai/code/session_01QTY9NV95DPMn45ngwfaJvJ
agent: opus
updated: 2026-08-27
next: Retire this file (last commit before PR); loop continues in-session, new findings start a fresh workstream
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
- Graduation (requester asked for a PR): f1/f2/f3 — the actionable,
  rule-shaped findings — become `docs/plans/fork-seam-rules.md`, same
  species as `harness-rules-field-review` (field evidence → rule-text
  edits). f4 is a status observation, f6 self-resolves with research-node,
  f5 stays a candidate research node once that shape exists; history keeps
  all three (retrieval command in the PR body).
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

Edge review of this branch's diff (one plan file + this record), separate
lenses: scope-conflict, evidence, doctrine-conformance.

- r1: first draft of the plan strengthened the `finish`/`ci` gate to
  detect human-merge PRs — mechanism, touches `joharness.sh`, undeclared
  conflict with `ci-scope-selftest`'s wave (fixed: scope cut to rule text
  only; gate change named in Out of scope as its own plan)
- r2: `needs: harness-rules-field-review` considered because both plans
  edit step 7 — fake edge, this plan reads no result of that one; the
  README says leave it out and declare the file conflict via `scope`
  (fixed: scope declared, wave conflict named in Traps)
- r3: every number in the plan re-counted this session — finish printed
  "1 already on origin/main", list_pull_requests returned 2 open fork
  PRs, #79 merged_at vs session start = ~21h — none written from memory
  (no change needed)
- r4: plan's edit 2 risked a second flag mechanism beside Decide alone's
  "flag for human" — reworded to point at the existing rule (fixed)

## Blockers

None.

## Where to look

- `docs/product/unsupervised-mode.md` — goal bound + the three declined
  caps; the autonomy contract every finding is judged against.
- `docs/product/research-capability.md` — why these findings need a
  durable home; f6.
- PR #81, #82 (fork: DaniloNaujoksi/joharness) — the live instances of
  f1/f2/f4.
