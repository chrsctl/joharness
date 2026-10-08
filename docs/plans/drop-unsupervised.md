---
plan: drop-unsupervised
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: none
scope: joharness.sh, .agents/harness/queue-context.sh, .agents/harness/handover-guard.sh, .agents/harness/handover-context.sh, .agents/harness/selftest/autonomy-mode.sh, .agents/harness/selftest/drain.sh, .agents/harness/selftest/queue-context-edge.sh, .agents/harness/selftest/queue-context-fanout.sh, .agents/harness/selftest/queue-context-supervised-only.sh, .agents/harness/selftest/handover-guard.sh, .agents/harness/selftest/review.sh, .agents/harness/selftest/dispatch.sh, .agents/harness/selftest/orchestrated.sh, .agents/harness/selftest/perf.sh, .claude/commands/drain.md, .claude/commands/upstream-report.md, .agents/scripts/bootstrap-consumer.sh, .agents/scripts/conf-keys.sh, joharness.conf
---

## Goal

Requester, 2026-10-08: "We still want to keep the current orchestration
mode. We can still leave drain if it's used in the cycle — we only want to
remove unnecessary stuff." Three modes exist; `unsupervised` (each
heartbeat-fired session takes one item and exits) is now redundant:
orchestrated at `JOHARNESS_MAX_MANAGERS=1`, fired by the same heartbeat
Routine, is the same loop with a health pass. Remove `unsupervised`. Keep
`supervised` (fail-closed default, the human-driven session, the
`JOHARNESS_MODE=supervised` override harness work here relies on) and
`orchestrated`. Keep `/drain` and `./joharness.sh drain`: supervised's
route, and `cmd_dispatch`/`cmd_curate` reuse its helpers.

## Scope

- `joharness.sh`:
  - `run_mode`: `unsupervised` stops resolving — reads as supervised (fails
    closed, as any unknown value does) and `mode_warn_unrecognised` names it
    obsolete with the replacement (`orchestrated`, cap 1). `unattended`:
    orchestrated only. `mode_unrecognised` accepts ''/supervised/orchestrated.
  - `cmd_drain`: delete the unsupervised-only output — the spawn line
    (`drain_free_others`, delete if nothing else calls it), the "exit, the
    heartbeat re-seeds" DRAINED line. Keep supervised and orchestrated output.
  - `cmd_session_start`: delete the unsupervised banner.
  - `cmd_authority`: wording naming unsupervised.
  - `perf_rows`: the `queue-context` and `handover-guard` rows pinned to
    unsupervised — re-pin to orchestrated and RE-COUNT their budgets.
  - Usage header and comments naming unsupervised (incl. `protocol_paths`
    header "The unsupervised boundary" → unattended boundary).
- `.agents/harness/queue-context.sh`: the unsupervised EXIT trap; keep the
  orchestrated one. `handover-guard.sh`: mode test → orchestrated.
  `handover-context.sh`: compaction mode→rules mapping.
- `.agents/harness/selftest/autonomy-mode.sh` — unsupervised cases become
  "reads as supervised, warns obsolete"; unsupervised fixtures in
  `.agents/harness/selftest/drain.sh`,
  `.agents/harness/selftest/queue-context-edge.sh`,
  `.agents/harness/selftest/queue-context-fanout.sh`,
  `.agents/harness/selftest/queue-context-supervised-only.sh`,
  `.agents/harness/selftest/handover-guard.sh`,
  `.agents/harness/selftest/review.sh`,
  `.agents/harness/selftest/dispatch.sh`,
  `.agents/harness/selftest/orchestrated.sh`,
  `.agents/harness/selftest/perf.sh` → orchestrated, or deleted when
  the subject (spawn line, heartbeat exit) is gone; say which in the PR.
- `.claude/commands/drain.md`: "What stops it" unsupervised bullet.
  `.claude/commands/upstream-report.md`: its unsupervised.md citation (point
  at whatever `drop-unsupervised-docs` will name; until then keep the link
  valid).
- `.agents/scripts/bootstrap-consumer.sh`: `--mode` accepts
  supervised|orchestrated; `unsupervised` given = warning + supervised; the
  interview offers supervised/orchestrated; heartbeat warning moves to the
  orchestrated answer. `conf-keys.sh`: `JOHARNESS_MODE` meaning text.
- `joharness.conf`: comment text naming unsupervised.

## Out of scope

- `supervised`, `/drain`, `./joharness.sh drain`, `/start` routing — kept.
- Docs under `.agents/docs/` and the AGENTS.md files: plan
  `drop-unsupervised-docs`.
- Any change to orchestrated behaviour, the cap, or dispatch.

## Acceptance

- `grep -rn "unsupervised" joharness.sh .agents/harness .claude .agents/scripts joharness.conf`
  — only the obsolete-value warning, its tests, and links to
  `.agents/docs/unsupervised.md` that the docs plan retires.
- `JOHARNESS_MODE=unsupervised ./joharness.sh mode` — `supervised`, warning
  names `orchestrated`.
- `./joharness.sh ci` — `ci: pass`; `./joharness.sh verify` — 0 failed.
- Every changed selftest case fails with its fix reverted (Loop step 5).
- Plan `ci` calls SHIPS: bootstrap selftest — `--mode unsupervised` on a
  fresh consumer writes `supervised` and warns.

## Where to look

- `joharness.sh:run_mode` — resolution; `joharness.sh:unattended` — bounds.
- `joharness.sh:cmd_drain` — mode branches near the DRAINED verdict.
- `joharness.sh:perf_rows` — pinned rows.
- `.agents/harness/queue-context.sh` — `qc_mode`, EXIT traps.
- `.agents/scripts/bootstrap-consumer.sh:write_decided_keys` — mode write.

## Traps

- Fails closed: an unknown mode must read supervised, never unattended.
- Perf budgets are counted; re-count, never edit to fit.
- Never skip, disable or quarantine a test to get green.
- Protocol text: build from a session with `JOHARNESS_MODE=supervised`
  exported (this repo's conf is orchestrated).
