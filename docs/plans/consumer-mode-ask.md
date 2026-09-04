---
plan: consumer-mode-ask
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: .agents/scripts/bootstrap-consumer.sh, .agents/harness/selftest/bootstrap-consumer.sh, .agents/docs/unsupervised.md, .agents/docs/consumer-repos.md
---

## Goal

Requester wants automatic draining — the queue emptied with no human turn
between items — available to a child repo as a MODE SWITCH that is **not
enabled by default**, and wants the bootstrap into a child to **ask** for it.
The mode itself already exists (`JOHARNESS_MODE=unsupervised`) and already
fails closed. What is missing is the ask at first contact, and one defect the
ask exposes: a whole-clone child inherits canonical's autonomy answer
silently, so a clone taken while canonical is flipped comes up unsupervised
without anyone choosing it.

## Scope

- `.agents/scripts/bootstrap-consumer.sh` — a `--mode` flag, an interactive
  ask when the run has a terminal and the flag is absent, and the resolved
  answer written into the child's conf in BOTH modes. Fresh mode seeds no
  `JOHARNESS_MODE` line today; whole-clone inherits canonical's.
- `.agents/harness/selftest/bootstrap-consumer.sh` — cases for the default,
  the flag, both non-interactive paths, the whole-clone force, and the
  refusal of an unrecognised value.
- `.agents/docs/unsupervised.md` — how a child gets the mode, and that the
  switch alone automates nothing without the heartbeat.
- `.agents/docs/consumer-repos.md` — the ask in the bootstrap route.

## Out of scope

- **Flipping canonical's own `JOHARNESS_MODE`.** Not enabled by default is the
  requirement; this repo stays supervised and its conf is untouched.
- **Creating a heartbeat Routine, or any code that creates one.** Recurring
  spend is the human's (`.agents/harness/AGENTS.md`, Decide alone) and
  `.agents/docs/unsupervised.md` says a session documents one and never
  creates one. The bootstrap may PRINT the next step; it may not take it.
- **A spend cap, a run-length limit, or a halt on red `main`.** The requester
  declined all three on 2026-08-24 and a session must not add one back on its
  own judgment.
- **Changing what the mode does.** The switch's behaviour is settled; this
  plan only routes an answer into a child's conf.
- **`sync-to-consumer.sh`.** The conf is consumer-own and never synced; steady
  state must not re-ask or overwrite a child's answer.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed; the diff touches a non-`*.md` file under
  `.agents/scripts/`, so step 7 requires this one and it is not inherited from
  the head's checks.
- Fresh bootstrap with no flag and no terminal seeds `JOHARNESS_MODE=supervised`.
- `--mode unsupervised` seeds `JOHARNESS_MODE=unsupervised` and prints the
  heartbeat next step.
- A whole clone whose conf carries `JOHARNESS_MODE=unsupervised` comes out
  `supervised` when the flag is absent.
- `--mode nonsense` exits 1 having written nothing.
- Each new case was made to fail by injection before it was trusted.

## Where to look

- `.agents/scripts/bootstrap-consumer.sh:bootstrap_whole_clone` — where the
  clone's inherited `JOHARNESS_ENV` is rewritten; the mode needs the same
  treatment with the opposite default.
- `joharness.sh:run_mode` — the fail-closed resolution the conf feeds.
- `joharness.sh:protocol_paths` — proves `joharness.conf` is not protocol text,
  so a child's conf is writable by a session.

## Traps

- The script already uses `MODE` for fresh/whole-clone. A second meaning in one
  variable is the bug this line exists to prevent.
- `read` under `set -euo pipefail` returns nonzero at EOF and would kill the
  run; the ask must survive a closed stdin.
- A dry run must leave the filesystem byte-identical, so it never prompts.
- Fail closed: any value that is not `unsupervised` resolves to supervised,
  matching `run_mode`.
