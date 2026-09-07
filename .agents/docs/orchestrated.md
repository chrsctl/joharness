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
| `./joharness.sh upstream` | New, and NOT orchestrated-only: reports what a merged edge found about the harness in any consumer, at any time. What this mode adds is a role that acts on it. |
| `JOHARNESS_UPSTREAM_FEEDBACK` | New, `off` by default. On, the health pass's `done` row spawns ONE reporter per merged edge, which files the findings as a report pull request on the canonical ([`feedback.md`](feedback.md), When the consumer is the detector). A reporter holds no manager slot and is one session beyond the cap. |
| `.claude/commands/orchestrate.md`, `manage.md`, `upstream-report.md` | The three roles, as commands. |

## Roles

| Role | Tier | Runs as | Spawns | Owns | Ends when |
| --- | --- | --- | --- | --- | --- |
| orchestrator | low, mechanical on purpose — the Routine's model: haiku by the ask, sonnet in the requester's diagram; a run decides | a session; the heartbeat fires one | manager sessions (`create_session`) | the cap, the health pass, the kill handover | dispatch says DRAINED with nothing in flight |
| manager | the item's `agent:` — plan or research; opus at xhigh for an unplanned requirement, decomposition being the judgement every build rests on | a session with its own branch, claim and merge | worker subagents (`Agent`) | one item, until its file retires | its pull request merges, or it blocks on a human |
| worker | at or below the plan's tier, lower by default | a subagent in the manager's container | nothing | the files its sub-task names | it returns |
| reporter | low; the judgement is its command file's gate, not its tier | a session, spawned after a manager MERGES — only where `JOHARNESS_UPSTREAM_FEEDBACK=on` | nothing | one merged edge's harness findings | it files one report on the canonical, or none, and exits |

### What each role reads

Every line injected at session start is paid by every session, and under
this mode most of the fleet-wide view is read by nobody: the orchestrator
gets the queue through `dispatch`, a manager works the one item its prompt
names. So session start prints the mode banner, the environment pointer,
and THIS branch's own workstream files — `HANDOVER_SCOPE=branch` in the
handover hook, which skips the walk over every remote ref — and no queue.

| Role | Reads | Never opens |
| --- | --- | --- |
| orchestrator | `dispatch`, the control plane, the Lineup table | a plan, a requirement, a research file, another branch's workstream file, this doc |
| manager | its item, its own workstream file, the item's anchors, `feedback` on the files it touches, the environment rules if it touches the environment | the queue, other plans, other branches, this doc |
| worker | its sub-task prompt and the files it names | everything else |

Two spawn levels, never three. A worker that needs a branch of its own is
a plan, and a plan enters the queue through a pull request — the manager
writes it into its own (`.agents/docs/plans/README.md`, same-session plan
handed off) and the orchestrator spawns it next pass. Subagents cannot
claim, get no hook state and die with the parent's turn
([`subagents.md`](subagents.md)); the manager's branch is the unit of
claim, and that is why the split falls where it does. A reporter is a second KIND of
session at the manager's level, not a third level below it: it is spawned by
the orchestrator, spawns nothing itself, and cuts no branch in this repo at
all — its one branch is on the canonical.

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
3. Spawn up to `slots`, in dispatch's order, skipping `HOLD`, `WAIT` and
   `NOT YOURS`.
4. Schedule the next pass; end the turn. A manager's "merged <stem>"
   message wakes a pass early, so a freed slot is filled at once rather
   than on the clock — where there is messaging. Where there is none, the
   scheduled pass is the only clock and the slot waits one pass.

Spawn = `create_session` with the repository attached, the item's tier
mapped to a model by [`agent-selection.md`](agent-selection.md) Lineup, a
title `manager: <stem>`, and a prompt carrying `/manage <path>`,
`./joharness.sh authority` and `./joharness.sh protocol-paths` — the three
things [`unsupervised.md`](unsupervised.md) Authority says a spawn prompt
carries, and nothing that asserts its own legitimacy.

## Health: two signals, one word each

The monitor rule under Heartbeat in [`unsupervised.md`](unsupervised.md):
never judge a session from one signal, because push time is not liveness
in either direction. So a verdict here needs both halves, and dispatch
prints only the git half.

| Word | Git (dispatch) | Control plane | Orchestrator does |
| --- | --- | --- | --- |
| working | any push age | `RUNNING`, or pushed inside the window | nothing |
| stalled | `STALL?` — no push for `JOHARNESS_STALL_MINUTES` | `RUNNING`, `status_detail` unchanged across two passes | pass 1 nudge, or nothing where there is no messaging; pass 2 kill |
| looping | `LOOP?` — one file rewritten `JOHARNESS_CHURN_LIMIT`+ times; or head moved on three passes with `next:` unchanged | any | kill with the record, respawn one tier up |
| crashed | branch unmerged; the git view says `in-progress`, which is what it says about every crash | `status_bucket` `..._FAILED` while `session_status` is not `RUNNING` | NO nudge — nothing is listening. Confirm once (`updated_at` and head both unchanged), then archive and respawn. **Read this row before the idle one**: one reading matches both |
| stillborn | no branch at all: the item is still under `spawn`, and the ledger says it was spawned a pass ago | `IDLE`/`PENDING` with NO `last_served_model` and NO `session_context.sources` — the session never ran a turn and has no checkout | no nudge, nothing to read it. Archive, then spawn the ITEM again — a plain spawn, nothing was claimed. **Read this row before the idle one**: one reading matches both |
| idle | branch unmerged, any push age | `IDLE` or `PENDING`, bucket not FAILED — **between turns, not gone** | pass 1 nudge and ledger; pass 2 respawn only if head AND `status_detail` are both unchanged |
| gone | branch unmerged, status in-progress / review / done, or an edge row IN FLIGHT that names an item | `ARCHIVED`, or no session found by title | respawn on the branch, no nudge. An edge row naming `?` is never respawned — no item, no successor's work |
| leftover | the branch is under `leftovers`: its item is already gone from the base branch, so that merge happened | any | NOT a merge to finish and never respawned — a successor would land on merged work with no pull request and no item. Report it; the human deletes the branch |
| blocked | status `blocked` | any | report to the human; never respawn |
| done | branch merged, plan file gone | any | nothing — or, with `JOHARNESS_UPSTREAM_FEEDBACK=on` and no `reported=` for it in the ledger, spawn ONE reporter |

**Gone is ARCHIVED, not found on the control plane, a FAILED bucket confirmed
by a second look, or a session that did not move across a nudge and a
confirming pass. Never IDLE on its own, never PENDING on its own** — IDLE
means between turns, and a manager that arms its own check-in reads IDLE for
the whole interval. Three fields, three different authorities:
`session_status` and `status_bucket` are the control plane's account of the
session and may decide liveness; `post_turn_summary.status_category` is the
SESSION'S own account of its TURN, so `completed` means its turn ended, never
that the work landed, and **it may never decide liveness on its own**; merge
state is git's (`git merge-base --is-ancestor`) and no summary's. Run 1 paid
for each of those sentences, in a duplicate manager and in a crash whose
recovery was outside the text (Runs, below, carries the cost and the
timestamps). The command file carries the same definition, the field table,
the row order and both worked readings
([`../../.claude/commands/orchestrate.md`](../../.claude/commands/orchestrate.md)).

A nudge is a message: push your workstream file now. Most stalls end there
— a session deep in a build has a handover it has not written, and
writing it is what the next session needs anyway.

Messaging is the one capability here the harness cannot promise, so the
loop is written to run without it. Absent, the stall costs the same two
passes and loses only the ask: the first pass writes the ledger entry and
sends nothing, the second kills if the head and the summary have still
not moved. The kill's own first step interrupts the session and lets its
Stop guard push — the same chance the nudge was giving it, harsher and
one pass later. What an operator loses is the warning band: with no
nudge, `JOHARNESS_STALL_MINUTES` is a kill threshold, and a fleet without
messaging wants it higher. The rule that shape belongs to is general and
is stated in `.claude/commands/orchestrate.md`: a name you cannot find is
a capability you do not have, not a reason to do nothing. Only
`create_session`, `send_later` and one liveness read stop the loop.

Measured, and the reason both files now say it: the first orchestrated
run in consumer `chrsctl/gx` at `afdd11d` (2026-09-06) stopped on
`send_message` — a name that was never in the Claude Code Remote MCP
server, because messaging is the harness's `SendMessage` — and dispatched
nothing while `./joharness.sh dispatch` printed `NOT DRAINED — 6 free
item(s) now (+28 waiting behind them), 4 slot(s)`. `ToolSearch
("+send_message")` returns nothing where `ToolSearch("+SendMessage")`
returns the tool: the lookup the file prescribed could not find the tool
the file needed.

### Loops are not stalls

A stall is silence. A loop is the opposite: pushes keep landing and the
same file keeps being rewritten, or `next:` never moves while the head
does. `ci` already has two tiers for this from the inside — a warning
from `JOHARNESS_CHURN_THRESHOLD`, the session's call; a red from
`JOHARNESS_CHURN_LIMIT`, not a call any more — and the review-churn rule
in [`agent-selection.md`](agent-selection.md) says what it means and what
to do. `LOOP?` sits on the limit, the warning band is named on the work
line, and the session inside the loop is the one that cannot see either.
The orchestrator can. A loop gets no nudge, because a nudge asks for a
push and a loop is pushing; it gets a kill with the progress recorded
first and a successor one tier up, told to do the research step before
any edit. The record's contents and the escalation are in
`.claude/commands/orchestrate.md`, LOOP — stated once, there.

"Across passes" is memory, and the orchestrator stores nothing in the
repo. The wake message carries the ledger: per item, the head and the
`next:` line last seen, the count of passes those disagreed, a nudge if
sent, respawns so far. A pass reads it out of the message that woke it
and writes the next one into the message it schedules — survives
compaction, because the message arrives fresh; leaves nothing in git,
because it lives in the schedule.

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
slot — their session exited on purpose. A manager past its retire commit
still holds one: step 7 deletes the workstream file as the last commit
before the pull request opens, so from there until the merge it owns a
branch, a pull request, CI and a container while owning no claim. The claims
view is right to drop it and `dispatch` counts the slot anyway — a claim
says who owns an item, a slot says what is committed, and one value cannot
answer both (`docs/plans/orchestrator-inflight-count.md`; the run that found
it is in Runs below, with its count). Whether that slot is REAL is decided in
git, and the discriminator is the item: still on the base branch means the
merge has not landed, hold it; gone means the merge already happened and the
branch is a leftover, listed and counted as nothing. Counting leftovers
stopped a fleet — five of them against a cap of 4, read `0 of 4 free` for as
long as they stood (`docs/plans/orchestrator-edge-slot-leak.md`). The control
plane says what to do about the session, never whether the slot is real.
Within the cap the order is the
queue hook's: urgent first, then oldest, partitioned into waves of
disjoint scope. Two things this mode adds to the wave rule:

- A free plan whose scope overlaps a plan a manager HOLDS is `HOLD`, not
  free. The peer fleet takes the collision and pays the reconcile at step
  7; an orchestrator that knows the collision is coming has no reason to
  send a manager into it. The hook computes it with the same
  `wave_split_hit` the waves use — a path only one side marked `shared:`
  collides here exactly as it does there — printed only in this mode.
- A hold behind a BLOCKED branch is released, the reconcile named as the
  cost: that branch waits on a human, a human's clock can be days, and a
  plan waiting on it starves with nothing in flight to end the wait.
- A wave-2 plan is `WAIT` while its wave-1 partner is free in the same
  pass: not counted as spawnable now, listed so the next pass finds it.
  A partner already IN FLIGHT is the `HOLD` case above instead — the waves
  partition free plans only, so an in-flight partner never puts a plan in
  wave 2. **A partner that is itself `HOLD` is out of the partition for the
  same reason**: it does not run this pass, so it cannot make another plan
  wait for it, and it carries no wave of its own. A hold *released* behind
  a BLOCKED branch does run, so that one stays partitioned and can still
  put a peer in wave 2.
- **An item at the edge is the same case, and the queue hook cannot see it.**
  A branch past its retire commit carries no workstream file, so the hook
  reads no claim and calls the plan free. `dispatch` withholds it from the
  spawn list all the same, so it must not be partitioned — and its peers are
  `HOLD`, not free: the branch has finished writing those paths and its pull
  request is open, which is the strongest reason there is to keep a manager
  off them. `dispatch` computes the set once and passes it to the hook as
  `QUEUE_WITHHELD`; nobody else sets it, so session start partitions exactly
  as it always did.
- `JOHARNESS_MAX_MANAGERS=0` is the human's pause, the one lever beside
  the Routine: dispatch says `PAUSED`, the orchestrator spawns nothing;
  with managers still in flight the health pass goes on until they end,
  then it exits.

The reconcile rate the peer fleet measured — about one merge in four
(`.agents/docs/product/README.md`, Orchestration) — is the number a run of
this mode should move. If it does not, the hold rule bought nothing.

## The numbers are the human's

| Knob | Default | Means | Where the default comes from |
| --- | --- | --- | --- |
| `JOHARNESS_MAX_MANAGERS` | 4 | managers in flight at once — money | p90 of branches active in one clock hour over every merge on `main`: median 2, p90 4, max 9 |
| `JOHARNESS_STALL_MINUTES` | 45 | no push for this long = cross-check, nudge | p95 of the gap between consecutive commits on one branch, rounded: median 4, p90 27, p95 44 minutes |
| `JOHARNESS_HEALTH_MINUTES` | 10 | one orchestrator pass every this many | between the median gap (4) and its p75 (12): a healthy manager's push lands inside one to three passes, a stall is seen within one window plus one pass |
| `JOHARNESS_RESPAWN_LIMIT` | 2 | respawns per item per orchestrator run | no data; a written number until a run counts one |
| `JOHARNESS_CHURN_THRESHOLD` | 5 | one file rewritten this often = a warning on the work line | `ci`'s own knob, backtested in [`agent-selection.md`](agent-selection.md): honest branches peak at 4. Raising it raises `ci`'s ceiling too |
| `JOHARNESS_CHURN_LIMIT` | 2x the threshold | one file rewritten this often = `LOOP?`; 0 lifts it | `ci`'s own ceiling, the same knob |
| `JOHARNESS_UPSTREAM_FEEDBACK` | `off` | on = one reporter session per merged edge, beyond the cap, filing harness findings on the canonical — money, and pull requests in a repo this one does not own | not a number to calibrate: a switch, off until a human turns it on. Unlike the six above it IS declared in `.agents/scripts/conf-keys.sh`, so every consumer's sync names the key its conf does not answer |

Read by `dispatch`: the environment for one command, `joharness.conf` for
the repo, else the default. Digits only; a word reads as the default. The
two churn knobs go through the same reader in `ci`, so a value set in the
conf means there what it means here — it did not, for one round, and the
conf's own comment was what documented the trap into existence.

**A consumer gets these as prose and nothing else.** They are deliberately
absent from `.agents/scripts/conf-keys.sh`, which drives the bootstrap
interview: four questions about a beta mode the interview never offers is
the wrong cost to put on every new consumer. The consequence is that a
consumer's `joharness.conf` carries no knob block at all — canonical's
comments are not synced — so THIS TABLE is the record, and an operator
enabling the mode there writes the lines by hand. Revisit when the mode
leaves beta. A
session proposes a change with a run's evidence; it never sets one
(`.agents/harness/AGENTS.md`, Decide alone: money).

The first three were counted on `origin/main` 2026-09-05, the last 200
merges, 530 commit gaps, 137 active hours, with this and nothing else —
commit time stands in for push time, which git does not keep. Nearest
rank: the value at rank ceil(p x N).

```bash
git rev-list --merges --first-parent -200 origin/main | while read -r m; do
  set -- $(git rev-list --parents -n1 "$m"); [ $# -ge 3 ] || continue
  git log --no-merges --format="$m %ct" "$(git merge-base "$2" "$3")..$3"
done > /tmp/commits.txt
pct='function r(p){ i=int(NR*p); if (i<NR*p) i++; return a[i] }'
sort -k1,1 -k2,2n /tmp/commits.txt |
  awk '$1==p {print ($2-t)/60} {p=$1; t=$2}' | sort -n |
  awk "{a[NR]=\$1} $pct END {printf \"gaps=%d median=%.0f p90=%.0f p95=%.0f\n\", NR, r(.5), r(.9), r(.95)}"
awk '{print int($2/3600), $1}' /tmp/commits.txt | sort -u | cut -d' ' -f1 |
  uniq -c | awk '{print $1}' | sort -n |
  awk "{a[NR]=\$1} $pct END {printf \"hours=%d median=%d p90=%d max=%d\n\", NR, r(.5), r(.9), a[NR]}"
```

Measured on the peer fleet, which is the only fleet that has run: what a
cap of 4 costs in reconciles under an orchestrator is the run's to say.

## Bounds, unchanged, plus one path

Every bound in [`unsupervised.md`](unsupervised.md) holds through
`unattended()`: protocol text off limits, step 7 conditions for every
merge, no requirement written by a session, nothing invented at the edge,
the prompt routes and the repository authorises. The orchestrator adds
its own: it merges nothing, edits nothing but a killed manager's
workstream file, picks no tier, and takes no item itself.
`JOHARNESS_UPSTREAM_FEEDBACK` does not loosen one of them — a reporter is a
SPAWN, like a manager, and the orchestrator authors no report.

`joharness.conf` joined `protocol_paths` with this mode. It holds the
mode line `authority` verifies and the cap: a session that may rewrite
its own mode line authorises itself, and one that may raise its own cap
decides money. Priced and accepted: `./joharness.sh env <name>` writes
that file too, so an unattended session that switches its environment
layer now trips the Stop guard until it reverts. Switching layers is a
configuration decision, which is the supervised half of the same split. Found the day the mode was built — the plan that flips the
mode for the measured run declared `scope: docs/product, joharness.conf`,
and with the conf outside the boundary `dispatch` offered that plan to the
very fleet it would have flipped. Both roles run `authority` first, and
`orchestrated` with any verdict but VERIFIABLE is a stop, not a beta path:
"a human invoked this" is a claim the session cannot check, which is the
sentence under Authority in the same file.

## Heartbeat

Same Routine as unsupervised, same operator action, same connector trap;
the prompt is `/orchestrate`. Firing over a live orchestrator is safe —
the new one finds the title `RUNNING` and exits. Firing over a dead one
is the point.

## What was read before this was designed

[Gas Town](https://github.com/gastownhall/gastown) (Steve Yegge, MIT), at
commit `649b832`, its own docs only — never run, code not audited. Ideas
taken, adapted, no text reproduced (`.agents/NOTICE`):

- Its coordinator and its per-project monitor are two long-running
  agents, one dispatching and one nudging, handing off and cleaning up
  (`README.md`, Mayor and Witness). Here one role, two steps of one pass:
  a repo-embedded harness has no daemon to hold a second agent, and a
  second watcher is a second thing to watch.
- It treats a worker's session ending as normal and its work as safe
  because the worktree and the assignment persist past the session
  (`docs/concepts/polecat-lifecycle.md`). Here the branch persists and
  the workstream file is the assignment; the kill comes after that file
  is written, by the manager or by the orchestrator.
- Its worker health words — working, idle, done, stalled, zombie (same
  file, Operating States). Here working, stalled, looping, gone, blocked,
  done: `blocked` is a state its table lacks, a session that stopped on
  purpose for a human, and it must never be respawned.
- Its dispatch cap, added after N assignments spawned N workers at once
  and hit rate limits (`docs/design/scheduler.md`, Overview). Here the
  cap is the human's number.
- Its rule that a worker finding work assigned to it executes at once,
  without announcing itself and waiting
  (`docs/concepts/propulsion-principle.md`). Here the spawn prompt is
  that assignment.

Not taken, and the arguments for this repo's own choices are in the
documents that own them: a queryable work ledger and a long-running
service (`graph.md`), integration branches and a merge queue
(`product/README.md`, Branch flow), querying a dead session
(`handover/README.md`), a named persistent worker pool — identity here is
the branch and the workstream file, attribution is the commit, and a pool
is state outside git.

## Runs

| Run | Date | Wall-clock | Managers | Kills | Merged | Ended by |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 2026-09-06 | 5h37m | 10 | 0 | 8 | a human turn, per the plan's own rule |

**Run 1**, consumer `chrsctl/gx`, cap 4, no heartbeat — one orchestrator's
lifetime, which is what the plan said a run without a Routine would measure.
12:05:05Z (session created) to 17:42Z (first human turn; `orchestrated-run.md`
says a human turn ends the measurement there). 28 health passes at
`JOHARNESS_HEALTH_MINUTES=10`.

Counted from the orchestrator's own passes: **10 managers** spawned in window
(an 11th at 17:52Z falls outside it); **0 kills**, **0 nudges**; **2
respawns**, one sound and one not; **8 merged** — `workflow-outbound-http`,
`workflow-state-machine-scope`, `permission-system-at-ten-thousand-seats`,
`comms-openapi-connector` (#291), `extension-code-surface` (#293),
`drive-slides-editor`, `ui-storyboard` (#295 / `30b845cb`),
`crm-aggregate-reasoning` (#296 / `4a4f3cc0`); **1 item blocked on the human**
and still open at the end. Cost **≥437 USD**, summed from `get_session`'s
`usage.cost_usd` last observed per session, 9 of the 10 seen — last-observed
values, not finals, so it is a floor.

**Nothing stopped it; the queue did not drain.** At the end 30 plans waited
behind one branch in flight. From roughly 13:00Z the fleet was overlap-bound,
not slot-bound: passes 11 through 17 spawned nothing while 2 to 3 slots sat
idle, because every free plan overlapped a claimed one on `docs/adr`,
`docs/phases` or `tools/criteria/index.py`. That is the number this run
actually produces — against this queue the cap of 4 was never the binding
constraint, and raising it would have changed nothing.

**Two defects, filed as plans rather than patched** (this plan's Out of
scope): `docs/plans/orchestrator-inflight-count.md` — `dispatch` frees a live
manager's slot for the whole PR window and re-offers its item, hit on 11 of
28 passes; and `docs/plans/orchestrator-respawn-liveness.md` — the health
table reads IDLE as *session gone* and respawns on one observation, which
cost one duplicate manager and about 17 USD. Both were survivable only
because the orchestrator cross-checked the control plane every pass and
disbelieved `dispatch` when the two disagreed. **A role told to act on one
read, which must override that read on 39% of its passes to avoid
overspending the cap, is the finding under both.**

What run 1 did NOT show: no heartbeat, so nothing about a fleet outliving its
orchestrator; no kill and no nudge fired, so those paths are still unmeasured;
one consumer, one queue shape, and that queue's overlap density is doing most
of the work in the throughput number above.

**Run 2, in flight, one observation** — the run is not over and its row is
not written yet. 2026-09-07, consumer `chrsctl/gx`: a manager spawned at
10:13:29.630Z came up having never run a turn — no `last_served_model`, no
`session_context.sources`, `updated_at` frozen six seconds after
`created_at` through three reads to 10:26Z — and cut no branch, so it was in
no in-flight row and the health pass, which walks dispatch's list, never
looked at it. Its item stayed in `spawn` as `wave 1` the whole time. That is
the `stillborn` row above, and the two field names in it; the run's own
numbers wait for the run.
