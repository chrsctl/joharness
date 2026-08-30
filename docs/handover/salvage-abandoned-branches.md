---
workstream: salvage-abandoned-branches
status: review
branch: claude/salvage-abandoned-branches
pr: none
plan: docs/plans/salvage-abandoned-branches.md
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-30
next: Retire this file and the plan, open the pull request, merge.
---

## Goal

Four unmerged branches carry workstream files with recorded findings and no
session that will act on them. Extract what is still true against today's
`main` before anyone deletes them.

## Method

Ownership by DIFF against the merge base, never a tree read — a branch
inherits every file its base carries (`.agents/docs/feedback.md`, "tree or
diff"). `git diff --name-only --diff-filter=A "$(git merge-base origin/main
$ref)" "$ref" -- docs/handover/...` per ref, read with `git show`, no
checkout. Liveness from the control plane, not from push time.

## Verdicts

All four sessions are dead — checked 2026-08-30 via `get_session`. None is
`RUNNING`, so no branch here is taken.

**1. `origin/claude/multi-agent-orchestration-pr-jyli0w`** —
`docs/handover/pm-dispatch.md`, session `019M7ypRKWMGi2oaM3XEmGcC` IDLE and
disconnected. Its pull request 10 was **closed unmerged on 2026-08-21**
(`closed_at` 2026-08-21T20:19:09Z). 679 behind `main`.

- **SALVAGED** → `docs/plans/dispatch-name-the-plan.md`. The dispatch gap:
  a claim exists only after the spawned session's first push, so a
  controller spawning in parallel must name each plan in its prompt. Written
  down nowhere — `grep -rn "NAME the plan\|spawn prompt\|self-selection"
  .agents/docs/` returns nothing, 2026-08-30. Independently re-derived since:
  the fan-out live run bound each spawned session to one named plan for this
  exact reason.
- **NOT APPLICABLE HERE** — the file's own `## Salvage` section carries three
  findings from branches a human deleted on 2026-08-21: k3s v1.36.3 cgroup v1
  behaviour, helm v3.21.4 smoke coverage, and a pre-split harness-sync path
  list. The first two are a CONSUMER repo's environment work; filing them as
  joharness plans would put work in a queue this repo cannot run. They are
  named here with provenance so they can be carried to the right repo, and
  they stay recoverable from the branch until it is deleted.
- The third — "harness-owned path list was drafted pre-split, needs redo
  against env/-split paths" — is superseded: `joharness.sh protocol_paths`
  is that list, and `handover-guard.sh` reads it.

**2. `origin/claude/unsupervised-goal`** —
`docs/handover/unsupervised-goal.md`, session `0126bZYruEVL7vNBLb7RXF4v`
**ARCHIVED**. Four findings recorded, `status: in-progress`.

- **STILL APPLICABLE, AND NOT A SESSION'S TO SALVAGE.** The branch amends
  `docs/product/unsupervised-mode.md` to replace "an empty queue is a
  trigger for work, not a stopping point" with a goal bound: unsupervised is
  live only while a requirement is open, and reaching `Satisfied when` is a
  terminal action that deletes the requirement file. That wording is **still
  on `main`, line 33**, unchanged — so this work never landed.
- Not re-filed as a plan or a research node, deliberately. It is a
  requirement amendment, and a requirement is the human's: the branch's own
  reasoning says "sessions still may not write requirements. A fleet that
  writes its own finish line has none." Filing it would be a session doing
  the one thing the amendment forbids.
- **FLAGGED FOR THE HUMAN**: this branch holds unmerged, still-applicable
  work on the requirement that is currently the top of the queue. Merge it,
  or discard it and decide the bound directly — but do not delete the branch
  without reading it. `git show origin/claude/unsupervised-goal:docs/handover/unsupervised-goal.md`

**3. `origin/claude/guard-docs-only-branch`** —
`docs/handover/guard-docs-only-branch.md`, session `019c3kktaEvDBAnDv1K2i65p`
IDLE, and its primary repo was `chrsctl/redocted`; this branch is orphaned.

- **SUPERSEDED, and `main` took the OPPOSITE decision with a measured
  reason.** The branch chose "root-level `*.md` is documentation, excluded
  from the guard's code filter". `main`'s guard now counts everything
  outside `docs/{handover,plans,product}/`, documentation included, and says
  why in the code: the old narrower wording "cost a real session two stops:
  it read 'code', saw its own diff was two `.md` files, concluded the guard
  had misfired, and stopped through a claim it genuinely owed" — and "the
  narrower rule the old comment described would have excused exactly the case
  that went wrong."
- Nothing filed. Recorded here so the answer is not re-opened: it was
  considered and rejected on evidence, not overlooked.

**4. `origin/claude/backpass-usage-review-sbew6t`** —
`docs/handover/unsupervised-boundary.md`, session `01UcW18iV8drNpkz9rpCT27B`
IDLE and disconnected. Eight verifier findings.

- **SUPERSEDED.** It was fixing issue #114 (an unsupervised session can
  delete its own reviewer). #114 is **closed as completed**, by merged pull
  request #118, on 2026-08-29. `main` carries `joharness.sh protocol_paths`
  as the single list, and `handover-guard.sh` reads it.
- **SALVAGED** → `docs/plans/guard-vacuous-assertions.md`. Finding `v3` is
  not about the boundary at all: three new assertions greped the whole
  `session-start` output, which echoes workstream `next:` lines and plan
  `scope:` paths, so any repo-controlled text satisfied them. Proven there by
  planting a decoy. That is a CLASS, and it recurred independently in PR 151
  two days later — a `refute` whose needle can never be produced. Two
  instances, both caught by a person deciding to check, neither by anything
  mechanical.

## Decisions

- **Two plans filed, two branches yielding none.** The plan's Out of scope
  is explicit that a plan for work already done is worse than no plan, so
  every finding was checked against today's tree before filing. Two of the
  four branches were entirely superseded.
- **The unsupervised-goal work is flagged, not re-filed.** See verdict 2.
- **No branch touched.** No merge, no push, no delete. `git show` only.

## Rejected

- Filing the k3s and helm findings as joharness plans. They are a consumer
  repo's environment work; a plan this repo cannot execute is queue noise.
- Graduating the vacuous-assertion class straight into
  `.agents/docs/feedback.md`. Two instances is a class, but the salvage
  plan's Scope says plan or research node, and the useful output here is a
  DETECTOR rather than a paragraph. The plan can graduate it when it lands.

## Review

Round 1, opus, self.

- r1: the first pass read `git ls-tree` to find each branch's workstream
  files, which is the tree read `.agents/docs/feedback.md` graduated a rule
  against — six merged edges paid for it. A branch inherits every file its
  base carries, so that would have attributed other sessions' files to these
  branches. (fixed — `git diff --diff-filter=A` against each merge base
  before anything was read)
- r2: "still applicable" was nearly asserted for `unsupervised-goal` from
  its own text. Checked against `main` instead: line 33 still carries the
  wording it replaces, which is what makes it applicable. (fixed — the
  verdict cites the line, not the branch's claim about it)
- r3: `backpass-usage-review` reads urgent and is entirely done. Nearly
  filed its boundary findings as new work. Checked issue #114: closed as
  completed by merged PR 118. (fixed — verdict is SUPERSEDED, and only the
  class finding survived)
- r4: verifier round owed and NOT run — standing instruction, same as the
  last several edges.

## Blockers

Human decision on `origin/claude/unsupervised-goal` (verdict 2) before that
branch is deleted. Not blocking this merge.
