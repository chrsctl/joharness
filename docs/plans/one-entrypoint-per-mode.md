---
plan: one-entrypoint-per-mode
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: joharness.sh, .claude/commands/start.md, .agents/harness/selftest/start.sh, .agents/harness/selftest.sh, .agents/harness/AGENTS.md
---

## Goal

Requester, 2026-09-06: "one command which starts depending on the loop
configured". Today a session or a human must know which role the repo's
mode calls for and type its command — `/drain` under supervised and
unsupervised, `/orchestrate` under orchestrated, `/manage <item>` if an
orchestrator named one. The mode is in `joharness.conf`, so the choice is
already decided by the repository; making a person carry it is how a
fleet gets an orchestrator where it wanted a manager, or a `/drain` in a
repo whose queue an orchestrator holds.

One command, and the routing lives in the shell where it can be tested:
`./joharness.sh start` prints the command file this repo's mode calls
for, and `/start` reads that file and follows it.

## Scope

- `joharness.sh` — new `start` subcommand. Reads `run_mode()` (the ONE
  resolver; never re-derive the mode) and prints, in this order:
  - the resolved mode and its source, the same two facts `authority`
    prints, so a session can see WHY it is being routed;
  - the one command file to follow, as a repo-relative path:
    `supervised` and `unsupervised` to `.claude/commands/drain.md`,
    `orchestrated` to `.claude/commands/orchestrate.md`;
  - nothing else. No queue read, no git, no fetch. This runs before a
    session knows anything, and it must be instant.
  Errors, both non-zero and both naming the fix: an argument (the two
  commands that take one are `/manage <item>` and `/plan`, and this is
  not either), and a routed file that does not exist in this checkout
  (an old consumer copy — say which file and that a harness sync brings
  it).
  Usage block gets its line, in the order the other subcommands are in.
- `.claude/commands/start.md` — new, and SHORT. Run
  `./joharness.sh start`, read the file it names WHOLE, follow it. State
  the one thing this command must never do: guess the role. Under
  orchestrated the role comes from the PROMPT — a prompt naming
  `/manage <item>` makes a manager, and shell cannot see a prompt — so
  a session whose prompt named an item follows `manage.md` and does not
  run this at all.
- `.agents/harness/selftest/start.sh` — new topic, registered in
  `.agents/harness/selftest.sh`. Cases below.
- `.agents/harness/AGENTS.md` — ONE line in step 2, where the three role
  commands are already named: not sure which? `/start` routes by mode.
  Caveman; the mapping is not repeated in prose, because a mapping
  spelled twice drifts.

## Out of scope

- Arguments. `start <path>` routing to `/manage <path>` reads helpful
  and hides the rule that matters: under orchestrated, the role is the
  orchestrator's to assign in the prompt it spawns with. A human who
  wants one item worked types `/manage <path>` and means it.
- Reading the queue, fetching, or printing what to work on. `drain` and
  `dispatch` do that, they cost git, and this command is the routing
  step before either.
- Running the routed command from the shell. A slash command is a prompt
  and the shell cannot invoke one; `start` names the file and the
  session reads it. That indirection is the point — one mapping, in one
  place, testable.
- Changing any existing command, or what any mode does. Nothing about
  `drain`, `orchestrate` or `manage` changes; this only chooses between
  them.
- A `perf` row. It forks nothing — no git, no hook — so there is no
  per-item loop to budget. Say so in the commit rather than adding a row
  that would measure zero.

## Acceptance

- `./joharness.sh start` in a supervised checkout names
  `.claude/commands/drain.md`; with `JOHARNESS_MODE=unsupervised` the
  same; with `JOHARNESS_MODE=orchestrated`,
  `.claude/commands/orchestrate.md`.
- An unrecognised mode routes to `drain.md`, because `run_mode()`
  normalises it to supervised — and the existing unrecognised-mode
  warning still prints.
- `./joharness.sh start x` exits non-zero and names `/manage` and
  `/plan` as the commands that take an argument.
- A checkout whose routed file is missing exits non-zero naming the
  file. Proved with a fixture that removes it, not by reasoning.
- `./joharness.sh mutate joharness.sh <the routing line>` reds at least
  one case, per mode arm.
- `./joharness.sh ci` — `ci: pass`.
- SHIPS: `joharness.sh`, `.claude/commands/start.md` and
  `.agents/harness/AGENTS.md` reach consumers at the next sync — and
  the two selftest files do NOT, because `sync-to-consumer.sh` holds
  `.agents/harness/selftest.sh` in `CANONICAL_ONLY` and
  `.agents/harness/selftest` in `CANONICAL_ONLY_DIRS`. `ci`'s own ship
  scope prints exactly those three. Consumer-side check: in a synced
  repo `./joharness.sh start` names the file that repo's own conf calls
  for — gx is orchestrated and must name `orchestrate.md`, this repo is
  supervised and must name `drain.md`, from identical code.

## Where to look

- `joharness.sh:run_mode` — the one resolver, and `mode_source` beside
  it. `authority` already prints both; read how before printing them a
  second way.
- `joharness.sh:cmd_mode` (the `mode)` arm) — the closest existing
  subcommand: takes no argument, says so when given one, and calls
  `mode_warn_unrecognised` first. Copy that shape.
- `.claude/commands/orchestrate.md` — its precondition 0 runs
  `authority` itself, which is why `start` must not: a check spelled in
  two files drifts, and the routed command owns its own preconditions.
- `.agents/harness/selftest/` — any topic file for the shape; the runner
  defines the helpers and the fixtures.

## Traps

- `run_mode()` or nothing. A `case` on `$JOHARNESS_MODE` here is the
  second resolver the file's own comment warns about, and it would miss
  the conf.
- The command file must not restate what `drain.md` or `orchestrate.md`
  say. It routes and hands off; a summary of the routed file is a copy
  that rots.
- A test written for this must FAIL without it — revert the arm, watch
  the case red.
- Caveman in AGENTS.md: one line, and never let the style eat the fact.
