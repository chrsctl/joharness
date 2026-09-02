---
workstream: decompose-unsupervised-mode
status: in-progress
branch: claude/current-state-review-oxfb7f
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_011LSGxqQsZyuMYSqxa3jVT5
agent: opus
updated: 2026-09-02
next: File the endurance plan and correct the misplaced fan-out annotation
---

## Goal

`docs/product/unsupervised-mode.md` has no open plan serving it, so the queue
ranks it above everything: planning outranks executing, and a requirement
nobody has decomposed is the top of the queue. Check every `Satisfied when`
bullet against the tree, and file plans for what is actually left — no more.

Decomposition is the work. This is the one kind of work that starts without a
plan of its own.

## Decisions

- **Checked, not assumed.** Every bullet was read against the code that would
  make it true, not against the annotation beside it. That is what turned up
  the misplaced annotation below.
- **One plan comes out of this, not four.** Eleven of the thirteen bullets
  are done and tested. Filing more would be inventing work.

## Rejected

- **A plan for the `advances:` gap.** `lint_plan_advances` skips any plan
  whose `requirement:` is `none`, so a plan generated while a goal is open
  can name no bullet and still lint green — which looks like a hole in the
  bullet that requires one. It is not a defect: recording is always allowed
  and a recorded plan legitimately serves no requirement, so the check would
  have to tell recording from generating, which is a fact about the
  session's state and not about the file. The code already says this in the
  comment above the function. Left alone.
- **A plan for delete-on-satisfied.** The terminus is written where sessions
  read it (`.agents/docs/product/README.md`: satisfied = the last plan's
  pull request deletes the requirement file) and the machinery downstream of
  it is tested — `drain` prints GOAL REACHED on zero open requirements, with
  cases. What is missing is an exercise of it, and that arrives when this
  requirement is finished rather than as work of its own.

## Review

Pending.

## Blockers

None for the decomposition. The plan it files is gated on a human: spawning
sessions spends money, and the heartbeat that would keep a fleet alive across
generations is an operator action.

## Where to look

- `docs/product/unsupervised-mode.md` — `## Satisfied when`, thirteen
  bullets.
- `.agents/docs/unsupervised.md` — the heartbeat, and why the fleet is short
  without one.
