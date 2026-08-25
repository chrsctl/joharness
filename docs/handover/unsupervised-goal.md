---
workstream: unsupervised-goal
status: in-progress
branch: claude/unsupervised-goal
pr: none
plan: none
session: https://claude.ai/code/session_0126bZYruEVL7vNBLb7RXF4v
agent: opus
updated: 2026-08-25
next: Open PR for the goal bound; implementation is unsupervised-edge-work's, not this branch's
---

## Goal

Requester asked to restrict unsupervised mode once the queue drains: there
have to be guidelines, references, and a final goal that can be reached.
The first draft of the requirement said the opposite — "an empty queue is a
trigger for work, not a stopping point" — which is unbounded, and unbounded
plus full-loop autonomy means invented work merging with nobody reading it.
This branch replaces that with a goal bound and rewrites the plan that
implements it.

## Decisions

- The three things asked for already exist in the graph; none is invented
  here. Final goal = a requirement's `Satisfied when`, which is observable
  and whose file is deleted when its last plan merges. Guidelines = the
  requirement's `Constraints`, already defined as the boundary a
  decomposing session must not cross. References = the `requirement:`
  frontmatter edge plus each plan's `Where to look` anchors. Reusing them
  keeps the rule count flat and adds no state.
- The bound is a goal, not a counter. Unsupervised is live only while a
  requirement is open. This is what answers the runaway risk the three
  declined limits were offered for on 2026-08-24, so those stay declined
  rather than quietly returning.
- Reaching the goal is a terminal ACTION, not a resting state: when every
  `Satisfied when` bullet reads true, the session deletes the requirement
  file instead of generating another plan. Without that, a satisfied
  requirement would keep the fleet live forever on a goal already met.
- The no-goal case must say so out loud. A quiet fallthrough at the edge is
  indistinguishable from a hook that failed, and the session would guess.
- Sessions still may not write requirements. A fleet that writes its own
  finish line has none, and the goal bound would be circular.
- The first draft's wording is quoted in the Constraints where it is
  replaced. A requirement that silently changes meaning between readings is
  the failure the exception-at-the-rule decision already avoided once.

## Rejected

- An iteration or spend cap as the stopping condition. Offered 2026-08-24
  and declined; a counter stops the fleet at an arbitrary point mid-goal,
  while `Satisfied when` stops it at a meaningful one. The goal bound is
  strictly better for the same risk.
- A rubric scoring whether a `Satisfied when` bullet is true. That is a
  second definition of done competing with the requirement's own, and the
  requirement is the human's.
- Letting a session write a requirement when none is open. It converts the
  restriction into a formality.
- Implementing the hook change here. It is `unsupervised-edge-work`'s
  scope, opus/xhigh, and it touches `queue-context.sh` — a file
  `unsupervised-fanout` also wants.

## Review

- r1: the amendment contradicted a bullet already merged in the same file
  ("an empty queue is a trigger for work, not a stopping point"). Left
  standing it would be two rules for one question, and a literal reader
  gets no way to pick. Replaced in place, with the old wording quoted where
  it is superseded and dated. (fixed)
- r2: `Satisfied when` bullets all true, but nobody deletes the file — the
  fleet stays live on a goal already reached. Added the deletion as the
  terminal action in both the requirement and the plan. (fixed)
- r3: docs-only diff, so `verify` is not required
  (`.agents/harness/AGENTS.md` step 7 scopes it to non-`*.md` files under
  four paths). `ci` covers the graph lint, which is what can break here.
  (no change needed)
- r4: scope declared disjoint from `claude/mode-toggle`, which is in
  flight from this same session and touches `joharness.sh`,
  `.agents/harness/selftest.sh` and `.gitignore`. No overlap with this
  branch's two files. (no change needed)

## Blockers

None.

## Where to look

- `docs/product/unsupervised-mode.md` — Satisfied when and Constraints
  carry the bound; the Goal paragraph says why a loop without a stateable
  "done" does not converge.
- `docs/plans/unsupervised-edge-work.md` — the three-way edge, the closed
  source list, and the terminal deletion.
- `.agents/docs/product/README.md` — `Satisfied` = last plan's PR deletes
  the requirement file. The definition this bound leans on.
