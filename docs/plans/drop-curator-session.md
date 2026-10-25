---
plan: drop-curator-session
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: none
scope: shared:joharness.sh, .claude/commands/curate.md, shared:.claude/commands/orchestrate.md, shared:.agents/docs/orchestrated.md, shared:.agents/docs/orchestrate-reference.md, .agents/docs/glossary.md, .agents/docs/plans/README.md, README.md, .agents/scripts/conf-keys.sh, .agents/scripts/bootstrap-consumer.sh, .agents/scripts/sync-to-consumer.sh, shared:.agents/harness/selftest.sh, .agents/harness/selftest/dispatch-curate.sh, .agents/harness/selftest/curate-apply.sh, .agents/harness/selftest/role.sh, shared:.agents/harness/selftest/scout.sh, shared:.agents/harness/selftest/orchestrated.sh, .agents/harness/selftest/reading-budget.sh, .agents/harness/selftest/knobs-declared.sh, .agents/harness/selftest/clerk.sh, .agents/harness/selftest/dispatch-order.sh, .agents/harness/selftest/retro.sh
---

## Goal

The user asked to remove the curator session. Its six merged runs:

- five (#420, #436, #490, #514, #599) changed nothing but their own
  workstream file;
- one (#340) made repairs that `curate --apply` now does;
- none of its decompose or order proposals was followed.

The mechanical part stays: `./joharness.sh curate [--apply]`, which plan
authors and the clerk run, and which ci's `lint_plans_in_diff` reuses.
Remove only the session role and the clock that schedules it.

## Scope

**Delete:**

- `.claude/commands/curate.md`.
- `curate` from `role`: usage lines, `role_start_stop`'s curate case, the
  twin STOP, `scout|curate`.
- The cadence functions: `cycle_landed_sha`, `cycle_landed_ts`,
  `cycle_age_h`, `dispatch_curate_plan_churn`, `curate_noop`,
  `dispatch_curate_due`, `dispatch_curate_branches`. Keep
  `cycle_unreadable` and `cycle_repo_age_h`, which the other roles' clocks
  share.
- dispatch's `curate    :` block, its spawn, held and suppressed lines, and
  `role_will_spawn`'s curate case.
- The `n_curate_inflight` terms in the conduct and retro suppression
  clauses. Reword them to name the roles that remain.
- Knobs `JOHARNESS_CURATE_HOURS` and `JOHARNESS_CURATE_PLANS`: their KNOBS
  rows, the orchestrated.md knob rows, the `conf-keys.sh` rows, and
  `bootstrap-consumer.sh`'s seeded lines and comment.

**Keep:** `cmd_curate` and its helpers, `--apply`, `lint_plans_in_diff`,
and the knobs `_REGISTRY`, `_SPLIT` and `_LAYERS`.

**Fix inside `cmd_curate`:**

- "REPAIR (the curator fixes these in place)" names no one; reword it to
  "`--apply` fixes these".
- The stale "curate.md 0.4" reference goes. Its needle in
  `dispatch-curate.sh` changes with it.
- `judgement :` loses its only reader; delete it unless another reader is
  found.

**Docs:**

- orchestrated.md: roles, prelude, reads and knob rows, and "nightly
  `/curate`".
- orchestrate.md: the curator mentions and the `[curated=<stamp>]` ledger
  field.
- orchestrate-reference.md: the "nightly `/curate`" line, the role list,
  and the `🧭 curator` spawn row.
- glossary.md: drop `🧭 curator` from the role-title row, and edit
  `orchestrated.sh`'s pinned needle with it.
- README.md: the Curator row.
- plans/README.md: the "A curator only PROPOSES" sentence. Say instead
  that `./joharness.sh curate` prints the proposals for the plan author.

**Tests:**

- Remove the cadence cases in `dispatch-curate.sh` (the clock, spawn,
  in-flight and noop needles) and `curate-apply.sh`'s curator-slot cases.
  Re-point the slot case at another role if it tests the cap, not the
  curator.
- Remove the `role.sh` curate cases and `scout.sh`'s "conduct due,
  suppressed by a curate in flight".
- Re-point `knobs-declared.sh` and `sync-to-consumer.sh`'s fixture key away
  from `_PLANS` and `_HOURS`.
- Drop the inert `JOHARNESS_CURATE_HOURS=0` lines in the clerk,
  dispatch-order, retro and scout tests, and the `selftest.sh` unset list
  entries.
- Keep every case on `cmd_curate` and `--apply` output.

**Consumers:** a consumer conf that still sets `JOHARNESS_CURATE_HOURS` or
`_PLANS` must stay green. Read how `knobs-declared` and `conf` treat an
undeclared key. If either reds, keep both keys tolerated as retired (read
and ignored), and record that in `## Decisions`.

## Assumptions

- A1: `cycle_unreadable` and `cycle_repo_age_h` are shared with other
  roles' clocks — evidence: `grep -n 'cycle_unreadable\|cycle_repo_age_h'
  joharness.sh` — confidence: high.
- A2: ci does not run `curate --apply`. It calls `curate_repairs` through
  `lint_plans_in_diff` — evidence: `joharness.sh:lint_plans_in_diff` —
  confidence: high.
- A3: surveyor and `OVERLAP-BOUND` call no `curate_*` function or
  `JOHARNESS_CURATE_*` knob — evidence: `grep -n 'curate'` around
  `OVERLAP-BOUND` in `joharness.sh` — confidence: high.

## Out of scope

- `cmd_curate`'s checks and `--apply`'s repairs.
- Pruning existing `curate-noop-*` refs: branch deletion is human-only.
- The free path, which plan one-release-command removes.
- Core paths.

## Acceptance

```bash
test ! -e .claude/commands/curate.md   # exit 0
./joharness.sh dispatch | grep -c '^curate    :\|curate DUE'   # 0
./joharness.sh curate | grep -c 'verdict   :'   # 1: the command still reports
./joharness.sh role curate; echo $?   # non-zero, "unknown role"
./joharness.sh ci       # ci: pass
./joharness.sh verify   # 0 failed
```

- The pull request body states the selftest assertion counts before and
  after, split into removed (cadence) and kept (`curate` output).
- Consumer side (SHIPS): a fixture consumer conf setting
  `JOHARNESS_CURATE_HOURS=168` runs `./joharness.sh ci` → `ci: pass`.

## Where to look

- `joharness.sh:dispatch_curate_due`: the clock that goes.
- `joharness.sh:cmd_curate`: the command that stays.
- `joharness.sh:lint_plans_in_diff`: ci's reuse of curate's helpers.
- `joharness.sh:role_start_stop`: the role prelude's curate case.
- `.agents/harness/selftest/dispatch-curate.sh:curate DUE`: cadence cases.

## Traps

- Plans one-release-command and retro-audit-and-trace also edit
  joharness.sh and the orchestration docs, including the conduct and retro
  suppression lines this plan rewords. dispatch holds overlapping plans
  apart; reconcile by merge.
- Never skip, disable or quarantine a test to get green: a removed case
  tests a removed behaviour, named in the pull request body.
- Glossary lint bans `handover file`, `model tier`, `env layer`, `rescope
  manager`, `bare role title`.
