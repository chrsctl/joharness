---
research: frozen-cost-is-not-death-yet
urgency: normal
agent: opus
effort: high
graduates: .claude/commands/orchestrate.md
---

<!--
Split out of `docs/research/push-age-is-not-death.md` (issue #283) when that
node closed. Its half — may a row order a respawn on push age — was answered
NO and graduated (`.agents/docs/orchestrated.md`, "And push age is not death
either"; code in PR #362). This is its option 2, which it said must land
separately: a new class of evidence, not a deletion. Recover the parent:
`git log --diff-filter=D -p -- docs/research/push-age-is-not-death.md`.
-->

## Question

May the orchestrator's health table read a frozen `cost_usd` as evidence of
death, and if so, after what minimum frozen window?

## Echo

Every field the health table now keys on — `status_bucket`, `updated_at`,
the head from git — has been measured frozen on a session that was alive.
`cost_usd` is the one field #283 found that separated a dead session from a
suspended one. But a live `IDLE` manager also held cost still for up to 31
minutes, and a `RUNNING` one froze every field, cost included, for 172s. So
the question is whether frozen cost is a death signal at ANY window, and
what floor would keep it from killing a live session. It would put a
control-plane money field into the evidence table for the first time.

## Sweep

`goal-directed` — enough readings, with known outcomes, to set or refuse a
floor. Not a survey of every session field: the four others below are
already refuted.

## What would settle it

- **A frozen-cost window on a session known DEAD, and the longest one on a
  session known ALIVE, both re-sampled by a context that can read the plane.**
  A floor above every alive window and below the dead ones settles YES with a
  number; overlap settles NO.
- **The suspension case.** A suspended fleet freezes cost too (negative
  control below). Whatever test is written must not fire across a
  suspension, or it is push age's mistake in a new field.

## Method

Second context, named here: the manager session that closed this node, which
holds the Claude Code Remote tools (`get_session`, `list_sessions`). The
verifier has no control-plane call (issue #267). Reads, quoted from the plane:

    list_sessions limit=30   (~16:18:45Z; saved, parsed with python json)
    list_sessions limit=12   (~16:19:35Z)
    get_session session_01M9K21PELwkMhyt26ZvSzsq   (16:19:56Z, 16:22:39Z, 16:35:52Z by updated_at)
    get_session              (own session: 16:18:36Z, 16:19:49Z, 16:36:15Z by updated_at)
    git log -S'13-minute frozen pair' -- .agents/docs/orchestrated.md

The issue's readings (Findings, second list) were never re-sampled. History
to read first:

    git log --diff-filter=D -p -- docs/research/liveness-in-a-long-turn.md
    git log --diff-filter=D -p -- docs/research/push-age-is-not-death.md

## Findings

Re-sampled on the plane by the session above (commands in `## Method`):

- **GROUNDED — a live RUNNING session with no cost for 117 minutes.**
  `manager: crm-the-default-door-reaches-the-wire`, created 14:38:12Z. Three
  reads, all `RUNNING`, `WORKING`, `connected`, no `usage` block, no
  `post_turn_summary`: `updated_at` 16:19:56Z → 16:22:39Z → 16:35:52Z,
  `task_summary` from "CRM852 red on main too; running merged head clean" to
  "final clean run on merged head; round-2 verifier running". Alive and
  moving; cost unreadable from creation to the last read (117m40s).
- **GROUNDED — cost also moves between reads of a RUNNING row.** Two RUNNING managers
  with a `post_turn_summary`, reads ~1 minute apart: 7.1347603 → 7.2818833,
  22.2020803 → 26.8445091. Same in the repo's record (`5f5cc37`: +0.524106
  over 359.937s on a RUNNING manager doing real work).
- **GROUNDED — this session.** No `usage` on own reads at 16:18:36Z and
  16:19:49Z (one turn running); `cost_usd` 2.3532222 at 16:36:15Z after that
  turn had ended, still with no `post_turn_summary`.
- **UNGROUNDED — "cost is a turn-end write".** First drafted from the 30-row
  read, where `usage` was present exactly on the 30 of 30 rows that carried
  `post_turn_summary` (23 IDLE, 2 RUNNING, 1 ARCHIVED with both; 4 RUNNING
  with neither). Refuted twice: cost moves mid-RUNNING (above), and this
  session carried `usage` without `post_turn_summary`. (Whether a turn ended
  between those RUNNING reads is not known.) What holds: before
  some first write, a live session carries no cost; after it, the cadence is
  not documented and not measured here. The verdict does not rest on it.
- **GROUNDED — the #283 separation was hindsight.** By its own record the
  corpse and the suspended survivors were all frozen at read time and came
  apart only when the survivors resumed. No single pass can make that read.
- **GROUNDED — the precedent is no longer on main.** The withdrawn
  13-minute-pair sentence: withdrawn in `5f5cc37`, its account trimmed out
  in `7f2b5af`.

From issue #283, all WEAK: the issue and its comment, re-read against the issue and never
re-sampled.

- **Five signals, four refuted.** Push age (wrong 3 for 3 at the largest
  age, 2026-10-05); `updated_at` (a sweep artefact, two unrelated sessions
  1.6 ms apart); `status_detail` / `task_summary` (byte-identical across 23
  minutes of live work); `connection_status` (`connected` survives death);
  `worker_epoch` (bumped 4→5 on a corpse at frozen cost on 2026-09-17, and
  1→2 on all three survivors across the suspension — moves in both cases).
  `cost_usd` alone separated them.
- **Negative control.** A session read at `136.9262205` on
  2026-09-17T19:31:07Z with an unmoved head, open as possibly dead, read at
  `144.76052` after the 18-day suspension — suspended, never dead.
- **Four alive windows.** 2026-10-07, one live manager, `IDLE`,
  `connected`, turn ended on a background run: 28.058789 20:19:50Z–20:38:09Z
  (18m19s), 32.2565868 21:15:04Z–21:34:19Z (19m15s), 36.8669214
  22:11:07Z–22:30:41Z (19m34s), 42.1354032 22:55:14Z–23:26:01Z (30m47s).
  Reads 13–15 minutes apart met a two-reads-plus-IDLE-plus-unmoved-head test
  on every one. It finished its work.
- **The all-fields freeze.** `.agents/docs/orchestrated.md`: a `RUNNING`
  manager with every leaf key byte-identical, cost included, for 172.273s
  while working. From saved pages, re-computable, never confirmed real.
- **Precedent.** A sentence licensing a kill on a 13-minute frozen pair was
  graduated once and withdrawn on review (`5f5cc37`). A floor below 31 minutes repeats it.
- **No such test exists today.** `git grep -n cost_usd -- .claude .agents`
  finds it only in `.agents/docs/orchestrated.md`, never in the health
  table — so #283's comment proposing a "floor" under a frozen-cost test
  names a test the table does not carry.

## Consequence for the queue

None. NO: no row is added; `external_metadata.usage.cost_usd` joins step 2's
"decide nothing" list, and the why lands in `.agents/docs/orchestrated.md`
beside push age.

## Verification

The reviewer (`.claude/agents/verifier.md`) re-sampled nothing: it has no
control-plane call. It checked the readings for internal consistency only and
re-ran the git commands (`5f5cc37`, `7f2b5af` resolve; `git log -S` returns
exactly those two). The plane readings are GROUNDED on the session named in
`## Method`, and on that one session only; no operator re-took them.

Settled NO, on a criterion REPLACED, said so: `## What would settle it`
asked for a re-sampled dead window against the longest alive one. No dead
window was re-sampled — none was needed, because the alive side has no
ceiling. A live `RUNNING` session showed no cost for 117 minutes (past the
45-minute stall default and every reported window); on `IDLE` cost is frozen
for as long as no turn runs, which a self-armed check-in or a suspension
makes as long as it likes. A floor would have to sit above all of that, and
no dead session can be told apart below it. The suspension case is moot:
no test is written.

## Graduates to

`.claude/commands/orchestrate.md` — step 2's "decide nothing" list, the field
list beside the evidence table, where every kill is keyed. The why goes to
`.agents/docs/orchestrated.md`, beside push age, as the push-age node did.
