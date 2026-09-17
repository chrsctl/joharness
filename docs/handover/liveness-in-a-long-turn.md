---
workstream: liveness-in-a-long-turn
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: liveness-in-a-long-turn
issue: none
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: opus
updated: 2026-09-17
next: Record the verifier's verdict, then retire the research file and the workstream file and open the pull request
---

## Goal

`docs/research/liveness-in-a-long-turn.md`. Does a session's `updated_at`
advance while it sits inside ONE long turn, or only when a turn ends? The
health pass decides kill, nudge and respawn from `updated_at` plus the
branch head, and two rules drafted for issue #249 assumed OPPOSITE answers
in the same diff. Four rules were withdrawn pending this. A wrong answer
destroys work in progress and spends the concurrency cap twice.

## Decisions

- The corpus is the live orchestrated fleet, sampled read-only from here
  with `get_session`. The node's Method asks for a session whose turn length
  is known independently and a sampler that is not the session itself; both
  hold, and it costs nothing, where spawning a session to observe would be
  money for a reading already available.
- The independent discriminator is `post_turn_summary`, not my judgement of
  what a manager is doing. It is written when a turn ENDS, so `updated_at`
  moving while `post_turn_summary` is byte-identical means no turn boundary
  fell between the samples. That closes the confound the node does not name:
  many short turns look like one long turn if you only watch `updated_at`.

## Rejected

- Spawning a session with a deliberately long task, which is what the node's
  Method sketches. It is the cleaner experiment and it costs the human money
  for an observation the running fleet already offers. Recorded rather than
  silently skipped: if the fleet reading comes back ambiguous, that spawn is
  the next step and it is an operator decision.
- `docs/plans/orchestrated-run.md`, the queue's first item. Blocked on the
  human's heartbeat and on run 3 having stopped.
- The edge branch naming pull request #10. Re-read from GitHub this session:
  `state: closed`, `merged: false`, closed 2026-08-21.

## Review

Findings land here as the second context returns them. The measurement,
its two confounds and their controls are in the research file's `## Findings`
and `## Verification`, which is where a reader of the answer looks — not
duplicated here.

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md`, the evidence table and the health rows
  — where the answer graduates, and where a wrong one costs money.
- `docs/research/liveness-in-a-long-turn.md` — the question, and what it
  says would settle it either way.
