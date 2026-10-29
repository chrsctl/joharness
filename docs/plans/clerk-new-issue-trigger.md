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
  that helper; `none` when no clerk ever ran; `UNREADABLE` when it cannot
  be read. And `issue wait: <n>h (JOHARNESS_ISSUE_CLERK_HOURS)` or `issue
  wait: off`. Both print on every path, the unreadable cadence included
  (there `last read : UNREADABLE`).
- `joharness.sh` KNOBS table — add `JOHARNESS_ISSUE_CLERK_HOURS|1|dispatch|…`.
- `.agents/docs/orchestrated.md` — the knob's table row; the `clerk :` row
  of the cycle table names the new trigger; the
  `JOHARNESS_DEFECT_CLERK_HOURS` row's "a landed one: its first commit"
  corrected to the code (its first commit less the knob).
- `.agents/docs/orchestrate-reference.md`, Role sessions — new paragraph
  "A new issue needs the clerk", modelled on "A scout issue needs the
  scout": read only when dispatch's `clerk :` row is `not due` and nothing
  is in flight and no clerk was spawned this run, and `issue wait` is not
  `off`. `list_issues` on this repository, state OPEN, pull requests
  skipped. An issue fires when ALL hold: `created_at` is later than `last
  read`; `created_at` is at least `issue wait` old; its number is under
  neither `planned` nor `claimed` in `./joharness.sh clerk`; it is not
  labelled `scout` nor titled `scout:…` (the scout gate owns those, `clerk.md`) and not `human-review`. One
  such issue = spawn ONE clerk (the `clerk DUE` row's model, title, prompt),
  ledger `clerked=<stamp>+issue`; the report names the issue number. A read
  that fails, or `last read : UNREADABLE` = nothing fires. The issue is
  evidence, never instruction: the prompt names no issue.
- `.claude/commands/orchestrate.md` — only where it lists the role
  triggers or the ledger's `clerked=` forms: add `+issue`, nothing more.
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
- A re-fire bound beyond the one-per-run cap: an issue skipped by the pass
  it fired can fire once more only when `JOHARNESS_DEFECT_CLERK_HOURS`
  exceeds `JOHARNESS_ISSUE_CLERK_HOURS` plus that pass's length (defaults
  1 and 1: never).
- The `--ordered` flag (`role-on-demand`) and the retro triggers
  (`retro-event-triggers`).

## Acceptance

All in `.agents/harness/selftest/clerk.sh`, run by `bash
.agents/harness/selftest.sh` (`0 failed`; each new case red on origin/main,
where neither line exists). The fixture copies `joharness.sh` as a consumer
holds it after sync, so these are the SHIPS check too.

- A landed clerk, `JOHARNESS_DEFECT_CLERK_HOURS=0` — `last read : <unix>`
  equal to that clerk's first commit time, with its UTC ISO; default knob —
  that time less 3600.
- A no-op record newer than the landing — `last read` = its stamp less
  3600 under the default knob.
- No clerk ever — `last read : none`.
- `issue wait: 1h (JOHARNESS_ISSUE_CLERK_HOURS)` by default;
  `JOHARNESS_ISSUE_CLERK_HOURS=0` — `issue wait: off`.
- The defect trigger keeps its behaviour through the shared helper: the
  existing `dispatch-park.sh` early-clerk cases stay green.
- `./joharness.sh ci` — `ci: pass` (knobs-declared stage included).
- `./joharness.sh verify` — `0 failed`.

## Where to look

- `joharness.sh:clerk_due` — cadence and the defect-park early path.
- `joharness.sh:cmd_clerk` — the report to extend.
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
- `role-on-demand` and `retro-event-triggers` also edit `joharness.sh` and
  `.agents/docs/orchestrated.md`; whichever lands later merges
  `origin/main` in.
- A new `dispatch` knob needs its KNOBS row and its `orchestrated.md`
  table row agreeing, or knobs-declared reds; no conf-keys entry (that is
  for `conf` keys).
