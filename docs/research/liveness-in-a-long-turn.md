---
research: liveness-in-a-long-turn
urgency: normal
agent: opus
effort: high
graduates: .claude/commands/orchestrate.md
---

## Question

Does a session's `updated_at` advance while it sits inside ONE long turn, or
only when a turn ends?

## Echo

The health pass decides kill, nudge and respawn from `updated_at` plus the
branch head, read twice. Every candidate rule for separating a dead manager
from a slow or looping one assumes an answer to the question above, and two
rules drafted for issue #249 assumed OPPOSITE answers in the same diff: one
argued a manager six minutes into a long turn shows a FROZEN `updated_at`, so
a two-reads-in-one-pass verdict would kill it; the other required
`updated_at` to have MOVED as proof a session is alive. Both cannot hold. A
wrong answer here destroys work in progress and spends the concurrency cap
twice.

## Sweep

`goal-directed` — enough to decide what the health pass may key on for a
session mid-turn. Not a survey of the control plane's fields generally.

## What would settle it

A session observed across a turn KNOWN to be long, with `updated_at` sampled
more than once inside it:

- `updated_at` advances during the turn: a frozen reading is evidence of
  death even at short intervals, and a two-read verdict inside one pass is
  defensible. The rules drafted for #249 stand with their interval named.
- `updated_at` advances only at turn boundaries: then interval is everything.
  A verdict needs two reads at least one long turn apart, which is what "two
  passes" buys, and no in-pass pair may ever decide. The drafted signature
  must say so.
- It depends on the client version or the turn's tool use: the field cannot
  carry a verdict alone at any interval, and the health pass needs a
  different discriminator.

## Method

Run 2026-09-17. The corpus is a live orchestrated fleet in a consumer,
sampled read-only from outside with `get_session` — so the sampler is not
the session, which is what the sketch below asked for, and no session was
spawned to be watched, which would have been the human's money for a reading
already on offer.

```
list_sessions                      # pick subjects by session_status
get_session <id>                   # 12:45:58Z, 12:48:58Z, 12:54:02Z
```

**The confound this question does not name, and the field that closes it.**
Many short turns look like one long turn if you only watch `updated_at`.
`post_turn_summary` is written when a turn ENDS, so it is the independent
clock: `updated_at` moving while `post_turn_summary` is byte-identical means
no turn boundary fell between the samples. A session that has NEVER finished
a turn carries no `post_turn_summary` at all, which makes its whole life one
turn and needs no comparison.

**The second confound: does the read itself bump the field?** Both RUNNING
subjects returned an `updated_at` inside a second of the call. That would be
fatal if reads were writing it, so an IDLE, disconnected session was read as
a control.

The sketch this replaces asked for a session started with a task known to
run several minutes. That is the cleaner experiment and it costs money; it
is the next step only if the reading above had come back ambiguous.

## Findings

- **`updated_at` advances DURING a turn.** Subject A, a manager in its FIRST
  turn — no `post_turn_summary` in the record at any sample, so zero turns
  had ended and its whole life was one turn. `created_at`
  `12:42:10.232025Z`; `updated_at` `12:46:34.218833Z`, then
  `12:48:58.253303Z`, then `12:54:02.164223Z`. Eleven minutes fifty-two
  seconds, one turn, the field tracking throughout. `get_session` on that id
  at each of the three times.
- **Corroborated on a second subject with real work between the samples.**
  Subject B, RUNNING, carrying a `post_turn_summary` from an earlier turn:
  `updated_at` `12:46:36.751182Z` → `12:48:58.684883Z` while
  `post_turn_summary` stayed byte-identical (`review_ready`, "handover
  pushed; awaiting worker notifications to proceed") and `usage.cost_usd`
  moved `35.08391755` → `36.07648935` with `output_tokens` +7,314. Work
  happened, no turn ended, the field moved.
- **The read does not bump the field.** Subject C, IDLE and
  `connection_status: disconnected`: `updated_at` `12:38:59.746071Z` in a
  `list_sessions` page at 12:45:58Z and `12:38:59.746071Z` again from a
  direct `get_session` at 12:49:00Z. Identical to the microsecond across a
  read three minutes later, so neither reading writes it, and a session
  doing nothing shows a frozen field.
- **What a MOVING field does not prove.** Both RUNNING subjects returned an
  `updated_at` within a second of the call, every time. Against subject C's
  frozen field, the reading is that a CONNECTED session refreshes this
  continuously — so movement proves the container is up and connected, not
  that the turn is making progress. A connected session wedged inside a tool
  call would still show a moving field. This is the half neither rule
  drafted for issue #249 had.
- **`task_summary` is not a turn-boundary field; `post_turn_summary` is.**
  Subject A's `task_summary` changed between samples 2 and 3 ("researching
  diff anchors against code feedback" → "claimed comms-sequences;
  researching test suite & web surface") with no `post_turn_summary` ever
  appearing. So `task_summary` moving says nothing about turns, and
  `post_turn_summary` changing is the only cheap turn-end signal in the
  record.

## Consequence for the queue

The question closes on its FIRST branch, with one correction to how that
branch was written. "A frozen reading is evidence of death even at short
intervals" holds, and the reason is stronger than the branch assumed: the
field is refreshed by the connection, not by the work, so on a CONNECTED
session a frozen `updated_at` is loud. The branch's other half — "a two-read
verdict inside one pass is defensible" — holds for declaring a session GONE
and not for declaring it STUCK, because a moving field proves only that the
container is up.

The four rules withdrawn from issue #249 can be rewritten on that, and the
one that would have killed a manager six minutes into a long turn is
answered outright: it was wrong. Its premise — a frozen `updated_at` mid-turn
— does not occur on a connected session.

No plan carries a `research:` edge to this file, so nothing unblocks
mechanically. What changes is that the health pass's evidence table can
state what this field means, which is where the answer graduates.

## Verification

Second context: `.claude/agents/verifier.md`, spawned to re-sample the same
subjects from its own `get_session` calls rather than to read this file's
numbers. Its verdict is in the workstream file's `## Review`, tagged
`(verifier)`.

- **`updated_at` advances during a turn** — GROUNDED. Three samples of a
  session with no `post_turn_summary`, which cannot have ended a turn.
- **Reads do not bump it** — GROUNDED. The idle control is identical to the
  microsecond across two reads three minutes apart.
- **Movement means connected, not progressing** — WEAK, and said as weak.
  It rests on the sub-second alignment of every RUNNING reading with its
  call, which is consistent with a connection heartbeat and consistent with
  a very chatty session. Separating those needs a connected session known to
  be idle inside a turn, which the fleet did not offer. The graduated text
  claims only what the health pass needs: a frozen field on a connected
  session is death evidence; a moving one is not progress evidence.

## Graduates to

`.claude/commands/orchestrate.md`, the evidence table in step 2. That table
already disqualifies two fields that look decisive and are not
(`context_usage.used_tokens`, `external_metadata.current_branches`), each on
one counter-example; this is the same kind of entry for the field the whole
health pass turns on. A rule line alone would not carry it, because what a
reader needs is the asymmetry — frozen is loud, moving is quiet — and that is
a sentence about the field, not about a row.
