---
plan: unsupervised-stop-condition
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: unsupervised-mode
scope: shared:joharness.sh, .agents/harness/selftest/sources.sh
---

## Goal

The mode's whole termination argument rests on a stop condition that no
command states. The requirement says it in four parts:

> Every detector zero on two consecutive sweeps, queue empty, no open pull
> request.

`./joharness.sh sources` reports **one** of those four. Measured on `main`
at `aab2fa4`, 2026-08-31:

```
sweep NOT dry — checks(0 failing, 1 skipped) findings(151 unmarked)
```

That is one sweep's detector counts and nothing else. "Two consecutive",
"queue empty" and "no open pull request" are left to the session to
assemble by hand — and this is the one place the mode is allowed to stop, so
a session that assembles it wrong either halts a fleet that should run or
runs one that should have halted.

## Scope

- `sources` states the whole condition, each part with its own count, and
  says DRY only when all four hold.
- "Two consecutive" needs a previous sweep to compare against. Decide where
  that lives. It is the only piece of state in a harness whose every other
  measure counts from git at read time and stores nothing, so justify it or
  find a way to derive it — a prior sweep's result is recoverable from git
  if a sweep records itself, and that may be cheaper than a state file.
- Open pull requests: `sources` is read-only and offline today. Say what it
  does when it cannot reach GitHub — a sweep that silently treats
  unreachable as zero would report DRY over an open pull request.

## Out of scope

- Acting on the condition. `sources` counts; the session decides. That
  split is in its own banner ("read-only: counts, never acts").
- Changing the four parts. They are the requirement's, ratified 2026-08-25.
- The 151 unmarked findings. That number is `unsupervised-finding-dedupe`'s
  subject, and this plan must work whatever the count is.

## Acceptance

```
./joharness.sh sources        # names all four parts, each with a count
bash .agents/harness/selftest.sh                 # 0 failed
./joharness.sh ci                                # ci: pass
```

Cases must cover DRY and each of the four ways to be not-dry, and each must
red under `./joharness.sh mutate` when its part is disabled. A case green
both ways pins nothing.

## Where to look

- `joharness.sh:cmd_sources` — the three detectors and the dryness line.
- `.agents/harness/AGENTS.md` step 2 — "every detector zero twice running,
  queue empty, no open PR", the sentence this makes countable.
- `joharness.sh:cmd_drain` — the unsupervised branch already defers its stop
  to this sweep, so it is the caller that inherits any wrong answer.

## Traps

- Unreachable is not zero. The offline case is the one that reports DRY over
  work.
- `sources` runs `ci` — it is slow, and `drain` calls it. Do not make it
  slower without saying what it bought.
