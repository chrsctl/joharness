---
workstream: unsupervised-heartbeat
status: review
branch: claude/loop-research-plan-execute-o35t4g
pr: none
plan: unsupervised-heartbeat
session: https://claude.ai/code/session_01AE7grFXQWrQ3Qyr1n522Uf
agent: opus
updated: 2026-08-27
next: Retire this file and the plan, open PR, merge under step 7
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

Adversarial, opus depth, separate lenses (claim-correctness, reproduce,
literal-reader harm).

- r1: claim-correctness — table called `send_later` non-surviving. Wrong on
  the letter: it stores a self-bind Routine and its delivery survives
  container restarts. Real disqualifier is width, not survival. Sloppiness
  here undercuts the doc's own thesis, since survival IS the separating
  question. (fixed)
- r2: literal-reader harm — Operator procedure reads as runnable
  instructions, and a session landing on that heading never sees the
  preamble's "does NOT create the Routine". Restated the boundary at the
  heading; auto-clarity beats state-each-fact-once for a spend action.
  (fixed)
- r3: reproduce — cadence claimed the hourly floor by quoting the tool
  description. Replaced with the measured refusal of `*/5 * * * *` and its
  exact error, per trust-counted-not-written. (fixed)
- r4: reproduce — doc asserts the procedure ran end to end and that the
  paused Routine did not fire. Both must be observed before merge, not
  asserted; delete step and the post-deadline no-run check were still
  outstanding when written. (fixed: both run, outputs below)
- r5: claim-correctness — `queue-context.sh` written unqualified, the one
  path in the file that would not resolve from repo root. Qualified to
  `.agents/harness/queue-context.sh`. Anchors are checked path-only, so an
  unqualified one rots silently. (fixed)

## Blockers

None.

## Where to look

- `docs/plans/unsupervised-heartbeat.md` — the plan; acceptance requires a
  proved stop procedure, not an asserted one.
- `.github/workflows/update.yml:15` — the "pull request it opens gets NO ci
  runs" comment; the evidence that rejects the Actions route.
