---
plan: ci-only-suite-patrol
urgency: normal
agent: sonnet
effort: high
needs: local-checks-name-unrun-jobs
requirement: none
issue: none
scope: joharness.sh, .agents/harness/selftest/patrol.sh, .agents/harness/selftest.sh, .agents/scripts/conf-keys.sh, .claude/commands/clerk.md, .agents/docs/orchestrated.md, .agents/harness/AGENTS.md, .agents/docs/consumer-repos.md
---

## Goal

Under `JOHARNESS_CHECKS=local` the harness has a fixing half for broken
suites (issue -> clerk -> plan -> manager) and no capturing half: a step
only GitHub runs counts for nothing, so its regressions never become an
issue (`.agents/docs/consumer-repos.md`, "Local checks"). Add the capturing
half to the role that already runs on a clock and already turns issues into
plans: the clerk. A consumer declares ONE executable that runs its CI-only
suites; each clerk pass first runs it on fresh `origin/main` (the patrol),
files one issue per failing criterion, and plans those issues in the same
pass on its own reading. No new role, no new dispatch cycle: the clerk's
clock, twin check, slot and ledger key stay as they are. On a clock, not
per merge: such suites cost the consumer's whole suite runtime, paid once a
clerk cycle instead of at every `finish`.

## Scope

- `joharness.sh` knob table (`KEY|default|scope|meaning`), plus each knob's
  registration (`.agents/harness/selftest/knobs-declared.sh` reds
  otherwise): `conf` keys in `.agents/scripts/conf-keys.sh`, `dispatch`
  keys as a row in `.agents/docs/orchestrated.md`'s knob table:
  - `JOHARNESS_PATROL_CMD||conf|` — a path, relative to the worktree root
    or absolute, to ONE executable taking no arguments; empty = no patrol.
    A single token, as every conf value is (`joharness.sh:conf_get` keeps
    up to the first blank): a consumer wraps its suites in a script. Exit 0
    = green. Each stdout line `FAIL <id>` names one failing criterion
    (`<id>` = no whitespace). Non-zero exit with no `FAIL` line = one
    failure, id `patrol-command`.
  - `JOHARNESS_PATROL_MINUTES|90|dispatch|` — `timeout` bound on the
    executable; hitting it = one failure, id `patrol-timeout`. Also the
    window a patrol marker reads in flight (below).
- `joharness.sh` subcommand `patrol` (header usage line): fetch
  `origin/main`; `git worktree add --detach` it under a `mktemp -d`
  directory; run the executable there under `timeout`; remove the worktree
  on every exit path (`trap`); print `patrol: green (<short sha>)` or
  `patrol: <n> failing (<short sha>)`, then one `FAIL <id>` line each.
  Report-only: no issue, no push. Exit 0 green, 1 failing, 2 no patrol or
  unrunnable (no command, not executable, no `timeout`, fetch failed) with
  the reason.
- `joharness.sh:clerk_due` (and the dispatch `clerk     :` line it feeds) —
  a clerk running a patrol pushes nothing for up to
  `JOHARNESS_PATROL_MINUTES`, so it must not read as no clerk at all. A
  `clerk-patrol-<YYYYMMDDTHHMMSSZ>` branch (parsed with
  `joharness.sh:clerk_stamp_ts`) younger than `JOHARNESS_PATROL_MINUTES`
  reads `IN FLIGHT`, as an unmerged `clerk-<digit>` branch does today. It
  never dates the clock: only the merge or the `clerk-noop-` record does.
  With `JOHARNESS_CHECKS=local`, `JOHARNESS_PATROL_CMD` empty and
  `checks_unrun_jobs 0` printing N > 0 rows, the clerk line carries one
  more clause: `no patrol: N workflow job(s) with a step not run here and
  JOHARNESS_PATROL_CMD is empty`.
- `.claude/commands/clerk.md` — new section between §1 Branch and §2 Read,
  `## 1b. Patrol`, skipped when `./joharness.sh patrol` would exit 2 for no
  command (`./joharness.sh clerk` prints whether the command is set):
  1. Push the marker first: `git push origin
     "origin/main:refs/heads/clerk-patrol-$(date -u +%Y%m%dT%H%M%SZ)"`.
  2. Run `./joharness.sh patrol` in the Bash tool's background mode (a
     foreground call caps at 600 s) and wait for its completion notice;
     the `timeout` inside bounds it. This is the one command the clerk runs
     that it has not read whole: the executable is the one a human named
     in `joharness.conf`, a core path; §3's read-only rule does not cover
     it, and the section says so.
  3. Exit 2 = report the reason, go on to §2. For each `FAIL <id>`: an open
     issue titled `patrol: <id> fails on main` = add nothing; none = file
     it, body = the sha, the command, the last 40 output lines.
  4. Every open `patrol:` issue whose id failed in THIS run is read first
     in §2, ahead of oldest-first order and within `JOHARNESS_CLERK_BATCH`,
     and its §3 reading is this run's output: HOLDS, plan `issue: <N>`. An
     open `patrol:` issue whose id did not fail this run: DOES NOT HOLD
     with this run's sha as evidence (a human closes it). Never re-run a
     different or weaker suite as the reading of a `patrol:` issue.
  The clerk's §4 (pull request or `clerk-noop-` record) is unchanged.
- `joharness.sh:cmd_clerk` — print `patrol    : <command>` or `patrol    :
  none (JOHARNESS_PATROL_CMD empty)` so §1b reads it without opening conf.
- `.agents/docs/orchestrated.md` — wherever the clerk's cycle is described,
  one sentence: a clerk pass runs the patrol first when the command is set;
  the two knob rows above.
- `.agents/harness/selftest/patrol.sh` — new topic, listed in
  `.agents/harness/selftest.sh:SELFTEST_TOPICS`. Fixtures: an executable
  printing `FAIL a`, exit 1 -> `patrol: 1 failing`, exit 1; one exiting 0
  -> exit 0, and `git worktree list` shows no patrol worktree after; one
  sleeping past the bound -> `FAIL patrol-timeout` (a fixture `timeout`
  shim on `PATH`, so the topic waits no minute); empty command -> exit 2; a
  conf fixture line `JOHARNESS_PATROL_CMD=scripts/ci-only.sh` reads back
  whole; dispatch with a fresh `clerk-patrol-` marker -> clerk `IN
  FLIGHT`, with a stale one -> not; local mode with a `make slow-suite`
  workflow step and no command -> the `no patrol:` clause.
- `.agents/harness/AGENTS.md` step 7 first bullet — those steps are the
  clerk's patrol (`JOHARNESS_PATROL_CMD`).
- `.agents/docs/consumer-repos.md` "Local checks" — rewrite to the new
  status quo: the second and fourth bullets become the clerk's patrol and
  its reading rule; the closing paragraph names the knob.

## Out of scope

- A separate role, command file, `cmd_role` entry, dispatch line, ledger
  key or role-table row for the patrol. The clerk's carry it.
- Running the executable from `finish`, per merge. Rejected in Goal.
- Mapping diff paths to suites. Same reason.
- Provisioning any service: the consumer's executable provisions what it
  needs. `.agents/harness/` names no environment.
- Setting the knob in this repo's `joharness.conf` (core path). Declared,
  unset.
- Closing an issue when its criterion turns green: the fixing manager's
  pull request closes it; DOES NOT HOLD leaves it to a human.
- Deleting old `clerk-patrol-*` markers.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- With a scratch executable `s` printing `FAIL x` and exiting 1, at an
  absolute path outside the checkout (the worktree is `origin/main`, which
  does not carry it):
  `JOHARNESS_PATROL_CMD=/abs/s ./joharness.sh patrol; echo "rc=$?"` —
  `patrol: 1 failing (<sha>)`, `FAIL x`, `rc=1`.
- `JOHARNESS_PATROL_CMD= ./joharness.sh patrol; echo "rc=$?"` — names the
  reason, `rc=2`.
- `./joharness.sh clerk` in this repo — `patrol    : none
  (JOHARNESS_PATROL_CMD empty)`.
- Mutation: drop the `timeout` wrapper in a scratch copy — the
  `patrol-timeout` assertion FAILs; drop the marker age test in
  `clerk_due` — the stale-marker assertion FAILs. Restore.
- SHIPS: `joharness.sh` and `.claude/commands/` reach consumers; the
  selftest does not (`.agents/scripts/sync-to-consumer.sh:CANONICAL_ONLY_DIRS`).
  Consumer-run checks: `./joharness.sh patrol` and `./joharness.sh clerk`;
  quote their output from the acceptance above in the PR body.

## Where to look

- `joharness.sh:conf_get` — single-token values.
- `joharness.sh:clerk_stamp_ts`, `joharness.sh:clerk_noop` — marker shape
  and parser.
- `joharness.sh:clerk_due` — in-flight and due readings; the dispatch block
  printing `clerk     :`.
- `joharness.sh:cmd_clerk` — what a clerk reads first.
- `joharness.sh:checks_unrun_jobs` — built by
  `local-checks-name-unrun-jobs`.
- `.agents/harness/selftest/knobs-declared.sh` — which registration each
  knob scope needs.
- `.agents/harness/selftest.sh:SELFTEST_TOPICS` — topic registration.
- `.claude/commands/clerk.md` — §1 (twin check, push), §2 batch and order,
  §3 the read-only rule and verdicts, §4 the noop record.

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
