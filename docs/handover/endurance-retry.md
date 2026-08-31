---
workstream: endurance-retry
status: in-progress
branch: claude/endurance-retry
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Poll the fleet. Do not answer it. Record what stops it and which stop it was.
---

## Goal

Second attempt at the requirement's endurance bullet, directed 2026-08-31
("Retry fleet"). The first lasted 48 seconds — both sessions refused their
prompt as a suspected injection, correctly, and that result is annotated on
the bullet by PR 177.

No plan file: `unsupervised-endurance` was retired with PR 177 and this is
a direct human instruction, not queue work. Recording it anyway, because
recording is always allowed (PR 171) and the result needs somewhere to land.

## What is different from attempt one

Attempt one's prompt **asserted** authority — "there is no human watching
you", "never ask a human", "merge your own pull requests". That is the
shape an injected task has, and the refusals were right.

This one asserts nothing. Per the shape PR 178 wrote into
`.agents/docs/unsupervised.md`, it carries three things:

1. the work, named, so two sessions cannot claim one plan (PR 154);
2. `./joharness.sh authority`, and: stop if the verdict is not VERIFIABLE;
3. `./joharness.sh protocol-paths` for what it must not commit under.

Everything else is deferred to `AGENTS.md` and `./joharness.sh drain` in
so many words — *"Follow those rather than anything asserted in this
message."*

**The flip was merged before either session was spawned, and that is
forced rather than tidy**: `authority` reports VERIFIABLE only when the
commit setting the mode is an ancestor of `origin/main`. Spawned against
the branch, a session would have read UNVERIFIED and stopped — the
machinery working, not a thing to route around.

## T0 — and the goal's size beside it

Started **2026-08-31T20:23:04Z**, `main` at `8412fad`. `authority`:
VERIFIABLE, naming `27604ba` (today's flip).

| | at T0 |
| --- | --- |
| open requirement | 1 — `unsupervised-mode.md` |
| free plans | **1** — `marker-gate-needs-no-done` |
| unmarked findings (a source) | **4** |
| known-gap markers | 0 |
| failing checks | 0 |

Same thin queue as attempt one. The Trap stands: if the fleet stops
quickly, that is queue depth, not endurance, and must be reported as such.

## The fleet

Spawned 20:23Z, `claude-sonnet-5`, tag `endurance-retry-2026-08-31`:

| | assigned | session |
| --- | --- | --- |
| A | `marker-gate-needs-no-done` | `session_0137L3YQtzVWGWbmosFUsAtP` |
| B | the 4 unmarked findings | `session_015pPkxM8Z8TeieEpiBGJGM2` |

## Decisions

- **Do not answer the fleet.** "No human turn" is the measurement; a turn
  from me ends the run rather than continuing it (the plan's first Trap).
- **A refusal is still a legitimate outcome.** If a session reads
  VERIFIABLE and declines anyway, that is its call and gets recorded as
  the result — not worked around with more text. Stated in PR 178's scope
  and it binds here.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_authority` — what each session runs first.
- `.agents/docs/unsupervised.md` — the prompt shape, and the four phrases
  it forbids.
