---
research: cost-per-merge-levers
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/agent-selection.md
---

## Question

Does any of four named levers cut cost per merged edge by at least 20%
without raising respawns, kills or reverted merges in the same fleet?

## Echo

Run 3 paid ~128 USD per merged edge (`.agents/docs/orchestrated.md` Runs),
managers 93% of it. `.agents/docs/agent-selection.md` Cost levers names
what is free; these four trade something, so each needs a number before a
human picks it — a tier or effort cut is money, humans only. The levers:

1. **Fresh session for long waits.** A manager waiting on CI or review
   past the cache TTL ends after its handover; a fresh session resumes
   from the workstream file instead of waking the fat context.
2. **Fable planning manager at `high`**, not `xhigh`
   (`.claude/commands/orchestrate.md`, UNPLANNED spawn).
3. **Sonnet verifier on opus plans.** Independence, not depth, is what the
   review-depth rule says was missing; the verifier runs at plan tier today.
4. **Haiku 5.5 worker share.** Fraction of manager sub-tasks sent to haiku
   workers, before and after the Lineup move to 5.5.

## Sweep

`goal-directed` — enough runs per lever to compare cost per merge and the
failure counts against a baseline from the same consumer and queue shape.
Not every possible lever.

## What would settle it

Per lever: cost per merged edge (sum of `get_session` `usage.cost_usd` over
the fleet, divided by merges) and respawns + kills + reverts, baseline vs
trial, over at least 10 merged edges each. YES for a lever = cost down
≥20% AND failure count not up. NO = either fails. All four NO closes the
question NO.

## Method

Not run yet. Planned, per lever, in one consumer:

- Baseline: the last 10 merged edges before the trial. Cost =
  `get_session` `usage.cost_usd` summed over the orchestrator and every
  session whose `parent_session_id` is it (`list_sessions`); merges =
  `search_pull_requests` `is:merged` in the window; respawns and kills =
  the orchestrator's ledger; reverts = `git log --grep '^Revert'` on main.
- Trial: the lever switched on by a human for the next 10 merged edges,
  same reads.
- Lever 4 only: worker tiers counted from each manager's `Agent` calls
  (`list_events`, `kinds: ["assistant"]`).

Second context for the control-plane readings, named up front
(`.agents/docs/research/README.md`): a session other than the one running
the fleet re-reads `get_session` for the same session ids.

## Findings

None yet.

## Consequence for the queue

A YES becomes a plan a human authorises (tier or effort change = money).
Lever 1 touches `.claude/commands/manage.md` and the orchestrator's health
table — protocol paths, CORE ONLY.

## Verification

None yet.

## Graduates to

`.agents/docs/agent-selection.md` Cost levers — where a session choosing a
tier or a wait already reads.
