---
plan: ci-job-cap
urgency: normal
agent: sonnet
effort: low
needs: none
requirement: none
scope: .github/workflows/ci.yml
---

## Goal

`.github/workflows/ci.yml` declares no `timeout-minutes`, so GitHub's default
360-minute cap is what stands between a hung job and a held runner. The job
normally finishes in under three minutes. A hang is not hypothetical here: a
selftest change made during pull request #209 blocked on a pty read that never
returned, and only a local kill ended it — on a runner that would have been
six hours of a machine nobody was watching.

## Scope

- `.github/workflows/ci.yml` — `timeout-minutes` on both jobs, with the
  measurement that sized the `lint` one written beside it.

## Out of scope

- **Step-level timeouts.** The job cap is the backstop; a per-step number is
  a second place to keep the same reasoning current.
- **Making the job faster.** It is not slow.
- **`update.yml`.** It runs the sync on a cron and has its own risk profile;
  capping it is a separate judgment with separate evidence.
- **Reaching existing consumers.** `ci.yml` is seeded verbatim at bootstrap
  and never synced (`.agents/scripts/sync-to-consumer.sh`), so this reaches
  repos bootstrapped after it lands and no others. Saying so is in scope;
  changing how the file is delivered is not.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- The `lint` job carries `timeout-minutes`, and the value is at least five
  times the slowest run measured below.
- The pull request's own run is green, which is the only way this file's
  syntax gets proven — nothing in the suite parses the workflow.
- SHIPS: nothing. This file is consumer-own and never synced; the plan states
  that rather than naming a consumer-side check it cannot have.

## Where to look

- `.github/workflows/ci.yml:lint` — the job, and the comment block above it
  that already explains what the two steps are for.
- `.agents/scripts/ci-verify-layers.sh` — the second step, which provisions
  any layer declaring `ci-verify`. `.agents/env/docker/ci-verify` exists, so
  that work is inside the measured numbers.

## Traps

- A number here is a written number unless it carries what produced it. The
  `lint` cap is sized from a counted range; the `windows` cap is not, because
  that job is disabled and has no runs to count — say which is which.
- The Windows job is `if: false`. A cap on it changes nothing today and must
  not be described as though it had been measured.
