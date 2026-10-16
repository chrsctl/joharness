---
plan: ci-only-suite-patrol
urgency: normal
agent: opus
effort: high
needs: local-checks-name-unrun-jobs
requirement: none
issue: none
scope: joharness.sh, .agents/harness/selftest/patrol.sh, .agents/harness/selftest.sh, .agents/scripts/conf-keys.sh, .agents/scripts/bootstrap-consumer.sh, .claude/commands/clerk.md, .agents/docs/orchestrated.md, .agents/harness/AGENTS.md, .agents/docs/consumer-repos.md
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
pass through its usual §2/§3, with this run's output as the reading. No
new role, command file, ledger key or role-table row; the one change to
what dispatch reads is a marker that keeps a patrolling clerk IN FLIGHT.
The plan comes from an issue verified in §3, so "no session writes a plan
from a detector" (`.agents/docs/plans/README.md`, Lifecycle) still holds:
the detector files the issue, the clerk plans it. On a clock, not
per merge: such suites cost the consumer's whole suite runtime, paid once a
clerk cycle instead of at every `finish`.

## Scope

- `joharness.sh` knob table (`KEY|default|scope|meaning`), plus each knob's
  registration (`.agents/harness/selftest/knobs-declared.sh` reds
  otherwise): `conf` keys in `.agents/scripts/conf-keys.sh`, `dispatch`
  keys as a row in `.agents/docs/orchestrated.md`'s knob table; a new
  `conf-keys.sh` key also goes in the conf the bootstrap seeds
  (`.agents/scripts/bootstrap-consumer.sh` heredoc;
  `.agents/harness/selftest/bootstrap-consumer.sh`, "conf keys match the
  declaration", reds otherwise):
  - `JOHARNESS_PATROL_CMD||conf|` — a path, relative to the worktree root
    or absolute, to ONE executable taking no arguments; empty = no patrol.
    A single token, as every conf value is (`joharness.sh:conf_get` stops
    at the first blank or `#`): a consumer wraps its suites in a script.
    Protocol: only stdout lines matching `^PATROL FAIL [^[:space:]]+$`
    count, each naming one failing criterion (the prefix keeps suite output
    such as a test runner's own `FAIL` lines out). Any such line = failing,
    whatever the exit code. Non-zero exit with none = one failure, id
    `patrol-command`. Exit 0 with none = green.
  - `JOHARNESS_PATROL_MINUTES|90|dispatch|` — `timeout` bound on the
    executable; hitting it = one failure, id `patrol-timeout`. Range 1 to
    100: 0 or above 100 = `patrol` exits 2 naming the range (GNU `timeout
    0` disables the bound; above 100 the clerk's background Bash call,
    capped at 120 min, cannot outlive it). The in-flight window is this
    plus 30 minutes (fetch, issue filing, §2-§3 before the clerk's first
    push).
- `joharness.sh` subcommand `patrol` (header usage line): fetch
  `origin/main`; `git worktree add --detach` it under a `mktemp -d`
  directory; run the executable there under `timeout`; remove the worktree
  on every exit path (`trap`); print `patrol: green (<short sha>)` or
  `patrol: <n> failing (<short sha>)`, then one `FAIL <id>` line each.
  Report-only: no issue, no push. Exit 0 green, 1 failing, 2 no patrol or
  unrunnable (no command, not executable, no `timeout`, fetch failed) with
  the reason. The runs that FINISHED are exit 0 and exit 1 without
  `patrol-timeout` or `patrol-command`; `patrol` prints `complete: yes|no`
  as its last line so the clerk reads which.
- `joharness.sh:clerk_due` (and the dispatch `clerk     :` line it feeds) —
  a clerk running a patrol pushes nothing for up to
  the in-flight window, so it must not read as no clerk at all. A
  `clerk-patrol-<YYYYMMDDTHHMMSSZ>` branch (parsed with
  `joharness.sh:clerk_stamp_ts`) aged 0 to the window reads `IN FLIGHT`, as
  an unmerged `clerk-<digit>` branch does today. A stamp more than 5 minutes
  in the future is ignored, as `clerk_noop` and `clerk_walk` ignore one
  ("either side of now"). The marker sits at `origin/main`, merged by
  construction, so `clerk_walk`'s `--no-merged` walk never sees it: read it
  separately, the way `clerk_noop` reads its records. A live marker and a
  `clerk-<digit>` branch together are ONE clerk: one slot in `n_clerk`,
  never two. The marker never dates the clock: only the merge or the
  `clerk-noop-` record does.
  With `JOHARNESS_CHECKS=local`, `JOHARNESS_PATROL_CMD` empty and
  `checks_unrun_jobs 0` printing N > 0 rows, the clerk line carries one
  more clause: `no patrol: N workflow job(s) with a step not run here and
  JOHARNESS_PATROL_CMD is empty`.
- `.claude/commands/clerk.md` — new section between §1 Branch and §2 Read,
  `## 1b. Patrol`, skipped when `./joharness.sh clerk` prints `patrol    :
  none`:
  1. Push the marker: `git fetch origin main && git push origin
     "origin/main:refs/heads/clerk-patrol-$(date -u +%Y%m%dT%H%M%SZ)"`;
     rejected because the name exists = run it again (new second).
  2. Twin guard: list `clerk-patrol-*` markers inside the window. Yours is
     not the oldest by name = another clerk patrols: report `patrol:
     deferred to <marker>`, skip to §2.
  3. Run `./joharness.sh patrol` in the Bash tool's background mode with a
     Bash timeout of `JOHARNESS_PATROL_MINUTES` + 10 minutes (a foreground
     call caps at 600 s) and wait for its completion notice. It is the one
     command the clerk runs without reading it whole, and the section says
     why honestly: the executable is code on `origin/main`, merged through
     the same gate as every suite a manager runs, run in a throwaway
     worktree; the conf key naming it is human-set. Never set the key in
     the environment for a pass.
  4. Exit 2 = report the reason, go to §2. For each id: search open issues
     for title `patrol: <id> fails on main` and `git grep` the id across
     `docs/plans/` on `origin/main` and every unmerged branch
     (`.agents/docs/plans/README.md`, "What identifies a plan"); either
     found = add nothing; none = file it, body = the sha, the command, the
     last 40 output lines.
  5. In §2, open `patrol:` issues whose id failed in THIS run go first,
     inside `JOHARNESS_CLERK_BATCH`, and every §2 skip applies to them
     unchanged (PLANNED, CLAIMED, `human-review`, own verdict newest). In
     §3 the reading of such an issue is this run's output: HOLDS, plan
     `issue: <N>`. An open `patrol:` issue whose id did not fail gets NO
     verdict from the patrol, finished run or not: its fixing pull request
     closes it, a human closes the rest. Never re-run a different or
     weaker suite as the reading of a `patrol:` issue.
  The clerk's §4 (pull request or `clerk-noop-` record) is unchanged.
- `.claude/commands/clerk.md` `## Never` — a fourth carve-out: opening a
  `patrol:` issue in §1b step 4.
- `joharness.sh:cmd_clerk` — print `patrol    : <command>` or `patrol    :
  none (JOHARNESS_PATROL_CMD empty)` so §1b reads it without opening conf.
- `.agents/docs/orchestrated.md` — wherever the clerk's cycle is described,
  one sentence: a clerk pass runs the patrol first when the command is set;
  the two knob rows above.
- `.agents/harness/selftest/patrol.sh` — new topic, listed in
  `.agents/harness/selftest.sh:SELFTEST_TOPICS`. Fixtures: an executable
  printing `PATROL FAIL a`, exit 1 -> `patrol: 1 failing`, exit 1; one exiting 0
  -> exit 0, and `git worktree list` shows no patrol worktree after; one
  sleeping past the bound -> `FAIL patrol-timeout` (a fixture `timeout`
  shim on `PATH`, so the topic waits no minute); empty command -> exit 2; a
  conf fixture line `JOHARNESS_PATROL_CMD=scripts/ci-only.sh` reads back
  whole; a bare `FAIL x` stdout line is not counted;
  `JOHARNESS_PATROL_MINUTES=0` -> exit 2; dispatch with a fresh
  `clerk-patrol-` marker -> clerk `IN FLIGHT`, with a stale one -> not,
  with a far-future one -> not; a live marker plus a `clerk-<digit>` branch
  -> one clerk slot; local mode with a `make slow-suite`
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
- With a scratch executable `s` printing `PATROL FAIL x` and exiting 1, at an
  absolute path outside the checkout (the worktree is `origin/main`, which
  does not carry it):
  `JOHARNESS_PATROL_CMD=/abs/s ./joharness.sh patrol; echo "rc=$?"` —
  `patrol: 1 failing (<sha>)`, `FAIL x`, `complete: yes`, `rc=1`.
- `JOHARNESS_PATROL_CMD= ./joharness.sh patrol; echo "rc=$?"` — names the
  reason, `rc=2`.
- `./joharness.sh clerk` in this repo — `patrol    : none
  (JOHARNESS_PATROL_CMD empty)`.
- Mutation: drop the `timeout` wrapper in a scratch copy — the
  `patrol-timeout` assertion FAILs; drop the marker age test in
  `clerk_due` — the stale-marker assertion FAILs. Restore.
- The selftest's git exec count stays under `JOHARNESS_SELFTEST_GIT_BUDGET`;
  over it = measure and raise per `joharness.sh` (the budget's own comment),
  never by guess.
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
- `.claude/commands/clerk.md` — §1 (twin check, push), §2 batch, order and
  skips, §3 the read-only rule and verdicts, §4 the noop record, `## Never`.
- `joharness.sh:clerk_walk` — "either side of now", `--no-merged`; the
  `n_clerk` slot count in dispatch.
- `.agents/scripts/bootstrap-consumer.sh` — the seeded conf heredoc.

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
