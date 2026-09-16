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

Not yet run. The reading has to come from a session whose turn length is
known independently, so the sampler must not be the session itself:

```
# a session started with a task known to run several minutes in one turn
get_session <id>          # t0, before the turn's first tool call returns
get_session <id>          # t0 + 60s, mid-turn
get_session <id>          # t0 + 180s, still mid-turn
get_session <id>          # after the turn ends
```

Record `updated_at`, `session_status`, `status_bucket` and
`connection_status` at each. Repeat on a second session to rule out one
client version. The existing corpus cannot answer it: issue #249's readings
are all of sessions whose turn state at the sample was not independently
known, which is exactly why the two drafts could each cite it.

## Findings

OPEN. Nothing measured yet. Recorded so the next reader does not re-derive
the conflict from the drafts.

## Consequence for the queue

Issue #249's first cut merged narrowed to two items that do not depend on the
answer: the caution that a workstream file's `session:` line names a writer
rather than a worker, and the worked reading of a dead manager wearing the
LOOP row's shape. Four rules were withdrawn pending this question — a death
signature keyed on `connection_status`, a duplicate-by-branch check, a LOOP
precondition, and the ledger fields those needed. The withdrawal and its
reasoning are in that branch's retired workstream file.

## Verification

None yet; no finding to verify. When one exists it needs a second context per
`.agents/docs/research/README.md`, and the second context must not be the
session that produced the reading.

## Graduates to

`.claude/commands/orchestrate.md`, the health pass. That is where a verdict
on a session's liveness is reached, and where a wrong answer costs money.
