---
research: orchestrator-hand-off-lineage-cap
urgency: normal
agent: opus
effort: high
graduates: .claude/commands/orchestrate.md
---

## Question

Does `orchestrate.md` §4 HAND-OFF hand the fleet to a successor that can still
spawn managers and arm its next pass, given that the control plane caps
session lineage depth?

## Echo

Each hand-off is a `create_session` from the retiring orchestrator, so the
successor is that session's child. The control plane counts that ancestry
and, at a cap, refuses `create_session`, `send_later` and every trigger
call. If the chain can reach the cap, some hand-off produces an orchestrator
that holds the fleet and can do nothing for it. On the answer rests whether
an unattended fleet (no heartbeat) lives indefinitely or dies a fixed time
after a human starts it.

## Sweep

`goal-directed`: everything needed to say whether HAND-OFF can strand the
fleet, and what a guard would read. Not a survey of every control-plane
limit.

## What would settle it

- A session's own `get_session` exposing a depth and a cap, and a refusal
  quoting them. Absent either one, the question is open.
- The `parent_session_id` chain of one consumer's orchestrators, from the
  stranded session back to a session with no parent, with one hand-off per
  level. A chain that branches or skips levels would mean something else
  deepens it.

## Method

Run on chrsctl/gx on 2026-10-16, from orchestrator
`session_01R1n8ZaN4UD8ALPGzrv96XA` (the stranded one):

```
get_session()                              # no session_id: this session
send_later(delay_minutes=10, ...)          # §4 arm, pass 1
create_session(source_url=..., title="manager: ui-adapt-entry-palette-dashboards", ...)
get_session(session_id=<each parent_session_id>)   # walked to the root
git log origin/main --merges --since=2026-10-16T04:00Z --format='%H %cI %s'
JOHARNESS_PENDING_SPAWNS=0 ./joharness.sh dispatch
```

## Findings

- **The control plane exposes the cap on the session's own record.**
  `get_session()` with no `session_id` returned
  `"lineage":{"depth":8,"limit":8}`. `get_session` on any other session
  returned no `lineage` field, so only a session can read its own depth.
- **At depth == limit both of the orchestrator's REQUIRED tools refuse.**
  `send_later` and `create_session` each returned, verbatim: `this session
  is at lineage depth 8 (limit 8), so it cannot start sessions, or create,
  fire or re-arm routines and reminders. No user or organization setting
  changes this limit; finish the work in this session or ask the user to
  start a new session.` Its own pass 1 ran (the health pass and one nudge,
  delivered), then nothing could arm pass 2.
- **HAND-OFF alone built the chain, one level per hand-off.** Walking
  `parent_session_id` from the stranded session reached a root with no parent
  (`origin: ios`, a human start). Every level is titled `orchestrator (handed
  off): chrsctl/gx`, and each one's last summary reads "handed off ... after
  6 passes":

  | depth | session | created (UTC) |
  | --- | --- | --- |
  | 0 | `session_01GSLdrT5D6JTfJpL5GBgoFV` (ios) | 2026-10-15 19:34 |
  | 1 | `session_01WyBva2PkBQDpaNjusj14F7` | 20:40 |
  | 2 | `session_01JigpUc3w5AD9EFiSJKoAg4` | 21:47 |
  | 3 | `session_01NE3yPGFGdzdniftHqe5Nt6` | 22:55 |
  | 4 | `session_01Rudbvmg8EHRCWsmcrS4WcY` | 2026-10-16 00:03 |
  | 5 | `session_01AsR4NYHRvGtXyc5NcMDvrx` | 01:10 |
  | 6 | `session_016dNPPf1tmGbHfydhwNpYb1` | 02:16 |
  | 7 | `session_016e7m9HxPjzAPBtKEsDGFnc` | 03:25 |
  | 8 | `session_01R1n8ZaN4UD8ALPGzrv96XA` | 04:31 |

  At `JOHARNESS_ORCHESTRATOR_PASSES=6` and `JOHARNESS_HEALTH_MINUTES=10`
  (about 11 minutes a pass in practice), a hand-off came every 66 to 68
  minutes. **A fleet with no heartbeat dies at about limit × passes × pass
  interval: here 8 × 6 × ~11 min, nine hours after the human started it.**
- **The depth-7 hand-off was the fatal one, and nothing checked it.**
  Depth 7 could still `create_session` (it created depth 8), so §4's
  existing failure branches ("Fails or refused = ...") never fired. The
  successor could not act at all. §4 step 1 reads `configured_model`, a
  title and `send_message`, but never `lineage`.
- **What it cost.** No pass was armed after 04:33Z. `ui-adapt-agent` (PR
  #782) merged at 05:37Z and `ui-adapt-automation-story` (PR #783) at
  07:10Z. At 08:42Z dispatch read `slots : 2 of 4 free` with `20 free
  item(s)`, and nothing could fill them. The two managers still in flight
  were past `CEILING?` (9h and 10h, $43.62 and $60.42 `cost_usd`) with no
  orchestrator health pass on them after 04:33Z. The human found out by
  asking "Can you check again" and then "Why can't you spawn one".
- **Managers inherit depth too (not measured further).** A manager is the
  child of the orchestrator that spawned it: `manager: web-presence-bubbles`
  has parent `session_01JigpUc3...` (depth 2), so the manager sits at depth 3.
  A depth-7 orchestrator's managers would sit at the cap, unable to
  `send_later`. Whether `manage.md` or a PR check-in needs `send_later` or
  `create_session` was not measured here.
- **Open: does a heartbeat Routine reset the depth?** `orchestrated.md`,
  "Heartbeat: making the fleet long", fires a fresh orchestrator from
  `create_trigger` with `create_new_session_on_fire: true`. Whether that
  fresh session starts at depth 0, or at the trigger creator's depth plus
  one, is unmeasured. gx has no heartbeat (`list_triggers` with
  `enabled: true` returned `[]` at 08:4xZ), and a session at the cap cannot
  create a trigger to test. The refusal's "create, fire or re-arm routines"
  suggests routines are counted, so the depth could carry over.

## Consequence for the queue

Proposals for canonical to decide; this is a consumer's report, not a fix.

1. `.claude/commands/orchestrate.md` §4 HAND-OFF, step 1: read `lineage`
   from the same `get_session()`. Hand off only while `depth + 1 < limit`,
   so the successor can still `create_session` and `send_later`. Otherwise
   do not hand off: arm `send_later` in THIS session past `passes :`. The
   pass count is a cost tune; a stranded fleet costs more. Report `lineage
   <depth>/<limit>: no hand-off; start a fresh orchestrator session`, and
   `PushNotification` it once. If `lineage` is absent, today's behaviour
   applies.
2. The same file, "## 0. Start": read `lineage` once. At `depth >= limit`,
   the REQUIRED-tools rule already says stop. Name the lineage cap in the
   report and the push, so the human learns it from the first pass rather
   than by asking.
3. `.agents/docs/orchestrated.md`, "Start each run fresh": record the chain
   above as the first measured hand-off sequence (it asks for one), with the
   lifetime arithmetic. Reword the Heartbeat section's "nothing makes it
   LONG": the hand-off makes the fleet long only up to the lineage cap.
4. A measurement for an operator: create one heartbeat Routine and read
   `get_session()` `lineage` in the session it fires. Depth 0 makes the
   heartbeat the durable fix. Carried-over depth means a heartbeat chain
   strands too, and the guard in 1 is the only defence.

## Verification

Not yet verified from a second context. Every claim above is GROUNDED in
the session record or the command named beside it, read by the stranded
orchestrator itself, except the two open items: managers needing
`send_later`, and heartbeat depth. Both are UNGROUNDED and marked open. A
verifier re-runs the parent walk with `get_session` on the listed ids. The
chain stays readable while those sessions exist.

## Graduates to

`.claude/commands/orchestrate.md`, because the guard has to sit where the
hand-off is decided. A rule line elsewhere would not run at §4 step 1, which
is the one moment a session can still choose not to strand its successor.
