---
plan: one-mode
urgency: urgent
agent: opus
effort: xhigh
needs: role-bound
requirement: none
scope: joharness.sh, .agents/harness, .claude/commands, .agents/scripts/bootstrap-consumer.sh, .agents/scripts/conf-keys.sh, .agents/scripts/sync-to-consumer.sh, joharness.conf
---

## Goal

Requester, 2026-10-08: "Supervised is orchestrated, we want to drop single
drain start, unsupervised is unnecessary, clean up." After `role-bound`
the bounds key on role, so the mode decides only routing. Make orchestrated
the only behaviour: `/start` with no item runs the orchestrator, `/manage
<item>` a manager. Delete supervised, unsupervised and the single-item
`/drain`. Consumers included: one mode everywhere, default cap 1 so a
consumer that never chose gets one manager at a time (decided alone,
flagged in the PR body).

## Scope

- `joharness.sh`:
  - `run_mode`, `mode_raw`, `mode_source`, `mode_unrecognised`,
    `mode_warn_unrecognised`, `unattended`, the `mode` subcommand: delete,
    or reduce to what `role-bound` left reading them. `JOHARNESS_MODE` is
    no longer read; a conf still carrying it gets one warning naming it
    obsolete, never an error.
  - `cmd_start`: always orchestrate.md, keeping the `/manage` STOP line.
  - `cmd_drain` and the `drain` subcommand: delete. Helpers `cmd_dispatch`
    and `cmd_curate` use (`drain_hook`, `drain_requirement`,
    `drain_supervised_only`) survive renamed `queue_hook`,
    `queue_requirement`, `queue_human_only`.
  - `cmd_dispatch`: drop the NOT ORCHESTRATED branch.
  - `cmd_authority`: drop the mode-commit check (`authority_commit` on the
    `JOHARNESS_MODE` line); keep whatever `role-bound` made it check, or
    delete the subcommand if nothing is left — then strip it from
    orchestrate.md and manage.md preconditions.
  - `cmd_session_start`: one banner (today's orchestrated one); always the
    branch-scoped handover view.
  - Perf rows `drain`, `queue-context` (unsupervised pin), `handover-guard`
    (unsupervised pin): delete or re-pin to orchestrated; re-count budgets,
    never copy the old numbers.
  - `num_knob JOHARNESS_MAX_MANAGERS` default 4 → 1.
  - Usage header text.
- `.agents/harness/queue-context.sh`, `handover-context.sh`,
  `handover-guard.sh`: drop the unsupervised/supervised branches.
- `.agents/harness/selftest/`: delete `drain.sh`, `autonomy-mode.sh`;
  rewrite mode cases in `start.sh`, `authority.sh`, `dispatch.sh`,
  `orchestrated.sh`, `queue-context-*.sh`, `handover-*.sh`, `review.sh`,
  `perf.sh`, `bootstrap-consumer.sh`, `sync-to-consumer.sh`; update the
  topic list in `.agents/harness/selftest.sh`.
- `.claude/commands/drain.md`: delete. `start.md`, `curate.md`,
  `janitor.md`, `upstream-report.md`: drop drain and supervised wording.
- `.agents/scripts/bootstrap-consumer.sh`: drop `--mode` and the autonomy
  interview; stop writing `JOHARNESS_MODE`; `--mode` given = warning, not
  error. `conf-keys.sh`: drop the `JOHARNESS_MODE` row; add
  `JOHARNESS_MAX_MANAGERS|1|…` so the sync report names the new default.
- `joharness.conf`: drop the `JOHARNESS_MODE` block; keep
  `JOHARNESS_MAX_MANAGERS=1` (now equal to the default — delete the line
  and the whole-clone strip from PR #306 only if a test proves it inert).

## Out of scope

- Docs under `.agents/docs/` and the AGENTS.md files: plan `one-mode-docs`.
- Any change to the orchestrator's loop logic, health pass, or cap
  arithmetic beyond the default.
- Creating a heartbeat Routine.

## Acceptance

- `grep -rn "unsupervised\|cmd_drain\|drain\.md\|JOHARNESS_MODE" joharness.sh .agents/harness .claude .agents/scripts`
  — no hit, except the obsolete-key warning and its test.
- `./joharness.sh start` — `follow    : .claude/commands/orchestrate.md`
  with or without `JOHARNESS_MODE` set.
- `./joharness.sh drain` — unknown command.
- `./joharness.sh ci` — `ci: pass`; `./joharness.sh verify` — 0 failed.
- Plan `ci` calls SHIPS: bootstrap selftest — a fresh consumer's conf has
  no `JOHARNESS_MODE` and `./joharness.sh start` there names orchestrate.md.

## Where to look

- `joharness.sh:run_mode` — every mode branch hangs off it.
- `joharness.sh:cmd_drain` — the deleted subcommand; its helpers live on.
- `joharness.sh:cmd_start` — routing.
- `joharness.sh:perf_rows` — perf pins.
- `.agents/scripts/bootstrap-consumer.sh:write_decided_keys` — mode write.
- `.agents/scripts/conf-keys.sh` — key defaults for consumers.

## Traps

- Never skip, disable or quarantine a test to get green: a deleted topic is
  deleted because its subject is gone, and the PR says which.
- Perf budgets are counted numbers; re-count, never edit to fit.
- Ships to every consumer: a consumer conf still saying
  `JOHARNESS_MODE=supervised` must keep working (warning only).
