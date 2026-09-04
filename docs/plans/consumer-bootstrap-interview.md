---
plan: consumer-bootstrap-interview
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: .agents/scripts/bootstrap-consumer.sh, .agents/harness/selftest/bootstrap-consumer.sh, .agents/docs/consumer-repos.md, .agents/docs/unsupervised.md
---

## Goal

Requester: "add all switches to the initial questions". The bootstrap asks a
child exactly one question today — the autonomy switch — while the other four
conf keys are either a flag (`--env`) or a hardcoded seed value nobody is
offered a say in (`JOHARNESS_ENV_SETUP`, `JOHARNESS_ENV_MD`,
`JOHARNESS_REVIEW`). Every switch a child runs under should be put to whoever
stands up that child, once, at first contact.

## Scope

- `.agents/scripts/bootstrap-consumer.sh` — one interview covering all five
  conf keys, a flag per key for runs with nobody to ask, validation of every
  explicit value, and one generalised conf writer replacing `set_conf_mode`.
- `.agents/harness/selftest/bootstrap-consumer.sh` — a case per flag, per
  refusal, and per interview answer, driven under the existing pty helper.
- `.agents/docs/consumer-repos.md`, `.agents/docs/unsupervised.md` — what is
  asked and what each answer decides.

## Out of scope

- **Changing any default.** `none`, `lazy`, `lazy`, `off`, `supervised` are
  the answers a repo gets today and stay the answers it gets by pressing
  Enter. This plan moves who is asked, never what is assumed.
- **Overwriting a conf value nobody was asked about.** The existing cases
  pinning `JOHARNESS_ENV=custom-own` through a bootstrap are the rule, not an
  accident: a key is written to an existing conf only when a flag gave it or
  the interview answered it. `JOHARNESS_MODE` keeps its documented exception.
- **A new conf key, or a new meaning for an existing one.**
- **`sync-to-consumer.sh`.** Steady state never re-asks and never touches the
  conf.
- **Any prompt outside first contact**, and any prompt in a run with no
  terminal.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed. The diff touches a non-`*.md` file under
  `.agents/scripts/`, so step 7 requires it.
- Each of the five flags reaches the seeded conf; each refuses an unknown
  value with exit 1 and nothing written.
- A run with no terminal and no flags seeds today's defaults unchanged.
- Under a pty, answering every question with Enter leaves a pre-existing
  conf's own values intact — including a layer name canonical does not carry.
- The two environment-shaped questions are skipped when the selected layer is
  `none`, since they configure a layer the repo does not have.
- Each new case made to fail by injection with `./joharness.sh mutate` before
  it is trusted.
- SHIPS: `.agents/harness/selftest.sh` in a consumer — the script and its
  selftest topic both sync, so these cases run there too.

## Where to look

- `.agents/scripts/bootstrap-consumer.sh:resolve_autonomy` — the one existing
  question; the interview generalises it.
- `.agents/scripts/bootstrap-consumer.sh:set_conf_mode` — the writer to
  generalise, and the shape both bootstrap shapes already route through.
- `joharness.sh:conf_get` — how a child reads these keys back.
- `.agents/env/README.md` — what a layer is and which ones exist.

## Traps

- A default offered in the interview must be the conf's CURRENT value where
  one exists. Offering the seed default and writing what Enter accepts would
  strip a selection somebody made, which is what the `custom-own` cases pin.
- `read` under `set -euo pipefail` returns nonzero at end of file.
- A dry run must leave the consumer tree byte-identical, so it never prompts.
- Every reader of these keys fails closed on an unrecognised value, so a typo
  in a flag has to be refused here or it is silent for the life of the repo.
