---
plan: orchestrated-only
urgency: normal
agent: opus
effort: xhigh
needs: protocol-boundary-core-only
requirement: none
scope: shared:joharness.sh, .agents/harness/queue-context.sh, shared:.agents/harness/handover-guard.sh, .agents/harness/handover-context.sh, .agents/harness/selftest/autonomy-mode.sh, .agents/harness/selftest/drain.sh, .agents/harness/selftest/start.sh, .agents/harness/selftest/authority.sh, .agents/harness/selftest/session-start.sh, .agents/harness/selftest/queue-context-edge.sh, .agents/harness/selftest/queue-context-fanout.sh, .agents/harness/selftest/queue-context-supervised-only.sh, shared:.agents/harness/selftest/handover-guard.sh, .agents/harness/selftest/review.sh, .agents/harness/selftest/dispatch.sh, shared:.agents/harness/selftest/orchestrated.sh, .agents/harness/selftest/perf.sh, .agents/harness/selftest/bootstrap-consumer.sh, shared:.agents/harness/selftest.sh, .claude/commands/drain.md, .claude/commands/start.md, shared:.claude/commands/orchestrate.md, shared:.claude/commands/manage.md, .claude/commands/upstream-report.md, .claude/commands/curate.md, .claude/commands/janitor.md, .agents/scripts/bootstrap-consumer.sh, .agents/scripts/conf-keys.sh, .agents/scripts/sync-to-consumer.sh
---

## Goal

Requester, 2026-10-08: "Only orchestrator mode should be left over",
confirmed in session as everywhere, consumers included, with the
fail-closed default gone. Today three modes exist (`joharness.sh:run_mode`).
After this plan there is one. A session whose prompt names `/manage <item>`
is a manager, and any other session is the orchestrator, including one a
human starts by hand. This supersedes the earlier `drop-unsupervised`
plan, which kept supervised.

## Scope

- `joharness.sh`:
  - `run_mode`, `mode_raw`, `mode_source`, `mode_unrecognised`,
    `mode_warn_unrecognised`, `unattended` — delete the switch. Every caller
    of `unattended` takes the true branch unconditionally, and the false
    branch is deleted. `JOHARNESS_MODE` becomes an obsolete key: absent or
    `orchestrated` = silent; any other value = one warning line at session
    start ("JOHARNESS_MODE is obsolete; orchestrated is the only mode") and
    ignored. It never fails.
  - `cmd_session_start` — one banner (the orchestrated one). Delete the
    supervised and unsupervised banners.
  - `cmd_start` — routes `/manage <item>` → manage, else → orchestrate. No
    mode read.
  - `cmd_drain` — delete the subcommand and its usage line. Keep every
    `drain_*` helper that `cmd_dispatch`, `cmd_curate` or `cmd_janitor` still
    calls, and delete the rest (`drain_free_others` and any other helper with
    no remaining caller; `grep` decides).
  - `cmd_authority` — there is no mode line to prove. Verdict: VERIFIABLE
    when this checkout's `joharness.sh` and `.agents/harness/` match
    `origin/<base>` (the session runs reviewed rules); otherwise NOT
    VERIFIABLE, naming the drifted paths. Delete `authority_commit`'s
    `JOHARNESS_MODE` pattern. Spawn prompts keep carrying `authority`.
  - `SUPERVISED ONLY` marking (queue hook, `drain_supervised_only`,
    `dispatch`) — rename to `CORE ONLY`. It now means a plan whose
    `scope:` names a core path (`protocol_paths`), and only a human builds
    it, by hand. Dispatch's block heading becomes `NOT YOURS — CORE ONLY`.
  - `perf_rows` — rows pinned to a mode: re-pin and RE-COUNT their budgets.
  - Every comment, usage and help line naming supervised or unsupervised.
- `.agents/harness/queue-context.sh`, `handover-guard.sh`,
  `handover-context.sh` — drop the mode branches and keep the orchestrated
  path. `HANDOVER_SCOPE=branch` becomes the only scope, if the fleet-wide
  walk is reachable only from supervised (verify by reading).
- Selftests named in `scope:` — supervised and unsupervised cases are
  deleted when their subject is gone, and re-pinned when the behaviour
  survives. List each deletion with its reason in the PR body. New cases:
  `JOHARNESS_MODE=supervised` warns and runs orchestrated; `authority` on a
  drifted `joharness.sh` reads NOT VERIFIABLE.
- `.claude/commands/drain.md` — delete. `.claude/commands/start.md` — two
  routes. `orchestrate.md`, `manage.md`, `curate.md`, `janitor.md`,
  `upstream-report.md` — delete supervised branches and mode preconditions.
  "Supervised: nothing to check, a human sent you" goes, and `authority` is
  always run.
- `.agents/scripts/bootstrap-consumer.sh` — no mode question and no
  `--mode` flag (given = warning, ignored). The heartbeat note moves to the
  closing message. `conf-keys.sh` — drop the `JOHARNESS_MODE` row.
  `sync-to-consumer.sh` — on update, name `JOHARNESS_MODE` as obsolete when
  a consumer's conf carries it.

## Out of scope

- `joharness.conf` — a core path. Its `JOHARNESS_MODE=orchestrated` line
  stays (silent by rule above). The human deletes it by hand.
- Docs under `.agents/docs/`, the AGENTS.md files and `.agents/harness/README.md`
  belong to `orchestrated-only-docs`.
- Any change to dispatch's health table, the cap or the cadence roles
  beyond deleting mode branches.

## Acceptance

- `git grep -n -i "unsupervised\|JOHARNESS_MODE" -- joharness.sh .agents/harness .claude .agents/scripts`
  → only the obsolete-key warning, its selftest, and links to
  `.agents/docs/unsupervised.md` that the docs plan retires.
- `JOHARNESS_MODE=supervised ./joharness.sh start` → routes to
  `/orchestrate`, plus the obsolete warning.
- `./joharness.sh drain` → unknown subcommand (non-zero).
- `./joharness.sh ci` → `ci: pass`. `./joharness.sh verify` → 0 failed.
- Every changed selftest case fails with its fix reverted.
- SHIPS: the bootstrap selftest — a fresh consumer gets no mode line and
  no mode question, and `--mode supervised` warns.

## Where to look

- `joharness.sh:run_mode`, `joharness.sh:unattended` — the switch.
- `joharness.sh:cmd_start`, `joharness.sh:cmd_session_start`,
  `joharness.sh:cmd_authority`, `joharness.sh:authority_commit`.
- `joharness.sh:cmd_dispatch` — which `drain_*` helpers it calls.
- `.agents/scripts/bootstrap-consumer.sh:write_decided_keys` — mode write.

## Traps

- Built by the fleet once `protocol-boundary-core-only` has merged. Do not
  touch `joharness.conf` or `.claude/settings.json`: the stop guard blocks
  it, and the plan does not need it.
- Perf budgets are counted. Re-count them, never edit them to fit.
- Never skip, disable or quarantine a test to get green.
- `issue-triager-role` needs this plan. `scout-cycle` / `scout-command`
  route through `/start` and `drain`, so reconcile them, or fix the plan
  text in the same PR.
