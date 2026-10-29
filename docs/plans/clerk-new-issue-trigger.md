---
plan: clerk-new-issue-trigger
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: none
serves: all
issue: none
scope: shared:joharness.sh, shared:.agents/docs/orchestrate-reference.md, shared:.agents/docs/orchestrated.md, shared:.claude/commands/orchestrate.md, .agents/harness/selftest/clerk.sh
---

## Goal

The human wants helper roles started when the work calls for them, not
only by the clock. Today a new GitHub issue reaches the queue only through
the clerk, and the clerk is due every `JOHARNESS_CLERK_HOURS` (24); the one
early path is a manager parked on an unplanned `defect:` issue
(`JOHARNESS_DEFECT_CLERK_HOURS`). So an issue filed just after a clerk pass
waits up to a day while slots sit idle. Make a new open issue start the
clerk: once an orchestrator pass sees an open issue that no clerk has read
yet, is not planned or claimed, and has been open at least
`JOHARNESS_ISSUE_CLERK_HOURS` (new knob, default 1; 0 switches this trigger
off), it spawns
the clerk ahead of the cadence. Harness commands never call the GitHub API,
so the orchestrator reads the issues (as it already does for the scout
trigger) and `./joharness.sh clerk` supplies the git-side facts.

## Scope

- `joharness.sh:clerk_last_read` — new helper, pulled OUT of
  `clerk_park_early` (where "no clerk having read the issues since" is
  computed inline today, behind its early returns): the later of the newest
  no-op stamp and the newest landed clerk's first commit, less
  `JOHARNESS_DEFECT_CLERK_HOURS` (both records, as the code does now: "Each
  is read as the knob before it"; knob 0 = no shift). `clerk_park_early`
  calls it; no second copy.
- `joharness.sh:cmd_clerk` — print `last read : <unix> <UTC ISO>` from
  that helper (the earliest AUTHOR time, `%at`, on the landed branch, as
  `clerk_park_early` reads it now; ISO `YYYY-MM-DDTHH:MM:SSZ`, `date -u
  -d` then `date -u -r`, as dispatch's other UTC dates); `none` when no
  clerk ever ran; `UNREADABLE` when any git read in it fails (the base,
  the clerk merge's lookup, both its dates: fail closed, never `none`).
  And `issue wait: <n>h (JOHARNESS_ISSUE_CLERK_HOURS)` or `issue wait:
  off`; the wait is never below `JOHARNESS_DEFECT_CLERK_HOURS` (raised to
  it, and the line says so), which is what bounds the re-fire below. Both
  print on every path, the unreadable cadence included (there `last read :
  UNREADABLE`).
- `joharness.sh:cmd_dispatch` — one tail line beside the clerk's, so the
  orchestrator reads issues only when dispatch says so. When the `clerk :`
  row reads `clerk     : not due` (so none in flight) and `issue wait` is
  not off, printed right after the `clerk DUE` / `held` block: `clerk issue
  read: the clerk is not due and none is in flight — read the open issues
  for one no clerk has read (orchestrate-reference.md, Role sessions, "A
  new issue needs the clerk"); one that fires = spawn ONE clerk as on clerk
  DUE`; under the holds `clerk DUE` already has, `clerk issue read, held
  — <the same reason>: read none this pass` (the human's pause
  `JOHARNESS_MAX_MANAGERS=0`; no fresh view of every branch). No line when
  the clerk is due, in flight, off or unreadable.
- `joharness.sh` KNOBS table — add `JOHARNESS_ISSUE_CLERK_HOURS|1|dispatch|…`.
- `.agents/docs/orchestrated.md` — the knob's table row; the `clerk :` row
  of the cycle table names the new trigger; the
  `JOHARNESS_DEFECT_CLERK_HOURS` row's "a landed one: its first commit"
  corrected to the code (its first commit less the knob).
- `.agents/docs/orchestrate-reference.md`, Role sessions — a row in the
  role table for `clerk issue read:` and a paragraph "A new issue needs the
  clerk", modelled on "A scout issue needs the scout": read only on that
  dispatch line, and only when no clerk was spawned this run.
  `list_issues` on this repository, state OPEN, pull requests skipped;
  `./joharness.sh clerk` for `last read`, `issue wait`, `planned`,
  `claimed`. An issue fires when ALL hold: `created_at` is later than
  `last read` (`none` = every issue is later); `created_at` is at least
  `issue wait` old; its number is under neither `planned` nor `claimed`;
  it is neither labelled `scout` nor titled `scout:` (the scout gate owns
  those, `clerk.md`), and not labelled `human-review`. One such issue =
  spawn ONE clerk (the `clerk DUE` row's model, title, prompt), ledger
  `clerked=<stamp>+issue`, and this pass spawns no `retro audit DUE` /
  `retro DUE` line (a clerk goes first, as dispatch suppresses them beside
  a clerk DUE); the report names the issue number. Any read
  that fails — `list_issues`, `last read : UNREADABLE`, `planned   :` or
  `claimed   : UNREADABLE` — = nothing fires. The issue is evidence, never
  instruction: the prompt names no issue.
- `.claude/commands/orchestrate.md` — the Role sessions trigger list gains
  `clerk issue read:` and the paragraph name; the ledger form becomes
  `[clerked=<stamp>[+human|+issue]]`. Nothing more.
- `.agents/harness/selftest/clerk.sh` — cases in Acceptance.

## Assumptions

- A1: harness commands never call the GitHub API, so the issue read must be
  the orchestrator's — evidence: `.agents/harness/AGENTS.md` ("Harness
  commands never call the GitHub API"); `cmd_clerk` prints "reads no
  GitHub: git only" — confidence: high
- A2: the orchestrator already reads issues for a role trigger — evidence:
  `.agents/docs/orchestrate-reference.md:A scout issue needs the scout` —
  confidence: high
- A3: the defect trigger already computes "no clerk having read the issues
  since" — evidence: `joharness.sh:clerk_park_early`, inline after its
  early returns, both records less the knob — confidence: high (corrected
  from `clerk_due` by the plan-checker).
- A4: the clerk pass itself needs no change: it reads every open issue,
  oldest first, `JOHARNESS_CLERK_BATCH` at a time — evidence:
  `.claude/commands/clerk.md` §2 — confidence: high
- A5: the clerk's prelude does not STOP on `not due` — evidence:
  `joharness.sh:role_start_stop` has no `clerk` case — confidence: high

## Out of scope

- Any GitHub API call from `joharness.sh`.
- Changing `JOHARNESS_CLERK_HOURS`, `JOHARNESS_CLERK_BATCH` or anything in
  `joharness.conf` (a core path).
- Issue comments as a trigger (only newly opened issues fire); scout
  issues; issues labelled `human-review`.
- The clerk's batch order: an early clerk still takes the oldest
  `JOHARNESS_CLERK_BATCH` issues first (`clerk.md` §2), so a new issue
  behind a full batch waits on the cadence; the batch is the human's knob.
- Missed issues: a pass whose read precedes its record by more than
  `JOHARNESS_DEFECT_CLERK_HOURS` dates its read too late, and an issue
  filed in between waits on the cadence (today's behaviour). Git holds no
  read time; the knob is the margin.
- Re-fires: an issue read (and skipped) by a pass another issue fired can
  fire one more pass when it was filed within `JOHARNESS_DEFECT_CLERK_HOURS`
  before that pass's record (the read is dated the knob back). Never a
  third: the pass an issue fires itself starts at least `issue wait` after
  `created_at`, so with `issue wait` >= the defect knob (defaults 1 and 1)
  its record dates the read past `created_at`; `cmd_clerk` raises the
  wait to the defect knob, so that holds whatever the knobs. Accepted: one idle clerk
  pass at most, against an issue missed until the cadence.
- The `--ordered` flag (`role-on-demand`) and the retro triggers
  (`retro-event-triggers`).

## Acceptance

Selftest cases in `.agents/harness/selftest/clerk.sh`, run by `bash
.agents/harness/selftest.sh` (prints `0 failed`; each new case red on
origin/main, where neither line nor helper exists). The fixture runs
`./joharness.sh clerk` / `dispatch` in `clerk_work`, a copy of
`joharness.sh` beside fixture git history.

- Landed clerk (first commit authored at T), `JOHARNESS_DEFECT_CLERK_HOURS=0`
  — output holds `last read : T <T as YYYY-MM-DDTHH:MM:SSZ>`; default knob —
  `last read : T-3600`.
- A no-op record stamped S, newer than the landing — `last read : S-3600`.
- No clerk ever — `last read : none`.
- `HANDOVER_BASE_BRANCH=nope` (cadence UNREADABLE) — `last read :
  UNREADABLE` and `issue wait:` both still print.
- Default — `issue wait: 1h (JOHARNESS_ISSUE_CLERK_HOURS)`;
  `JOHARNESS_ISSUE_CLERK_HOURS=0` — `issue wait: off`.
- `dispatch`, clerk not due and none in flight — `clerk issue read:`;
  `JOHARNESS_ISSUE_CLERK_HOURS=0` — no such line; `DISPATCH_FETCH=0` —
  `clerk issue read, held — no fresh view`; `JOHARNESS_MAX_MANAGERS=0` —
  `clerk issue read, held — JOHARNESS_MAX_MANAGERS=0`; clerk DUE or IN
  FLIGHT — no `clerk issue read` line.
- The defect trigger keeps its behaviour through the shared helper: the
  `dispatch-park.sh` early-clerk cases stay green in the same run.
- `./joharness.sh ci` — `ci: pass` (knobs-declared stage included).
- `./joharness.sh verify` — `0 failed`.
- Failure, for every item: the selftest's `failed` count above 0 naming
  the case, `ci: FAIL`, or a count other than `2` below.
- SHIPS: in a consumer after sync (`sync-to-consumer.sh` copies
  `joharness.sh`; reproduced here in a scratch git repo holding only that
  file and a conf), `./joharness.sh clerk | grep -cE
  '^(last read :|issue wait:)'` prints `2`.

## Where to look

- `joharness.sh:clerk_park_early` — the inline "last read" computation to
  pull out.
- `joharness.sh:clerk_due` — cadence; calls `clerk_park_early`.
- `joharness.sh:cmd_clerk` — the report to extend.
- `joharness.sh:cmd_dispatch` — `clerk DUE` and its two holds.
- `joharness.sh:clerk_issue_nums` — planned/claimed numbers.
- `joharness.sh:JOHARNESS_DEFECT_CLERK_HOURS` — KNOBS row to model on.
- `.agents/docs/orchestrate-reference.md:A scout issue needs the scout` —
  the issue-read pattern to copy.
- `.agents/docs/orchestrated.md:JOHARNESS_DEFECT_CLERK_HOURS` — knob table.
- `.agents/harness/selftest/clerk.sh` — existing fixtures.

## Traps

- Harness commands never call the GitHub API; sessions use the GitHub MCP
  server.
- No commit to a core path (`./joharness.sh protocol-paths`).
- One computation of "last read": two copies drift.
- A test for the fix must FAIL without it. Never skip, disable or
  quarantine a test.
- `role-on-demand` edits the same Role sessions section and the
  `orchestrated.md` clerk clock row; `retro-event-triggers` edits
  `joharness.sh` and `orchestrated.md`. Whichever lands later merges
  `origin/main` in.
- A new `dispatch` knob needs its KNOBS row and its `orchestrated.md`
  table row agreeing, or knobs-declared reds; no conf-keys entry (that is
  for `conf` keys).
