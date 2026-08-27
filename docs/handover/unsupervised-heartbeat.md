---
workstream: unsupervised-heartbeat
status: in-progress
branch: claude/loop-research-plan-execute-o35t4g
pr: none
plan: unsupervised-heartbeat
session: https://claude.ai/code/session_01AE7grFXQWrQ3Qyr1n522Uf
agent: opus
updated: 2026-08-27
next: Write .agents/docs/unsupervised.md, then prove the operator procedure on the throwaway Routine
---

## Goal

Fan-out makes the unsupervised fleet wide; nothing makes it long. Ship
`.agents/docs/unsupervised.md`: which scheduling mechanism gives the fleet
a restart that outlives any one session, why the other four lose, and the
operator procedure for create, inspect, pause, delete. Document the
mechanism; do not create the operator's Routine — that spends money.

## Decisions

- Heartbeat doc does NOT restate the edge rule (what a firing does when the
  queue is empty). It names the queue as the authority and points at the
  requirement plus `unsupervised-edge-work`. Reason: that rule is being
  rewritten right now on `origin/claude/unsupervised-goal` (sweep-dry
  becomes goal-bound). A copy here would be the second copy the graph
  rules forbid, and would land already contradicting an unmerged branch.
  Consistent with edge behaviour under BOTH readings, which is what the
  plan's acceptance asks for.
- Throwaway Routine for the acceptance run is created PAUSED-then-deleted
  with a no-op prompt, and its one-shot time is set close enough that the
  build window itself proves it did not fire. Never firing = no spend, so
  the money rule is not touched.

## Rejected

- Taking the queue's top plan (`k8s-136-validation`, sonnet). This session
  is opus; running sonnet-tier work here is an escalation the rules allow
  but the requester's "optimal models" ask argues against. Took the oldest
  free opus-tier plan instead.
- Documenting `CronCreate` as the mechanism: its own schema says jobs are
  in-memory, `durable` has no effect, and they die when the session exits.
  Disqualified by the one question the plan says separates the five.

## Review

- r1: pending

## Blockers

None.

## Where to look

- `docs/plans/unsupervised-heartbeat.md` — the plan; acceptance requires a
  proved stop procedure, not an asserted one.
- `.github/workflows/update.yml:15` — the "pull request it opens gets NO ci
  runs" comment; the evidence that rejects the Actions route.
