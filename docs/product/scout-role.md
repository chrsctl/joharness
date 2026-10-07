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
is allowed to invent work. Want: a `fable` tier and a role that uses it to RESEARCH new
capacities — model releases, API features, what merged edges and the
scorecard say about the harness itself — and PROPOSE them. Proposals, not
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
  reader (`get_session`: `usage.cost_usd`, `usage.cache_read_tokens`,
  `context_usage.used_tokens` — the reader `orchestrated.md` Runs already
  counts with), or a dated Anthropic release note / Models API read — and
  an estimated cost or saving, counted the same way. It writes no plan, no
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

Counted 2026-10-07 23:30Z from `get_session` on the `orchestrator:
chrsctl/gx` session and its children (`list_sessions`, `parent_session_id`),
and from `.agents/docs/orchestrated.md` Runs:

- Orchestrator: `cost_usd` 710.70, `cache_read_tokens` 1.21B, `output_tokens`
  1.74M, `context_usage.used_tokens` 412,906, worker epoch 409. Configured
  opus-5, switched by the human to sonnet-5.5 mid-life — most of the 710
  accrued at opus-5 cache-read rates. Cache reads, not output, are the bill.
- Run 3: 5,252.42 USD floor over 41 merges = ~128 USD per merged edge;
  managers 4,863.78 of it. Today's managers: 5–70 USD each, contexts
  126K–712K.
- Lineup prices vs served (claude-api skill cache, 2026-10-06, $/MTok
  in/out): haiku 4.5 → 5.5 is 1/5 → 0.10/0.50; opus 5 → 5.5 is 5/25 →
  4/20; sonnet 5 → 5.5 is 2/10 → 2/10, no saving. Fable 5.1: 10/50.

Candidates the first scout inherits, each with the number that picked it:

1. **Orchestrator pass in a fresh session.** The ledger already travels in
   the wake message (`orchestrate.md`, step 4) so the session holds no
   state the next pass needs; a per-pass session bounds the 412K context
   to one pass's reads and answers issue #285's single point of failure
   in the same move. Not a tier cut: #283 / run 1 show the orchestrator
   overriding `dispatch` on 39% of passes, which a haiku would not.
2. **Lineup to current-generation IDs.** Haiku row 10x cheaper, opus row
   20%; sonnet unchanged. A doc edit and three `lint_enum` lines.
3. **Manager context ceiling.** The 712K-context manager cost 46.76 USD;
   the 126K one 0.88. Whether a context bound (hand off at N tokens, the
   handover protocol already exists for it) cuts cost per merge without
   raising respawns is a measurement, not a guess — the scout proposes the
   measurement.
