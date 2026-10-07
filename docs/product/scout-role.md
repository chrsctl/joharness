---
requirement: scout-role
priority: normal
---

## Goal

The fleet burns tokens executing and never spends one on finding what it
could do better. Measured 2026-10-07 (Evidence below): the `chrsctl/gx`
orchestrator at $710 lifetime, 1.21B cache-read tokens, a 412K-token
context re-read every pass; run 3 at ~$128 per merged edge; the Lineup
still naming `claude-haiku-4-5` / `claude-sonnet-5` / `claude-opus-5`
while 5.5 and Fable 5.1 are served at lower or equal price — and no
session could have surfaced any of that, because nothing in the harness
is allowed to invent work. Want: a `fable` tier and a role that uses it
to RESEARCH new capacities — model releases, API features, what merged
edges and the scorecard say about the harness itself — and PROPOSE them.
Proposals, not
work: a proposal becomes queue work only when a human merges it, unless
the human has said in conf that the scout may merge its own.

## Satisfied when

- `.agents/docs/agent-selection.md` Lineup carries a fourth tier `fable`
  (`claude-fable-5-1`), and `agent: fable` passes the plan, research and
  workstream lints. Bound to judgement roles — planning manager for an
  unplanned requirement, review-churn research step, scout — never a
  build; the doc says why.
- A `scout` role exists with the shape of `curate` and `janitor`: a
  `scout : DUE` tail line from `dispatch` AND `drain`, cadence
  `JOHARNESS_SCOUT_HOURS` dated from git (the last merged or closed
  `proposal:` pull request), fires only at DRAINED, ONE session beyond the
  cap, at most one in flight, tier fable. `0` switches it off.
- A scout reads evidence and writes ONE `docs/product/<proposal>.md` as a
  pull request titled `proposal: <stem>`, each proposal citing what it rests
  on — `./joharness.sh upstream`, `scorecard`, review churn, feedback
  graduations, open issues on the canonical, the control plane's cost
  reader (`get_session`: `usage.cost_usd`, which `orchestrated.md` Runs
  already counts with, and the same record's `usage.cache_read_tokens`
  and `context_usage.used_tokens`, which nothing counts yet), or a dated
  Anthropic release note / Models API read — and an estimated cost or
  saving, counted the same way. It writes no plan, no
  code, and merges nothing.
- Human merges = the requirement is UNPLANNED and the existing flow takes
  it (planning manager decomposes, plans, managers). Human closes =
  nothing entered the queue; the record survives in history. The scout
  exits either way.
- `JOHARNESS_SCOUT_AUTOMERGE=on` in `joharness.conf` (default `off`, any
  other value reads as off) is the ONE exception: the scout merges its own
  proposal. The switch is a conf line, so flipping it is a human act and
  the no-inventing bound still holds; the doc records that it is money AND
  product direction in one key, like `JOHARNESS_UPSTREAM_FEEDBACK`.
- Session start under orchestrated mode names the scout beside the curator
  and janitor in the roles table and in `.claude/commands/`.

## Constraints

- No proposal schedules itself. A scout never writes `docs/plans/` or
  `docs/research/`, never edits protocol text, never spawns.
- Evidence-bound: a proposal with no citation is a red run, not a
  judgement call — the same strength as `LAYER_CARVE_OUT_*`.
- Fable is never a build tier in this requirement. The candidates below
  are the scout's, not this requirement's scope.

## Evidence

Session facts counted 2026-10-07 23:30Z with `get_session` on
`session_01KKR8BgAx8M7LhScqXQbFSn` (`orchestrator: chrsctl/gx`) and the
sessions whose `parent_session_id` is it (`list_sessions`);
run facts from `.agents/docs/orchestrated.md` Runs, counted there
2026-09-16 at the freeze:

- Orchestrator: `usage.cost_usd` 710.70, `usage.cache_read_tokens` 1.21B,
  `usage.output_tokens` 1.74M, `context_usage.used_tokens` 412,906.
  `configured_model` opus-5, `user_switched_model` sonnet-5.5 — most of the
  710 accrued at opus-5 cache-read rates. Cache reads, not output, are the
  bill.
- Run 3: 5,252.42 USD floor over 41 merges = ~128 USD per merged edge;
  managers 4,863.78 of it. The 19 children above: `cost_usd` 0.88 to 70.31
  each, `context_usage.used_tokens` 126K to 712K.
- Prices, $/MTok in/out. The Lineup's own rows: haiku 1/5, sonnet 3/15
  (its intro 2/10 expired 2026-08-31), opus 5/25. Served today per the
  claude-api skill cache dated 2026-10-06, which no reader here can
  re-count: haiku 5.5 0.10/0.50, sonnet 5 and 5.5 both 2/10, opus 5.5
  4/20, fable 5.1 10/50. A scout re-counts these from the Models API.

The three candidates below were seeded by the session that drafted this
file (`session_01CAk5n9ueLb5dsXWJjVuXnL`), not by the human; the human's
merge of the pull request carrying them is what authors them. Each carries
the number that picked it:

1. **Orchestrator pass in a fresh session.** The ledger already travels in
   the wake message (`orchestrate.md`, step 4) so the session holds no
   state the next pass needs; a per-pass session bounds the 412K context
   to one pass's reads and answers issue #285's single point of failure
   in the same move. Not a tier cut: run 1 (`orchestrated.md` Runs, 11 of
   28 passes) has the orchestrator overriding `dispatch` on 39% of passes,
   and issue #283 is the same reading one run later — judgement a haiku
   would not supply.
2. **Lineup to current-generation IDs.** Against the Lineup's written
   rows: haiku 10x cheaper, sonnet 33%, opus 20%. Against today's served
   sonnet 5 price, sonnet saves nothing — which of the two the scout
   counts against is its first job. A doc edit and three `lint_enum` lines.
3. **Manager context ceiling.** The 712K-context manager cost 46.76 USD;
   the 126K one 0.88. Whether a context bound (hand off at N tokens, the
   handover protocol already exists for it) cuts cost per merge without
   raising respawns is a measurement, not a guess — the scout proposes the
   measurement.
