# Orchestrated mode (beta)

Switch: `JOHARNESS_MODE=orchestrated` in `joharness.conf` (per repo, never
synced), or exported for one command. Third value beside `supervised` and
`unsupervised`; anything else reads as supervised. Requested 2026-09-05,
after four unsupervised runs never got past one generation
([`unsupervised.md`](unsupervised.md), Runs).

Same question as unsupervised — is a human present — same answer, same
bounds. ONE new distinction: who dispatches. Unsupervised is a peer fleet:
each session picks its own item, and the fleet lives only while the
heartbeat fires the next one. Orchestrated puts a controller above the
queue: one low-tier session reads it, spawns a manager per item under a
cap, watches them, and kills a stuck one after its handover is written.
`.agents/docs/product/README.md` records the peer position and what it
costs; this mode is the measured alternative, and beta until a run shows
which empties a queue faster.

## What the mode changes

One row per reader. Supervised sees none of it. Unsupervised sees none of
it either — the two unattended modes share every bound and differ only in
the rows below.

| Where | Change |
| --- | --- |
| `joharness.sh:run_mode` | Third value. `unattended()` is true for both unattended modes and is the ONE predicate the boundary, the requirement lint, the marking and `authority` read. A `= unsupervised` test anywhere is a bound this mode escapes. |
| `session-start` banner | Names the mode and routes by role: prompt names `/manage <item>` = manager; nothing named = orchestrator, run `/orchestrate`. Same boundary list. |
| Queue hook | Same `SUPERVISED ONLY` marking. Plus, this mode only: `in flight: <free> overlaps <claimed> on <path>` lines, one per free plan whose scope collides with a plan a manager holds now. |
| `./joharness.sh dispatch` | New. The orchestrator's one read: the human's numbers, managers in flight with push age and a `STALL?` mark, slots under the cap, the spawn order with waves and `HOLD`s, one verdict line. Reports only. |
| `./joharness.sh drain` | Same verdict; tells a manager it works the item its prompt named, and names the orchestrator's exit as dispatch's verdict. |
| `.claude/commands/orchestrate.md`, `manage.md` | The two roles, as commands. |

## Roles

| Role | Tier | Runs as | Spawns | Owns | Ends when |
| --- | --- | --- | --- | --- | --- |
| orchestrator | haiku, low effort — mechanical on purpose | a session; the heartbeat fires one | manager sessions (`create_session`) | the cap, the health pass, the kill handover | dispatch says DRAINED with nothing in flight |
| manager | the item's `agent:` — plan, research, or sonnet for an unplanned requirement | a session with its own branch, claim and merge | worker subagents (`Agent`) | one item, until its file retires | its pull request merges, or it blocks on a human |
| worker | at or below the plan's tier, lower by default | a subagent in the manager's container | nothing | the files its sub-task names | it returns |

Two spawn levels, never three. A worker that needs a branch of its own is
a plan, and a plan enters the queue through a pull request — the manager
writes it into its own (`.agents/docs/plans/README.md`, same-session plan
handed off) and the orchestrator spawns it next pass. Subagents cannot
claim, get no hook state and die with the parent's turn
([`subagents.md`](subagents.md)); the manager's branch is the unit of
claim, and that is why the split falls where it does.

The default role is the orchestrator. The heartbeat's prompt is standalone
and the orchestrator is what must be re-seeded; a manager is told what it
is by the orchestrator that spawned it. Two orchestrators are the
collision to avoid, and the rule is one line: a `RUNNING` session titled
`orchestrator: <repo>` that is not you = exit.

## The loop

Every `JOHARNESS_HEALTH_MINUTES`, scheduled with `send_later` — never a
sleep, never a poll:

1. `./joharness.sh dispatch`.
2. Health pass over every manager in flight (table below). Kills and
   respawns happen here, before any spawn.
3. Spawn up to `slots`, in dispatch's order, skipping `HOLD`, a wave-2
   row whose partner is in flight, and `NOT YOURS`.
4. Schedule the next pass; end the turn.

Spawn = `create_session` with the repository attached, the item's tier
mapped to a model by [`agent-selection.md`](agent-selection.md) Lineup, a
title `manager: <stem>`, and a prompt carrying `/manage <path>`,
`./joharness.sh authority` and `./joharness.sh protocol-paths` — the three
things [`unsupervised.md`](unsupervised.md) Authority says a spawn prompt
carries, and nothing that asserts its own legitimacy.

## Health: two signals, five words

Gas Town paid three times for a monitor that read one store — a healthy
worker read as stuck, and its own rule became cross-check first
([`prior-art.md`](prior-art.md)). This harness's handover protocol says
the same from the other side: push time is not liveness in either
direction. So a verdict here needs both halves, and dispatch prints only
the git half.

| Word | Git (dispatch) | Control plane | Orchestrator does |
| --- | --- | --- | --- |
| working | any push age | `RUNNING`, or pushed inside the window | nothing |
| stalled | `STALL?` — no push for `JOHARNESS_STALL_MINUTES` | `RUNNING`, `status_detail` unchanged across two passes | nudge, then kill |
| gone | branch unmerged, status in-progress / review / done | not `RUNNING` | respawn on the branch |
| blocked | status `blocked` | any | report to the human; never respawn |
| done | branch merged, plan file gone | any | nothing |

A nudge is a message: push your workstream file now. Most stalls end there
— a session deep in a build has a handover it has not written, and
writing it is what the next session needs anyway.

## The kill, and why the handover comes first

The requester's words: kill, but before that summarise progress into the
handover for the next one. In that order, because a killed session with no
handover strands a branch the successor cannot read, and the whole
protocol is built on the file being written by the session that knows.

1. Interrupt. The Stop guard fires in the manager; it may push.
2. One pass later: head or `updated:` moved = the handover landed.
3. Else the orchestrator writes it — the one file this role ever writes:
   a note under `## Blockers` with the date, the reason, the control
   plane's last summary and the diff stat, and a `next:` that says resume.
   Committed on the manager's branch, pushed.
4. Archive the session. Spawn a successor on the SAME branch, prompt
   naming the branch and the file to read whole. Counted: past
   `JOHARNESS_RESPAWN_LIMIT` the branch stays claimed — dispatch keeps it
   out of the spawn list — and the human is told.

The branch is the claim and the claim survives the kill. That is the
property the peer fleet already had and this mode keeps: nothing is
stored, the successor reads git.

## Concurrency

`JOHARNESS_MAX_MANAGERS` caps managers in flight. Blocked managers hold no
slot — their session exited on purpose. Within the cap the order is the
queue hook's: urgent first, then oldest, partitioned into waves of
disjoint scope. Two things this mode adds to the wave rule:

- A free plan whose scope overlaps a plan a manager HOLDS is `HOLD`, not
  free. The peer fleet takes the collision and pays the reconcile at step
  7; an orchestrator that knows the collision is coming has no reason to
  send a manager into it. The hook computes it with the same
  `scopes_overlap` the waves use, printed only in this mode.
- A wave-2 plan waits while its wave-1 partner is in flight or spawned in
  the same pass.

The reconcile rate the peer fleet measured — about one merge in four
(`.agents/docs/product/README.md`, Orchestration) — is the number a run of
this mode should move. If it does not, the hold rule bought nothing.

## The numbers are the human's

| Knob | Beta default | Means |
| --- | --- | --- |
| `JOHARNESS_MAX_MANAGERS` | 4 | managers in flight at once — money |
| `JOHARNESS_STALL_MINUTES` | 45 | no push for this long = cross-check, nudge |
| `JOHARNESS_HEALTH_MINUTES` | 10 | one orchestrator pass every this many |
| `JOHARNESS_RESPAWN_LIMIT` | 2 | respawns per item per orchestrator run |

Read by `dispatch`: the environment for one command, `joharness.conf` for
the repo, else the default. Digits only; a word reads as the default. The
defaults are written numbers — nobody has measured them — and they are
here so the first run has something to move rather than nothing. A
session proposes a change with a run's evidence; it never sets one
(`.agents/harness/AGENTS.md`, Decide alone: money).

## Bounds, unchanged

Every bound in [`unsupervised.md`](unsupervised.md) holds through
`unattended()`: protocol text off limits, step 7 conditions for every
merge, no requirement written by a session, nothing invented at the edge,
the prompt routes and the repository authorises. The orchestrator adds
its own: it merges nothing, edits nothing but a killed manager's
workstream file, picks no tier, and takes no item itself.

## Heartbeat

Same Routine as unsupervised, same operator action, same connector trap;
the prompt is `/orchestrate`. Firing over a live orchestrator is safe —
the new one finds the title `RUNNING` and exits. Firing over a dead one
is the point.

## What Gas Town gave this, and what it did not

Read at commit `649b832` for [`prior-art.md`](prior-art.md), re-read for
this mode. Taken: the split between a coordinator that dispatches (its
Mayor) and a monitor that nudges, hands off and kills (its Witness) — here
one role, two steps of one pass, because a repo-embedded harness has no
daemon to hold a second one; the health vocabulary; nudge before kill;
handoff as the thing that makes a session cycle survivable; a scheduler
cap so N items do not spawn N sessions at once; GUPP — a spawned session
executes what its prompt names, no announcing, no waiting. Not taken: the
ledger, the merge queue, the seance, integration branches, a persistent
worker pool — each with its reason in prior-art.

## Runs

| Run | Date | Wall-clock | Managers | Kills | Merged | Ended by |
| --- | --- | --- | --- | --- | --- | --- |
| none yet | | | | | | `docs/plans/orchestrated-run.md` is the first, and it is operator-gated |
