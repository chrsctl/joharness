---
workstream: drain-loop
status: in-progress
branch: claude/drain-loop
pr: none
plan: drain-loop
issue: none
session: https://claude.ai/code/session_01Vaf3LtqeZuPLpVyeSRpngQ
agent: opus
updated: 2026-10-07
next: Verifier on the conf-only diff, then retire commit + PR + merge (step 7)
---

## Goal

Human: "Add an infinity loop to drain … like the normal loop just with
parallelity 1 … still cheap orchestrator." Chosen route: orchestrated mode at
`JOHARNESS_MAX_MANAGERS=1` in `joharness.conf`.

## Decisions

- Config, not code: `/orchestrate` at cap 1 IS the cheap one-at-a-time loop.
  Human picked it over making `/drain` a cap-1 orchestrator (would relax the
  authority bound) and over an inline loop.
- Cost named, not hidden: under orchestrated, plans whose scope holds
  protocol text are SUPERVISED ONLY — 3 of 4 queued plans today
  (`dispatch`, 2026-10-07). Reverting = flip the mode back by PR.

## Rejected

- Inline `/drain` loop (c03ac7f, reverted): human wanted a cheap orchestrator
  spawning managers, not one session doing every item; verifier also found
  it contradicted curate/janitor exit rules, the unsupervised spawn line and
  the tier rule.
- Heartbeat Routine — spend is the human's; not what was asked.

## Review

- r1: (verifier) inline loop: drain.md "spawn nothing" contradicts `drain`'s unsupervised spawn line, queue-context.sh and unsupervised.md (wontfix — inline design reverted)
- r2: (verifier) curate.md "one pass, exit" contradicts the loop (wontfix — reverted)
- r3: (verifier) janitor.md exits, ending the loop with the queue full (wontfix — reverted)
- r4: (verifier) stop-on-blocked rationale false: blocked without pr is not edge work (wontfix — reverted)
- r5: (verifier) tier stop jams the queue on one high-tier plan (wontfix — reverted)
- r6: (verifier) no spend bound unattended; heartbeat overlap raises parallelism (wontfix — reverted; orchestrated cap is the bound now)
- r7: (verifier) /drain in an orchestrated repo bypasses the cap (wontfix — reverted)
- r8: (verifier) bootstrap-consumer.sh still states one item per session (wontfix — reverted, text true again)
- r9: (verifier) c03ac7f landed without its workstream-file update (fixed — this commit carries both)
- r10: (verifier) AGENTS.md silent for sessions not started via /drain (wontfix — reverted)
- r11: (verifier) drain.md step 6 has no not-merged-but-done route (wontfix — reverted)

## Blockers

None.

## Where to look

- `.claude/commands/drain.md` — the command.
