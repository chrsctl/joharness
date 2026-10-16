---
plan: ci-only-suite-patrol
urgency: normal
agent: opus
effort: high
needs: local-checks-name-unrun-jobs
requirement: none
issue: none
scope: joharness.sh, .agents/harness/selftest/patrol.sh, .agents/harness/selftest.sh, .agents/scripts/conf-keys.sh, .claude/commands/patrol.md, .claude/commands/orchestrate.md, .claude/commands/clerk.md, .agents/docs/orchestrated.md, .agents/harness/AGENTS.md, .agents/docs/consumer-repos.md
---

## Goal

Under `JOHARNESS_CHECKS=local` the harness has a fixing half for broken
suites (issue -> clerk -> plan -> manager) and no capturing half: a step
only GitHub runs counts for nothing, so its regressions never become an
issue (`.agents/docs/consumer-repos.md`, "Local checks"). Add the capturing
half: a consumer declares ONE executable that runs its CI-only suites; a
clock-driven role, the patrol, runs it on fresh `origin/main` and files one
GitHub issue per newly failing criterion; the clerk turns those into plans.
On a clock, not per merge: such suites cost the consumer's whole suite
runtime, paid once a cycle instead of at every `finish`.

## Scope

- `joharness.sh` knob table (`KEY|default|scope|meaning`), plus each knob's
  registration: `conf` keys in `.agents/scripts/conf-keys.sh`, `dispatch`
  keys as a row in `.agents/docs/orchestrated.md`'s knob table
  (`.agents/harness/selftest/knobs-declared.sh` reds otherwise):
  - `JOHARNESS_PATROL_CMD||conf|` — a path, relative to the worktree root
    or absolute, to ONE executable taking no arguments; empty = patrol off. A single
    token, as every conf value is (`joharness.sh:conf_get` keeps up to the
    first blank): a consumer wraps its suites in a script. Exit 0 = green.
    Each stdout line `FAIL <id>` names one failing criterion (`<id>` = no
    whitespace). Non-zero exit with no `FAIL` line = one failure, id
    `patrol-command`.
  - `JOHARNESS_PATROL_HOURS|24|dispatch|` — hours between passes; 0 = off.
  - `JOHARNESS_PATROL_MINUTES|90|dispatch|` — `timeout` bound on the
    executable; hitting it = one failure, id `patrol-timeout`. Also the
    in-flight window below.
- `joharness.sh` subcommand `patrol` (header usage line): fetch
  `origin/main`; `git worktree add --detach` it under a `mktemp -d`
  directory; run the executable there under `timeout`; remove the worktree
  on every exit path (`trap`); print `patrol: green (<short sha>)` or
  `patrol: <n> failing (<short sha>)` then one `FAIL <id>` line each.
  Report-only: no issue, no push. Exit 0 green, 1 failing, 2 off or
  unrunnable (no command, not executable, no `timeout`, fetch failed) with
  the reason.
- `joharness.sh:cmd_role` — accept `patrol` (usage line and `case`), with
  `--twin` as for clerk.
- `joharness.sh` dispatch: a `patrol    :` line beside `clerk`/`conduct`.
  Marker = a `patrol-<YYYYMMDDTHHMMSSZ>` branch at the base head that the
  role pushes FIRST, before running anything (parsed with
  `joharness.sh:clerk_stamp_ts`). Newest marker younger than
  `JOHARNESS_PATROL_MINUTES` = `IN FLIGHT`; else `DUE — <n>h since the last
  patrol (of <hours>h)` or `not due — …`; no command or hours 0 = `off —
  <reason>`. Command empty AND `JOHARNESS_CHECKS=local` AND
  `checks_unrun_jobs 0` printing N > 0 rows: reason `N workflow job(s) with
  a step not run here and JOHARNESS_PATROL_CMD is empty`.
- `.claude/commands/patrol.md` — the role. Prelude `./joharness.sh role
  patrol --twin` (`GO` / `STOP:` as `clerk.md` §1). Push the marker. Run
  `./joharness.sh patrol` as a background command (a foreground call caps
  at 600 s; `clerk.md` and `conduct.md` state that ceiling) and wait for
  its completion notice; the `timeout` inside bounds it. For each `FAIL
  <id>`: search open issues for title `patrol: <id> fails on main`; none =
  file it, body = the sha, `JOHARNESS_PATROL_CMD`'s value, and the last 40
  output lines; open = add nothing. Opens no pull request, writes no plan,
  edits no file.
- `.claude/commands/clerk.md` §3 "Verify, then decide" — an issue whose
  title starts `patrol:` carries its own reading. The clerk re-runs
  `./joharness.sh patrol` when it can; when it cannot (exit 2, or the
  executable needs services the clerk lacks) the patrol's output stands as
  the reading and the verdict is never DOES NOT HOLD. Re-running a
  different, weaker suite is not a reading of this one.
- `.claude/commands/orchestrate.md` — role table row `patrol DUE` |
  sonnet | `patrol: <UTC date>` | `/patrol` | `patrolled=<stamp>`; ledger
  line gains `[patrolled=<stamp>[+human]]`. Holds no slot, like conduct.
- `.agents/docs/orchestrated.md` — the role table under "The role prelude
  is a command" gains a patrol row; the patrol joins every list naming
  clerk and conduct as clock-driven roles; the two knob rows above.
- `.agents/harness/selftest/patrol.sh` — new topic, listed in
  `.agents/harness/selftest.sh:SELFTEST_TOPICS`. Fixtures: an executable
  printing `FAIL a`, exit 1 -> `patrol: 1 failing`, exit 1; one exiting 0
  -> exit 0, and `git worktree list` shows no patrol worktree after; one
  sleeping past the bound -> `FAIL patrol-timeout` (a fixture `timeout`
  shim on `PATH`, so the topic waits no minute); empty command -> exit 2;
  dispatch in a fixture repo with a fresh marker -> `IN FLIGHT`; local mode
  with a `make slow-suite` workflow step and no command -> the off reason.
- `.agents/harness/AGENTS.md` step 7 first bullet — those steps are the
  patrol's (`JOHARNESS_PATROL_CMD`).
- `.agents/docs/consumer-repos.md` "Local checks" — rewrite to the new
  status quo: the second and fourth bullets become the patrol and the
  clerk's rule; the closing paragraph names the knob.

## Out of scope

- Running the executable from `finish`, per merge. Rejected in Goal.
- Mapping diff paths to suites. Same reason.
- Provisioning any service: the consumer's executable provisions what it
  needs. `.agents/harness/` names no environment.
- Setting the knob in this repo's `joharness.conf` (core path). Declared,
  unset.
- Writing plans from a failure: the clerk plans issues
  (`.agents/docs/plans/README.md`, Lifecycle: no session writes a plan from
  a detector).
- Closing an issue when its criterion turns green again: the fixing
  manager's pull request closes it.
- Deleting old `patrol-*` markers.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- With a scratch executable `s` printing `FAIL x` and exiting 1, at an
  absolute path outside the checkout (the worktree is `origin/main`, which
  does not carry it):
  `JOHARNESS_PATROL_CMD=/abs/s ./joharness.sh patrol; echo "rc=$?"` —
  `patrol: 1 failing (<sha>)`, `FAIL x`, `rc=1`.
- `JOHARNESS_PATROL_CMD=` `./joharness.sh patrol; echo "rc=$?"` — names
  the off reason, `rc=2`.
- A conf fixture line `JOHARNESS_PATROL_CMD=scripts/ci-only.sh` reads back
  whole (`conf_get`), proven in the selftest topic.
- `./joharness.sh dispatch` in this repo — a `patrol    : off —` line.
- Mutation: drop the `timeout` wrapper in a scratch copy — the
  `patrol-timeout` assertion FAILs. Restore.
- SHIPS: `joharness.sh` and `.claude/commands/` reach consumers; the
  selftest does not (`.agents/scripts/sync-to-consumer.sh:CANONICAL_ONLY_DIRS`).
  Consumer-run checks: `./joharness.sh patrol` and `./joharness.sh
  dispatch`, both run in a consumer; quote their output from the
  acceptance above in the PR body.

## Where to look

- `joharness.sh:conf_get` — single-token values.
- `joharness.sh:clerk_stamp_ts`, `joharness.sh:clerk_noop` — the marker and
  its parser.
- `joharness.sh:clerk_due`, `joharness.sh:conduct_due` — due/off/in-flight
  shapes; the dispatch block printing `clerk     :` and `conduct   :`.
- `joharness.sh:cmd_role` — the role `case`.
- `joharness.sh:checks_unrun_jobs` — built by
  `local-checks-name-unrun-jobs`.
- `.agents/harness/selftest/knobs-declared.sh` — which registration each
  knob scope needs.
- `.agents/harness/selftest.sh:SELFTEST_TOPICS` — topic registration.
- `.claude/commands/orchestrate.md` — role table (`| line | model
  (Lineup) |`) and the ledger line.
- `.claude/commands/clerk.md` — §1 twin check, §3 verify.

## Traps

- `.agents/harness/` names no specific environment, and no consumer, nor
  its job or suite names, is named in harness text
  (`.agents/docs/consumer-repos.md`, "Name no consumer").
- Never commit to a core path: `joharness.conf`, `.claude/settings.json`,
  `.github` (`./joharness.sh protocol-paths`).
- A background command must be able to finish: the `timeout` bound is the
  point.
- Never `git push --delete` old markers: branch deletion is human-only.
- Edits the same step-7 bullet and "Local checks" section as
  `local-checks-name-unrun-jobs`; it lands first (`needs`).
- NEVER skip, disable or quarantine a test to get green.
