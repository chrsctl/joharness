---
plan: ci-only-suite-patrol
urgency: normal
agent: opus
effort: high
needs: local-checks-name-unrun-jobs
requirement: none
issue: none
scope: joharness.sh, .agents/harness/selftest/patrol.sh, .agents/harness/selftest/knobs-declared.sh, .claude/commands/patrol.md, .claude/commands/orchestrate.md, .agents/docs/orchestrated.md, .agents/harness/AGENTS.md, .agents/docs/consumer-repos.md
---

## Goal

Under `JOHARNESS_CHECKS=local` the harness has a fixing half for broken
suites (issue -> clerk -> plan -> manager) and no capturing half: a job only
GitHub ran is run by nobody, so its regressions never become an issue
(`.agents/docs/consumer-repos.md`, "Local checks"). Add the capturing half:
a consumer declares ONE command that runs its CI-only suites; a clock-driven
role, the patrol, runs it on fresh `origin/main` and files one GitHub issue
per newly failing criterion. The clerk turns those into plans as it does any
issue. Once a day, not per merge: one consumer's suites measured about 35
minutes sequentially in a cloud container, too dear for every `finish`.

## Scope

- `joharness.sh` knobs (the `JOHARNESS_*|default|kind|help` table):
  - `JOHARNESS_PATROL_CMD||conf|` — one shell command, run from the
    checkout root; empty = patrol off. Exit 0 = green. Each stdout line
    `FAIL <id>` names one failing criterion (`<id>` = no whitespace, the
    consumer's own test or criterion name). Non-zero exit with no `FAIL`
    line = one failure with id `patrol-command`.
  - `JOHARNESS_PATROL_HOURS|24|dispatch|` — hours between patrol passes;
    0 = off.
  - `JOHARNESS_PATROL_MINUTES|90|session|` — `timeout` bound on the
    command; hitting it = one failure with id `patrol-timeout`.
- `joharness.sh` new subcommand `patrol` (usage line in the header
  comment): fetch `origin/main`, `git worktree add --detach` it under a
  temp directory, run the command there under `timeout`, remove the
  worktree, print `patrol: green (<short sha>)` or `patrol: <n> failing
  (<short sha>)` followed by one `FAIL <id>` line each. Report-only: no
  issue, no push. Exit 0 green, 1 failing, 2 off or unrunnable (no
  command, no `timeout`, fetch failed) with the reason.
- `joharness.sh` dispatch: a `patrol    :` line beside `clerk`/`conduct`
  — `off — <reason>` (no command, or hours 0), `IN FLIGHT`, `DUE — <n>h
  since the last patrol (of <hours>h)`, `not due — …`. The clock reads a
  `patrol-<YYYYMMDDTHHMMSSZ>` branch at the base head that the role pushes
  each pass, the same marker shape and parser as `clerk-noop-<stamp>`
  (`clerk_stamp_ts`). With the command empty AND `checks_unrun_jobs`
  printing rows under `JOHARNESS_CHECKS=local`, the off reason is
  `off — N workflow job(s) run nowhere and JOHARNESS_PATROL_CMD is empty`.
- `.claude/commands/patrol.md` — the role: run `./joharness.sh patrol`;
  for each `FAIL <id>`, search open issues for `patrol: <id>` in the
  title; none = file one, title `patrol: <id> fails on main`, body = the
  sha, the command, and the last 40 lines of output for that id where the
  output names it; an open one = add nothing. Then push
  `patrol-<stamp>` at the fetched base head and exit. Opens no pull
  request, writes no plan, edits no file.
- `.claude/commands/orchestrate.md` — role table row: `patrol DUE` | sonnet
  | `patrol: <UTC date>` | `/patrol` | `patrolled=<stamp>`; the ledger
  line gains `[patrolled=<stamp>[+human]]`. Holds no slot, like conduct.
- `.agents/docs/orchestrated.md` — the patrol among the clock-driven roles,
  wherever clerk and conduct are listed together.
- `.agents/harness/selftest/patrol.sh` — new topic: a fixture command
  printing `FAIL a` and exiting 1 gives `patrol: 1 failing` and exit 1; a
  green command gives exit 0; a command sleeping past a 1-minute bound
  (`JOHARNESS_PATROL_MINUTES=1` with a fixture `timeout` shim, so the topic
  does not wait a minute) gives `FAIL patrol-timeout`; empty command gives
  exit 2; dispatch prints `patrol    : off` with the run-nowhere reason in
  a fixture repo with a `make crm` workflow job and local mode.
- `.agents/harness/selftest/knobs-declared.sh` — only if it lists knobs by
  hand; read it first.
- `.agents/harness/AGENTS.md` step 7 first bullet — local mode: jobs that
  run nowhere at `finish` are the patrol's (`JOHARNESS_PATROL_CMD`).
- `.agents/docs/consumer-repos.md` "Local checks" — rewrite to the new
  status quo: the second status-quo bullet becomes the patrol, the last
  paragraph names the knob and drops both plan paths.

## Out of scope

- Running the command from `finish`, per merge. Rejected in Goal (cost).
- Mapping diff paths to suites. Same reason; the patrol reads the base.
- Provisioning a database, browser or any service: the consumer's command
  provisions what it needs. `.agents/harness/` names no environment.
- Setting the knob in this repo's `joharness.conf` (core path, and this
  repo has no CI-only suite). The key stays declared in the knob table and
  unset.
- Writing plans from a failure: the clerk plans issues; no session writes a
  plan from a detector (`.agents/docs/plans/README.md`, Lifecycle).
- Closing issues when a criterion turns green again. The fixing manager's
  pull request closes its issue.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- `JOHARNESS_PATROL_CMD='printf "FAIL x\n"; exit 1' ./joharness.sh patrol;
  echo "rc=$?"` — prints `patrol: 1 failing (<sha>)`, `FAIL x`, `rc=1`.
- `JOHARNESS_PATROL_CMD=true ./joharness.sh patrol; echo "rc=$?"` —
  `patrol: green (<sha>)`, `rc=0`; `git worktree list` afterwards shows no
  patrol worktree.
- `./joharness.sh dispatch` in this repo — a `patrol    : off —` line.
- Mutation: drop the `timeout` wrapper in a scratch copy — the selftest's
  `patrol-timeout` assertion FAILs. Restore.
- Plan `ci` calls SHIPS: the new selftest topic runs in every consumer's
  `ci`.

## Where to look

- `joharness.sh:clerk_stamp_ts` and the `clerk-noop-` marker reader near
  it — the marker and clock to copy.
- `joharness.sh:clerk_due`, `joharness.sh:conduct_due` — due/off/in-flight
  shapes; the dispatch block printing `clerk     :` and `conduct   :`.
- `joharness.sh:checks_unrun_jobs` — built by
  `local-checks-name-unrun-jobs`; read for the off reason.
- `.claude/commands/orchestrate.md` — the role table (`| line | model
  (Lineup) |`) and the ledger line.
- `.claude/commands/clerk.md` — how a clerk reads issues; the patrol's
  issues must be readable there with no clerk change.

## Traps

- `.agents/harness/` names no specific environment, and no consumer is named
  in harness text (`.agents/docs/consumer-repos.md`, "Name no consumer").
- Never commit to a core path: `joharness.conf`, `.claude/settings.json`,
  `.github` (`./joharness.sh protocol-paths`).
- Background or bounded command must be able to finish: the `timeout`
  bound is the point, not a nicety.
- Never `git push --delete` old `patrol-*` markers: branch deletion is
  human-only.
- Edits the same step-7 bullet and "Local checks" section as
  `local-checks-name-unrun-jobs`; it lands first (`needs`).
- NEVER skip, disable or quarantine a test to get green.
