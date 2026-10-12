---
plan: scout-backlog-clock
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: scout-market-research
issue: none
scope: shared:joharness.sh, .agents/harness/selftest/scout.sh, .agents/scripts/conf-keys.sh, .agents/scripts/bootstrap-consumer.sh, shared:.agents/harness/selftest.sh, shared:.agents/docs/orchestrated.md
---

## Goal

The scout runs when the backlog runs low, not only on a clock at `DRAINED`
(`docs/product/scout-market-research.md`, Backlog, Three days, Cost,
Constraints). Today `scout_due` reads one clock, `JOHARNESS_SCOUT_HOURS`, and
`dispatch` spawns a scout only under `DRAINED — nothing free, nothing in
flight`. This plan adds the backlog trigger and the four conf lines the
requirement names, and makes `./joharness.sh scout` print everything a scout
pass reads from conf — the number N, the budget, the reviewer, the research
switch, the brief's state — so the role command (`scout-proposes-on-issues`)
reads one report and never the conf file. Dispatch stays git-only: it counts
open plans; the scout session counts open proposal issues on GitHub and
finishes the sum itself.

## Scope

- `.agents/scripts/conf-keys.sh` — four rows, after `JOHARNESS_SCOUT_AUTOMERGE`:
  - `JOHARNESS_SCOUT_BACKLOG|24|Open plans plus open scout proposal issues below this = a scout is due. Counted: 3 days x 8 merges/day, git log --merges --first-parent --since=14.days --format=%h origin/main | wc -l = 118, 2026-10-12; 0 leaves only the clock, and the pass proposes without a ceiling.`
  - `JOHARNESS_SCOUT_BUDGET_USD|10|USD one scout pass may spend before it stops researching and proposes from what it has (get_session usage.cost_usd). A written number until a pass counts one.`
  - `JOHARNESS_SCOUT_REVIEWER||GitHub login whose approved label is the approval gate on a scout proposal issue. Empty = nothing can be approved.`
  - `JOHARNESS_SCOUT_RESEARCH|off|on = a scout pass reads outside the repository (web, competitor docs, market reports); off = inside evidence only.`
- `.agents/scripts/bootstrap-consumer.sh` — seed the four keys in the heredoc
  beside `JOHARNESS_SCOUT_AUTOMERGE`, defaults from `conf_key_default`, no
  interview question for any of them.
- `.agents/harness/selftest.sh` — the four names in the conf-key list beside
  `JOHARNESS_SCOUT_HOURS JOHARNESS_SCOUT_AUTOMERGE`.
- `joharness.sh` — `scout_due`: a second trigger. `n_plans` = `*.md` under
  `docs/plans/` on `refs/remotes/origin/<base>` minus `README.md`,
  `TEMPLATE.md`, `VISION.md`; `N` = `num_knob JOHARNESS_SCOUT_BACKLOG 24`.
  `N > 0 && n_plans < N && brief present && age >= 24` reads
  `due backlog <n_plans> open plan(s) on <base> below N=<N> (JOHARNESS_SCOUT_BACKLOG)`
  where `age` is the SMALLER of the hours since the last scout retire that
  landed on the base branch and the hours since the last retire on any
  unmerged branch (`scout_retired_ts`), read for this trigger on every call —
  the clock consults `scout_retired_ts` only past `JOHARNESS_SCOUT_HOURS`,
  and under the new role no scout branch merges, so the unmerged retire is
  the one that exists; never scouted = repository age. `brief present` =
  `docs/product/SCOUT.md` exists on the base ref. The 24 is a written
  number, a one-line comment says so: one reviewer's day between passes.
  Known cost, accepted: dispatch counts plans only, so a pile of unreviewed
  proposals keeps the trigger due; the pass it spawns reads two reports,
  finds its ceiling at or below 0, retires as `WAITING ON REVIEW` before
  any outside read (`scout-proposes-on-issues`, §0), and the 24h re-arm
  bounds it to one such pass a day. Clock trigger unchanged. Both
  `unreadable` and `off` states unchanged. `SCOUT_DUE` keeps its first word
  as the state (`due`, `not-due`, `off`, `unreadable`); the backlog reason
  starts with the word `backlog` so `dispatch` can tell the two apart.
  `scout_reviewer()`: reads `JOHARNESS_SCOUT_REVIEWER` the way
  `scout_automerge` reads its key, from the base branch's conf, environment
  first, so a branch cannot name its own reviewer.
  `cmd_scout`: five lines after `cadence`, exact shape in Acceptance.
  `cmd_dispatch`: a backlog-due scout spawns WITHOUT the `scout_gate`
  (`DRAINED`) condition; every other condition stays — fresh fetch, none in
  flight, no curate or clerk due or in flight. Line text in Acceptance. The
  clock-case spawn line and `cmd_scout`'s closing `JOHARNESS_SCOUT_AUTOMERGE`
  paragraph say the same new story: the scout proposes on issues, a reviewer
  approves; the key no longer governs a merge. The key, `scout_automerge`
  and the selftest cases that read the key's VALUE stay; only the printed
  sentences change, with their selftest expectations.
- `.agents/harness/selftest/scout.sh` — cases: backlog low spawns under `NOT
  DRAINED`; backlog low with no `docs/product/SCOUT.md` on main = clock only;
  backlog low within 24h of a retire = not due; `JOHARNESS_SCOUT_BACKLOG=0` =
  clock only; `reviewer`, `research`, `brief` lines in both states;
  `JOHARNESS_SCOUT_REVIEWER` set on the branch's conf but not main's reads
  `none`.
- `.agents/docs/orchestrated.md` — four rows in the numbers table ("The
  numbers are the human's") beside the two scout rows, each marked counted
  or written as above; the `scout` row of "How the harness runs" says
  "GATED on DRAINED by the clock; the backlog trigger
  (`JOHARNESS_SCOUT_BACKLOG`) is not".

## Out of scope

- The scout role text (`.claude/commands/scout.md`) — `scout-proposes-on-issues`.
- Keeping `docs/product/SCOUT.md` out of the requirement queue —
  `scout-brief-home`. This plan only tests for the file's presence.
- Reading GitHub from `joharness.sh`. Proposal issues are counted by the
  scout session, never by `dispatch` or `scout`.
- `JOHARNESS_SCOUT_AUTOMERGE` the KEY: its conf line, `conf-keys.sh` row,
  `scout_automerge` and how it resolves, byte for byte (requirement,
  Constraints). The sentences `cmd_scout` and `dispatch` print about it are
  not the key and do change (Scope).
- `joharness.conf` of this repository — a core path. The pull request body
  asks the human for the four commented lines; the code reads the defaults
  until then.
- Any change to `JOHARNESS_SCOUT_HOURS`'s meaning or default.

## Acceptance

- `./joharness.sh scout | grep -E '^(backlog   |throughput|brief     |reviewer  |research  ):' | wc -l` — `5`. The lines, on this repository's `main` with the keys unset and no brief:

  ```
  backlog   : 10 open plan(s) on main, N=24 (JOHARNESS_SCOUT_BACKLOG): low, but NO BRIEF — clock only
  throughput: 8 merge(s)/day over 14 days (git log --merges --first-parent --since=14.days --format=%h origin/main | wc -l, 2026-10-12); 3 days = 24
  brief     : NO BRIEF — no docs/product/SCOUT.md on main: no outside research, the pass proposes nothing
  reviewer  : none (JOHARNESS_SCOUT_REVIEWER) — nothing can be approved
  research  : off (JOHARNESS_SCOUT_RESEARCH); budget 10 USD a pass (JOHARNESS_SCOUT_BUDGET_USD)
  ```

  The plan count, the merge count and the date are live; the shape is fixed.
  With a brief and the backlog low: `backlog   : <n> open plan(s) on main, N=<N> (JOHARNESS_SCOUT_BACKLOG): low — a scout is due`.
  Backlog not low: `: enough`. `N=0`: `backlog   : off (JOHARNESS_SCOUT_BACKLOG=0): clock only, no ceiling`.
- `./joharness.sh dispatch` on a fixture with a brief, 1 open plan, `JOHARNESS_SCOUT_BACKLOG=3`, one manager in flight, last scout retire 48h back: tail line
  `scout DUE: spawn ONE scout (agent: fable) on /scout — backlog low (JOHARNESS_SCOUT_BACKLOG), beyond the cap, holds no slot, at most one in flight. It proposes on issues; a reviewer approves (JOHARNESS_SCOUT_REVIEWER)` under a `NOT DRAINED` verdict. Same fixture, no brief: the `scout     :` line reads `not due` and the tail prints no scout line. Same fixture, a retire on an unmerged branch 1h back and a merged one 100h back: `not due`.
- `./joharness.sh dispatch` under `DRAINED` with the clock due: the tail line reads `scout DUE: spawn ONE scout (agent: fable) on /scout — beyond the cap, holds no slot, at most one in flight, only at DRAINED. It proposes on issues; a reviewer approves (JOHARNESS_SCOUT_REVIEWER, JOHARNESS_SCOUT_HOURS)`; `./joharness.sh scout | tail -2` no longer says a proposal waits for a merge.
- `bash .agents/harness/selftest.sh 2>&1 | tail -3` — `0 failed`; the new cases named above grep-able in `.agents/harness/selftest/scout.sh`.
- `./joharness.sh ci` — `ci: pass`. `./joharness.sh verify` — `0 failed`.
- SHIPS (`joharness.sh`, `.agents/docs/`): on a consumer after sync, `./joharness.sh scout` prints the five lines with the consumer's own conf values; `.agents/scripts/bootstrap-consumer.sh --dry-run` on a fresh directory names the four keys.

## Where to look

- `joharness.sh:scout_due` — the clock; the backlog trigger goes beside it, same `SCOUT_DUE` word protocol.
- `joharness.sh:scout_automerge` — reads a key from the base branch's conf; copy for `scout_reviewer`.
- `joharness.sh:cmd_scout` — the report; new lines after `cadence`.
- `joharness.sh:cmd_dispatch` — the `scout_gate` chain at the tail; the backlog case bypasses only `scout_gate`.
- `joharness.sh:num_knob` — how a knob resolves: environment, conf, default.
- `joharness.sh:lint_nodes` — the three names a plan count skips.
- `.agents/scripts/conf-keys.sh:conf_keys_rows` — row format; the selftest compares it to the bootstrap heredoc.
- `.agents/harness/selftest/scout.sh` — `sct`, `sdsp`, `sws`, `scommit`: the fixture helpers the new cases reuse.
- `.agents/docs/orchestrated.md` — "The numbers are the human's" table.

## Traps

- Never read GitHub from `joharness.sh`: the harness is git-only by design; a GitHub call in `dispatch` is a new dependency every consumer pays.
- Never touch `joharness.conf`, `.claude/settings.json`, `.github` (`./joharness.sh protocol-paths`).
- `JOHARNESS_SCOUT_AUTOMERGE` the key stays exactly as it is — conf line, row, reader; a selftest asserting the old printed sentence is updated, never deleted.
- A reviewer read from the branch's own conf would let a branch grant itself approval; read the base branch's, as `scout_automerge` does.
- Fail closed: an unreadable base ref holds the cycle (`unreadable`), never spawns.
- A number in a doc or conf comment names its command and date; the 24h re-arm and the 10 USD budget are written numbers and say so.
- `scout-brief-home` edits `joharness.sh:lint_nodes` and the queue hook for `SCOUT.md`; this plan only stats the file. Both are `shared:` on `joharness.sh`.
- `sampling-conduct-reviewer` (in flight on `origin/sampling-conduct-reviewer` on 2026-10-12) adds conf rows to `.agents/scripts/conf-keys.sh`, names in `.agents/harness/selftest.sh`'s key list and cases in `.agents/harness/selftest/scout.sh` — the same hunks this plan edits. The hook holds this plan until that branch merges; merge `origin/main` in first and add rows after its rows.
