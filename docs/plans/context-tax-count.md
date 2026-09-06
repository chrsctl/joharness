---
plan: context-tax-count
urgency: normal
agent: sonnet
effort: xhigh
needs: none
requirement: none
scope: joharness.sh, .agents/harness/selftest.sh, .agents/harness/selftest, .agents/docs/caveman.md, .agents/docs/agent-selection.md
---

## Goal

Human asked whether managers must run opus, and for token usage to be
optimised. The tier half is answered and needs no code. The cost half has
no number anywhere: `.agents/harness/AGENTS.md` opens by citing ETH
AGENTbench for "long context file hurt agent, cost more", and
`.agents/docs/caveman.md` says instruction files "load every session; every
word is paid repeatedly" — and nothing in the repo counts what that comes
to, or what a branch adds to it. Counted 2026-09-06, the file grew 770
words (2026-08-23) to 2129 (today), 2.8x in 14 days, while every session in
every mode at every tier loaded it. Count it where sessions already look,
and print what THIS branch adds, so a cut has a baseline and growth is a
visible act rather than an invisible one.

## Scope

- `joharness.sh` — `ctx_imports`, `ctx_bytes`, `cmd_context`, and a
  `== context` stage in `cmd_ci`. The stage counts the instruction chain
  and the branch delta. The subcommand adds the `session-start` injection
  for this repo's mode.
- `.agents/harness/selftest/ci-context.sh` — new topic, asserting exact
  counts on a scratch fixture: chain resolved through `@` imports, a
  branch's delta, the mode line, cycle safety.
- `.agents/harness/selftest.sh` — register the topic in the list.
- `.agents/docs/caveman.md` — under "Where it applies", what the tax is,
  how it is counted, why it reports and never gates.
- `.agents/docs/agent-selection.md` — ONE cross-reference line: under
  orchestrated mode a manager runs its item's tier, the role picks none.
  A pointer to `.agents/docs/orchestrated.md` Roles, never a second
  spelling of it.

## Out of scope

- Cutting `.agents/harness/AGENTS.md`, or any other instruction file. That
  is content judgement over protocol text and wants its own review with
  this counter's baseline already on `main`. Handed to the queue as
  `docs/plans/harness-agents-cut.md`.
- A budget, a threshold, a warn tier, or any gate. `scorecard` states the
  doctrine this follows: report first, and a count earns a ceiling on a
  backtest, the way `churn` did. A gate on prose size fires on the honest
  rule addition, and buys deleted rules.
- Adding a line to `.agents/harness/AGENTS.md` announcing the command. It
  would grow the number the command measures; `ci` prints it, which is
  where a session already reads.
- Running `session-start` inside `ci`. Measured 2026-09-06: `session-start`
  3.5s against `ci` 14.7s, so folding it in costs `ci` 24% for a number
  that the standalone command already gives and a diff rarely moves.
- Token counts. Bytes and words are counted; tokens would be estimated, and
  the repo's rule is to trust counted numbers only.

## Acceptance

- `./joharness.sh context` — prints one row per file in the chain, an
  `instructions` subtotal, a `session-start (<mode>)` row, a `total`, and a
  delta line against `origin/main`. Exit 0.
- `./joharness.sh ci` — prints a `== context` section carrying the
  `instructions` subtotal and the delta line, and no `session-start` row.
  Exit code unchanged by the stage on a clean branch.
- `.agents/harness/selftest.sh` — 0 failed, and the new topic's cases run.
- `./joharness.sh ci` — pass.
- `./joharness.sh verify` — 0 failed.
- Plan `ci` calls SHIPS, and only for part of the diff: `joharness.sh` is in
  the sync engine's `FILES`, `.agents/docs` in its `DIRS`, while
  `.agents/harness/selftest.sh` is `CANONICAL_ONLY` and
  `.agents/harness/selftest` is `CANONICAL_ONLY_DIRS` — the suite stays here
  (`.agents/scripts/sync-to-consumer.sh`). So the consumer bar is the two
  commands that do ship: `./joharness.sh context` prints a chain and
  `./joharness.sh ci` prints the stage, in the consumer fixture
  `.agents/harness/selftest/bootstrap-consumer.sh` builds.

## Where to look

- `joharness.sh:cmd_ci` — the stage registers beside `churn`, which is the
  nearest precedent for a counted number printed where sessions look.
- `joharness.sh:perf_report` — a counted number with a budget; read for the
  wording it uses when a number moves, not for a budget to copy.
- `joharness.sh:num_knob` — how a knob reads the environment, then
  `joharness.conf`, then a default. Nothing here needs one yet.
- `.agents/harness/selftest/ci-churn.sh` — the scratch-repo fixture shape a
  `ci` stage topic uses.
- `.agents/docs/caveman.md` — "Where it applies" owns the claim this counts.

## Traps

- Part 2: the harness layer names no specific environment. The chain walker
  follows `@` imports and reads the SELECTED layer from configuration; a
  literal `docker` anywhere in it is the carve-out violation the selftest
  exists to red.
- Protocol path in `scope:` — this plan is SUPERVISED ONLY by construction,
  and declared so rather than hidden.
- A number nobody can re-count is a written number: every count the stage
  prints comes from the tree at read time, and the selftest asserts the
  arithmetic on a fixture rather than on this repo.
