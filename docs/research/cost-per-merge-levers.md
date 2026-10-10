---
research: cost-per-merge-levers
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/agent-selection.md
---

## Question

Does any of four named levers cut cost per merged edge by at least 20%
without raising respawns, kills or reverted merges in the same fleet?

## Echo

Run 3 paid ~128 USD per merged edge (`.agents/docs/orchestrated.md` Runs),
managers 93% of it. `.agents/docs/agent-selection.md` Cost levers names
what is free; these four trade something, so each needs a number before a
human picks it — a tier or effort cut is money, humans only. The levers:

1. **Fresh session for long waits.** A manager waiting on CI or review
   past the cache TTL ends after its handover; a fresh session resumes
   from the workstream file instead of waking the fat context.
2. **Fable planning manager at `high`**, not `xhigh`
   (`.claude/commands/orchestrate.md`, UNPLANNED spawn).
3. **Sonnet verifier on opus plans.** Independence, not depth, is what the
   review-depth rule says was missing; the verifier runs at plan tier today.
4. **Haiku 5.5 worker share.** Fraction of manager sub-tasks sent to haiku
   workers, before and after the Lineup move to 5.5.

## Sweep

`goal-directed` — enough runs per lever to compare cost per merge and the
failure counts against a baseline from the same consumer and queue shape.
Not every possible lever.

## What would settle it

Per lever: cost per merged edge (sum of `get_session` `usage.cost_usd` over
the fleet, divided by merges) and respawns + kills + reverts, baseline vs
trial, over at least 10 merged edges each. YES for a lever = cost down
≥20% AND failure count not up. NO = either fails. All four NO closes the
question NO.

## Method

The trial the plan named needs a human to switch each lever on, and no
trial is needed to call a lever NO when it CANNOT reach 20%. A lever cuts
cost per merged edge by at most (share of fleet cost it touches) x (its
largest price cut). Under 20% = NO under the settling rule above, with no
trial run. Denominator = manager cost only: leaving the shared
orchestrator out raises every ceiling, so a NO under it holds.

Readings (Claude Code Remote MCP, this session and its subagents,
2026-10-10):

- `list_sessions` limit 100, two pages (`after_id` = first page's
  `last_id`): 200 sessions, oldest created 2026-10-07T23:23Z. Fleets =
  children of orchestrator `session_01KKR8BgAx8M7LhScqXQbFSn` (consumer
  `chrsctl/gx`) and `session_01LRrvSrFRZExrbQotmHKxQA` (this repo).
- Sample = the 12 newest IDLE `manager:` children of each orchestrator.
- Per sample session, every `result` event: `list_events` limit 100,
  `kinds: ["result"]`, paged by `before_id` = `first_id` until
  `has_more` false. A result carries per-turn main-thread `usage`,
  cumulative per-model `modelUsage` (subagents included) and
  `subagent_stats.by_type`.
- Main-thread cost = per-turn `usage` priced at the session model's list
  rates. Subagent cost = `modelUsage` total minus main thread. Idle gap =
  next result's `created_at` minus its `duration_ms`, minus the previous
  result's `created_at`.
- Rates per MTok (input, output, cache read, 5m write, 1h write): opus 5
  5/25/0.50/6.25/10; opus 5.5 4/20/0.20/5/8; sonnet 5.5 2/10/0.10/2.50/4;
  haiku 5.5 at <=100K 0.10/0.50/0.01. Checked against billing, not taken
  from a table: `Qnp3Vu` sonnet-5-5 `modelUsage` (21,882,198 read,
  252,311 out, 1,390,425 5m write) prices to its billed 8.188 USD at 0.10
  read; two sessions with no subagent (`k3LQgH` sonnet 5.5, `R4vmZi`)
  price to their billed cost from main-thread `usage` alone; every opus 5
  and opus 5.5 `modelUsage` prices inside its 5m-to-1h write range.
  Sonnet 5 rates are NOT established: its three sessions (`VN9LyX`,
  `Ds22mm`, `DLAHXN`) price at 2/10/0.10 to ~58% of billed. No ceiling
  below uses their main/subagent split.
- Overage: 0 of 134 turns wrote main-thread cache at the 5-minute TTL,
  133 at 1 hour (per-turn `usage.cache_creation`). `isUsingOverage` is
  false on all 200 `list_sessions` rows, but that is the state at read
  time, not history.
- Wait inside one turn: a turn whose `duration_ms` passes 60 minutes may
  hold an expiry; its whole main-thread 1h write counts as expiry penalty.
- Merged: read from each manager's final result text, not from GitHub.
  No ceiling divides by it.

Second context for the control-plane readings, named up front: a
subagent that never saw the first readings re-takes `get_session` cost for
all 24 sample ids and re-pages three sessions' `result` events.

## Findings

Sample: 24 manager sessions, 21 merged, 442.32 USD billed (this repo 12
sessions, 12 merged, 59.04 USD; gx 12 sessions, 9 merged, 383.28 USD).
Summed `modelUsage` matches billed within 0.11 USD on 23 of 24 sessions;
`7mYgHb` 8.01 vs 8.25. GROUNDED (re-taken, see Verification).

1. **Fresh session for long waits — NO.** 110 idle gaps between turns
   across 24 sessions; longest 25.3 minutes (gx), 15.2 (this repo); 0
   over the 1-hour cache TTL. A wait inside one turn is invisible to that
   reading: 2 of 134 turns ran past 60 minutes (`YCcNvV` 134.8 minutes,
   `Qnp3Vu` 60.3, both opened by a task notification). All their
   main-thread 1h writes (479,853 + 474,177 tokens at opus 5's 10 USD/MTok)
   = 9.54 USD, 2.2% of the sample. Ceiling 2.2%. Subagents write at 5
   minutes whatever the lever does, so they are outside it. GROUNDED.
2. **Fable planning manager at `high` — NO.** 0 of 168 children of the two
   orchestrators ran Fable (0 of 7 children of an earlier joharness
   orchestrator either); the three Fable sessions in the window had no
   parent (human-started). Touched share 0. And `create_session` takes no
   effort: `xhigh` reaches the session as prompt prose only
   (`.agents/docs/agent-selection.md`, Cost levers). GROUNDED.
3. **Sonnet verifier on opus plans — NO in gx, OPEN in this repo.**
   Subagent cost in opus-tier sessions: this repo 21.93 USD, 37.1% of the
   fleet's 59.04 (every subagent there a `verifier`); gx 61.49 USD, 16.0% of
   383.28 (workers included). Same tokens at sonnet 5.5 cut 50% vs opus 5.5
   and at most 80% vs opus 5 (cache read; 60% on the rest): ceiling 18.6%
   (this repo), 12.4% (gx). gx is under 20% even at a 100% cut (16.0%): NO.
   gx NO: GROUNDED for 42.73 of its 61.49 USD (re-taken), WEAK for the rest.
   This repo clears 20% only if a sonnet verifier spends at most ~92% of the
   opus verifier's tokens (manager-only denominator) — no reading here can
   say that, and none says anything about the defects it would miss. OPEN:
   split out as `docs/research/sonnet-verifier-on-opus-plans.md`.
4. **Haiku 5.5 worker share — NO.** Worker spawns (`general-purpose`): 13,
   in 2 of 24 sessions, 0 of them haiku. All subagent cost in those two
   sessions: 51.42 USD, 11.6% of the sample (13.4% of gx) — the ceiling at
   a 100% cut, verifiers inside it. GROUNDED.

Cost per merged edge, manager only: 21.06 USD (this repo 4.92, gx 42.59)
against run 3's ~128 USD with the orchestrator. Not a lever's effect: the
window, the queue and the models all differ.

## Consequence for the queue

No plan: three levers cannot reach the bar in either fleet, so none
earns a human's money decision. Lever 3 continues as its own question.

## Verification

Second context: a subagent that read none of the first readings re-took
`get_session` for all 24 ids and re-paged every `result` of `Qnp3Vu`,
`fsp9nw` and `GbRy34`.

- Billed cost: 24 of 24 match the first reading. GROUNDED.
- Result counts 7, 3, 9 and newest `modelUsage` (`Qnp3Vu` opus-5
  160.2236265 + sonnet-5-5 8.1881483; `fsp9nw` opus-5 48.216124) and
  `by_type` (`{"general-purpose":12,"verifier":3}`, `{"verifier":2}`)
  match. GROUNDED.
- Largest idle gaps 20.8, 23.9 and 6.0 minutes, all under the TTL; same
  arithmetic, same answer. GROUNDED.
- `GbRy34`: `get_session` reads 14.0514868, its newest result 14.106534
  (session record one step behind). That is the 0.06 USD gap the first
  reading showed; no finding moves.
- Split re-take (a third context, also blind to the first readings):
  per-turn `usage` of `YCcNvV`, `Qnp3Vu`, `GbRy34`, `iVC4mD`, priced at the
  Method's rates. Main thread / subagent USD: 60.70 / 8.96, 125.96 / 42.45,
  7.99 / 6.12, 3.39 / 4.05 — the first reading to the cent. The two turns
  over an hour and their 1h writes (479,853, 474,177) re-read the same.
  These four carry all of lever 4 and 42.73 of lever 3's gx 61.49 USD.
  GROUNDED.
- Same re-take, `list_sessions` two pages: 0 Fable children among 168
  under the two orchestrators (window shifted by new sessions: 117 + 51).
  GROUNDED.
- `YCcNvV` has ONE result event for a 134.8-minute session, so turns
  without a result would be missing from its main thread. That error
  moves cost from main thread to subagent, raising lever 3 and 4
  ceilings: a NO stays safe.
- Not re-taken: the split of the other 20 sessions (WEAK), and merged
  counts, read from each manager's own final text, not GitHub (WEAK; no
  ceiling divides by them).

## Graduates to

`.agents/docs/agent-selection.md` Cost levers — where a session choosing a
tier or a wait already reads.
