---
plan: orchestrated-mode
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: orchestrated-mode
scope: joharness.sh, .agents/harness, .claude/commands, .agents/docs, .agents/scripts, joharness.conf
---

## Goal

Same-session plan for the requester's direct ask (2026-09-05): a third
autonomy mode, `orchestrated`, in which an orchestrator session dispatches
the queue to manager sessions under a concurrency cap, watches their
health, and kills a stuck one only after its handover is written. Lives on
the work branch; deleted in the pull request that ships it.

## Scope

- `joharness.sh` — `run_mode` accepts `orchestrated`; `unattended()`;
  banner, `authority`, `drain`, `lint_requirement_writes` read the
  predicate; new `dispatch` subcommand; help text.
- `.agents/harness/queue-context.sh`, `handover-guard.sh`,
  `handover-context.sh` — the unattended branches fire for both values.
- `.agents/harness/selftest/orchestrated.sh`, `dispatch.sh` — new topics.
- `.claude/commands/orchestrate.md`, `.claude/commands/manage.md` — roles.
- `.agents/docs/orchestrated.md` (new), `prior-art.md` (ported, extended),
  `unsupervised.md`, `subagents.md`, `product/README.md`, harness
  `AGENTS.md` and `README.md` — the rules and why.
- `.agents/scripts/bootstrap-consumer.sh`, `conf-keys.sh` — accept the value.
- `joharness.conf` — the four knobs, commented, with beta defaults.

## Out of scope

- Running the mode. `docs/plans/orchestrated-run.md` is that, and it is
  operator-gated (money, Routine).
- A merge queue, a state store, a status field anywhere.
- Changing what unsupervised does.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `JOHARNESS_MODE=orchestrated ./joharness.sh mode` — `orchestrated`.
- `JOHARNESS_MODE=orchestrated ./joharness.sh session-start` — banner names
  the mode, the orchestrator command and the boundary.
- `JOHARNESS_MODE=orchestrated ./joharness.sh dispatch` on a fixture — cap,
  in-flight managers with push age, spawn order by wave, verdict.
- `./joharness.sh verify` — 0 failed (diff touches non-md harness files).
- SHIPS: in a consumer after its next sync, `JOHARNESS_MODE=orchestrated
  ./joharness.sh dispatch` prints `cap       : 4 manager(s)` and a verdict
  line, with no selftest present there.

## Where to look

- `joharness.sh:cmd_drain` — the single-session reading `dispatch` widens.
- `.agents/harness/queue-context.sh:wave_split_hit` — waves the spawn order
  follows.
- `.agents/docs/unsupervised.md` — bounds this mode inherits unchanged.

## Traps

- Protocol text: this branch edits it, so it is supervised work; the plan
  is `SUPERVISED ONLY` by scope and must never be offered to a fleet.
- Never a status field. Every dispatch view derives from git at read time.
- Retire this plan file and the workstream file in the last commit before
  the pull request opens.
