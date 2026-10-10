# How the harness runs

One mode. No human is present: ONE controller sits above the queue — a
low-tier orchestrator session reads it, spawns a manager per item under a cap,
watches them, and kills a stuck one after its handover is written. The role
files carry the operative rules: [`orchestrate.md`](../../.claude/commands/orchestrate.md)
and [`manage.md`](../../.claude/commands/manage.md). This page says what the
pieces are and why the bounds sit where they do.

Role, health and dispatch ideas adapted from
[Gas Town](https://github.com/gastownhall/gastown) (Steve Yegge, MIT), read at
commit `649b832` — docs only, no text reproduced (`.agents/NOTICE`).

## How the harness runs

| Where | What it does |
| --- | --- |
| `joharness.sh:unattended` | The ONE predicate the boundary, the marking and `authority` read. |
| `session-start` banner | Routes by role: prompt names `/manage <item>` = manager; nothing named = orchestrator, run `/orchestrate`. Prints the core-path boundary. |
| Queue hook | Marks a plan with ANY core path (`./joharness.sh protocol-paths`) in `scope:` and ranks it out of the free list. Prints `in flight: <free> overlaps <claimed> on <path>` per collision with a held plan. |
| `./joharness.sh dispatch` | The orchestrator's one read: the human's numbers, managers in flight with push age and marks (`STALL?`, `LOOP?`, `CEILING?`), slots under the cap, the spawn order with waves and `HOLD`s, the cycle lines, one verdict. Reports only. |
| `dispatch` verdict `OVERLAP-BOUND` | Slots free but every free plan HELD behind work in flight. A `rescope :` block names the holder key and the held paths; the verdict spawns ONE surveyor to correct the `scope:` declarations. |
| `./joharness.sh curate` + `curate :` line | Whether the plan queue's declarations are still true. Mechanical repairs: `./joharness.sh curate --apply`, and `ci` fails a branch whose added or edited plans still need one. A curator session is offered only for PROPOSE findings (decompose, order). Due on plan churn (`JOHARNESS_CURATE_PLANS`) or the clock; state read from git. Orthogonal to the verdict. |
| `./joharness.sh janitor` + `janitor :` line | Claims whose session is gone. Mechanical: `./joharness.sh janitor --apply` writes `status: abandoned` into the claim's own file — only where the session is ARCHIVED or not found, never a claim with `pr:` — and deletes nothing. No session, no pull request. Clock-driven (`JOHARNESS_JANITOR_HOURS`). |
| `./joharness.sh clerk` + `clerk :` line | Open issues become plans only through the clerk (`dispatch` reads `docs/plans/` only). Clock-driven, batch `JOHARNESS_CLERK_BATCH`, dated from git. Orthogonal to the verdict. |
| `./joharness.sh upstream` | What a merged edge found about the harness. With `JOHARNESS_UPSTREAM_FEEDBACK=on` the health pass's `done` row spawns ONE reporter per merged edge, which files the findings as a report pull request on the canonical ([`feedback.md`](feedback.md)). |
| `./joharness.sh analysis` | One unmerged branch's condition (BLOCKED / STALL? / LOOP?) beside the base branch's current conf. With `JOHARNESS_IDLE_ANALYSIS=on` a row `dispatch` marks `ANALYSE?` spawns ONE analyst — BESIDE that row's verdict, never instead of it. |
| `./joharness.sh scout` + `scout :` line | GATED on `DRAINED — nothing free, nothing in flight`: new work competes with real work. Clock-driven (`JOHARNESS_SCOUT_HOURS`). Every misread fails closed — holds the cycle, never spawns a second scout. |
| `.claude/commands/*.md` | The roles, as commands. |

## Roles

| Role | Tier | Runs as | Spawns | Owns | Ends when |
| --- | --- | --- | --- | --- | --- |
| orchestrator | low, mechanical on purpose | a session; the heartbeat fires one | manager sessions (`create_session`) | the cap, the health pass, the kill handover | dispatch says DRAINED with nothing in flight |
| manager | the item's `agent:`; fable at xhigh for an unplanned requirement | a session with its own branch, claim and merge | worker subagents (`Agent`) | one item, until its file retires | its pull request merges, or it blocks on a human |
| worker | at or below the plan's tier, lower by default | a subagent in the manager's container | nothing | the files its sub-task names | it returns |
| reporter | low | a session, after a manager MERGES — only where `JOHARNESS_UPSTREAM_FEEDBACK=on` | nothing | one merged edge's harness findings | it files one report on the canonical, or none |
| analyst | low | a session, on a row marked `ANALYSE?` — only where `JOHARNESS_IDLE_ANALYSIS=on` | nothing | one condition on one branch, explained and never ended | it files one issue on the canonical, or none |
| curator | sonnet | a session, on `curate DUE` with proposals to make | nothing | decompose/order proposals for ONE pass, changing no plan | its pull request merges |
| surveyor | sonnet | a session, on the `OVERLAP-BOUND` verdict | nothing (declarations, not code) | the held plans' and holders' `scope:` lines for one holder key | its pull request merges, or `done` with nothing to change |
| clerk | opus | a session, on the `clerk DUE` tail line | nothing | one plan-only pull request; never closes or opens an issue, never writes code | its pull request merges, a retire-only one, or `TWIN: deferred` |
| scout | fable | a session, on `scout DUE`, only under `DRAINED — nothing free, nothing in flight` | nothing | one proposal pull request, a `docs/product/<stem>.md` | the human merges or closes it — or `JOHARNESS_SCOUT_AUTOMERGE=on` and it merges itself — or `NOTHING TO PROPOSE` |

Reporter, analyst, curator, surveyor, clerk and scout hold no
manager slot: each is one session beyond the cap — the human's money, reported.
A role command that says nothing to do spawns nothing.

### What each role reads

Session start prints the banner, the environment pointer and THIS branch's
workstream files (`HANDOVER_SCOPE=branch`) — no queue. Every line injected is
paid by every session.

| Role | Reads | Never opens |
| --- | --- | --- |
| orchestrator | `dispatch`, the control plane, the Lineup table | a plan, a requirement, a research file, another branch's workstream file, this doc |
| manager | its item, its own workstream file, the item's anchors, `feedback` on files it touches, the environment rules if it touches them | the queue, other plans, other branches, this doc |
| surveyor | the `rescope :` block in its prompt, and the `## Scope` of each plan it renames | the queue, product code, this doc |
| curator | `./joharness.sh curate` and the plans it names | a held plan, the queue order, product code, this doc |
| analyst | `./joharness.sh analysis <branch>`, that branch's workstream file, the conf delta the command prints | the queue, a plan, product code, another branch, this doc |
| clerk | `./joharness.sh clerk`, the open issues, the source each issue cites | the queue order, another branch, product code beyond what an issue cites, this doc |
| scout | `./joharness.sh scout` and the evidence it lists — `review`, `feedback`, canonical issues, session cost, a dated release-note or Models API read | a plan, the queue order, product code, another branch's code |
| worker | its sub-task prompt and the files it names | everything else |

Two spawn levels, never three. A worker that needs a branch of its own is a
plan, and enters the queue through the manager's pull request
(`.agents/docs/plans/README.md`, same-session plan handed off). Subagents
cannot claim, get no hook state and die with the parent's turn
([`subagents.md`](subagents.md)).

The default role is the orchestrator: the heartbeat's prompt is standalone,
and a manager is told what it is by the orchestrator that spawned it. Two
orchestrators are the collision to avoid: a `RUNNING` session titled
`orchestrator: <repo>` that is not you = exit.

## The loop

Every `JOHARNESS_HEALTH_MINUTES`, scheduled with `send_later` — never a
sleep, never a poll:

1. `./joharness.sh dispatch`.
2. Health pass over every manager in flight. Kills and respawns happen here,
   before any spawn.
3. Spawn up to `slots`, in dispatch's order, skipping `HOLD`, `WAIT` and
   `NOT YOURS`.
4. Schedule the next pass; end the turn.

A merge is read from git — the branch head is an ancestor of `origin/main`,
and dispatch stops listing it. No message is needed for it; a freed slot is
filled on the next pass.

"Across passes" is memory, and the orchestrator stores nothing in the repo.
The wake message carries the ledger — in-flight items only; git holds what
merged. It survives compaction because the message arrives fresh.

## Health: two signals, one verdict

Push time is not liveness in either direction, so a verdict needs both
halves: git (dispatch) and the control plane.

| Word | Git (dispatch) | Control plane | Orchestrator does |
| --- | --- | --- | --- |
| working | any push age | `RUNNING`, or pushed inside the window | nothing |
| stalled | `STALL?` — no push for `JOHARNESS_STALL_MINUTES` | `RUNNING`, `status_detail` unchanged across two passes | pass 1 nudge; pass 2 kill |
| looping | `LOOP?` — one file rewritten `JOHARNESS_CHURN_LIMIT`+ times; or head moved three passes with `next:` unchanged | any | kill with the record, respawn one tier up |
| crashed | branch unmerged | `status_bucket` `..._FAILED` while `session_status` is not `RUNNING` | NO nudge. Confirm once, then archive and respawn. **Read before idle** |
| stillborn | ledger entry still `new` from a previous pass | `IDLE`/`PENDING`, NO `last_served_model`, NO `session_context.sources`, confirmed by a second read | archive, spawn the ITEM again (plain spawn), counted against the respawn limit. **Read before idle** |
| blocked before claim | ledger entry still `new` | `status_bucket` `..._BLOCKED`, `session_status` not `IDLE`/`PENDING`/`ARCHIVED`, confirmed by a second read | interrupt, archive, spawn the ITEM again, counted. Item gone, at the limit, or no `interrupt_session`: report only |
| unclaimed | ledger entry still `new` | `last_served_model` present — it ran and stopped without claiming | report; never respawn, a successor repeats it |
| gone before claim | ledger entry still `new` | `ARCHIVED`, or no session by title | report, keep the entry; the human decides |
| idle | branch unmerged | `IDLE` or `PENDING`, bucket not FAILED — **between turns, not gone** | pass 1 nudge; pass 2 respawn only if head AND `status_detail` both unchanged |
| gone | branch unmerged, claimed, or an in-flight edge row naming an item | `ARCHIVED`, or no session by title | respawn on the branch, no nudge. An edge row naming `?` is never respawned |
| leftover | under `leftovers`: its item already gone from the base branch | any | never respawned; report, the human deletes the branch |
| blocked | status `blocked` | any | report; never respawn |
| done | branch merged | any | drop the ledger entry — or, with `JOHARNESS_UPSTREAM_FEEDBACK=on` and no `reported=` for it, spawn ONE reporter |

**Gone is ARCHIVED, not found on the control plane, a FAILED bucket confirmed
by a second look, or a session that did not move across a nudge and a
confirming pass. Never IDLE on its own, never PENDING on its own** — a manager
that arms its own check-in reads IDLE for the whole interval.
`post_turn_summary.status_category` is the session's account of its TURN and
never decides liveness; merge state is git's (`git merge-base
--is-ancestor`), never a summary's.

`updated_at` decides nothing alone, at any interval. On an `IDLE` row it is
the age of the last activity; on a `RUNNING` row a frozen value reads the same
whether the writer is slow or the session stopped (measured: every field of a
row byte-identical for 172s). What turns a suspicion into a verdict is
`status_bucket` plus the head from git.

**And push age is not death either.** Push age is the tip commit date, and a
stopped manager and a stopped fleet both freeze it (issue #283: an
orchestrator back from an 18-day suspension read three live managers as 434h
stalled). A row built on push age may ask for a control-plane read and may
order nothing. Dispatch's `suspect a stopped fleet` tail line decides nothing.

### Messaging

A nudge is a message: push your workstream file now. Two transports, one per
kind of target: Claude Code Remote `send_message` addressed by the
`session_id` `create_session` returned, and the harness `SendMessage`
addressed by a `ListAgents` row. `ListAgents` can be empty while
`send_message` by `session_id` delivers (issue #347), so no peer row is not
"no messaging". The delivery result, never tool presence, says a nudge was
sent.

Without messaging the loop still runs: a stall costs the same two passes and
loses only the ask; the kill's interrupt gives the Stop guard the same chance
to push. `JOHARNESS_STALL_MINUTES` is then a kill threshold — an operator may
want it higher. A name you cannot find is a capability you do not have, not a
reason to do nothing: only `create_session`, `send_later` and one liveness
read stop the loop.

### Loops are not stalls

A stall is silence. A loop is pushes landing while the same file is
rewritten, or `next:` never moving while the head does. `ci` warns at
`JOHARNESS_CHURN_THRESHOLD` and reds at `JOHARNESS_CHURN_LIMIT`; `LOOP?` sits
on the limit. A loop gets no nudge (it is pushing); it gets a kill with the
progress recorded and a successor one tier up, told to do the research step
first ([`agent-selection.md`](agent-selection.md), review churn).

### `CEILING?` is a report

`JOHARNESS_MANAGER_HOURS` marks a mid-build claim (`in-progress`, no `pr:`)
older than that many hours. The orchestrator reports the age and `cost_usd`
and never acts on the mark alone: neither git nor `IDLE` says a manager is
between runs, so archiving ends whatever is in flight. A manager gone quiet at
the finish is already the STALL and IDLE rows' respawn. Refreshing a live,
pushing manager is the human's call.

## The kill, and why the handover comes first

A killed session with no handover strands a branch the successor cannot read.

1. Interrupt. The Stop guard fires; it may push.
2. One pass later: head or `updated:` moved = the handover landed.
3. Else the orchestrator writes it — the one file this role ever writes: a
   note under `## Blockers` and a `next:` that says resume. Pushed.
4. Archive. Spawn a successor on the SAME branch. Past
   `JOHARNESS_RESPAWN_LIMIT` the branch stays claimed and the human is told.

The branch is the claim and the claim survives the kill.

## Concurrency

`JOHARNESS_MAX_MANAGERS` caps managers in flight. Blocked managers hold no
slot. A manager past its retire commit still holds one — it owns a branch, a
pull request, CI and a container, but no claim. Whether that slot is real is
decided in git by the item: still on the base branch = merge pending, hold
it; gone = leftover, counts as nothing. Within the cap the order is the queue
hook's: urgent first, then oldest, in waves of disjoint scope. On top:

- A free plan whose scope overlaps a plan a manager HOLDS is `HOLD`
  (same `wave_split_hit` as the waves): no reason to send a manager into a
  known collision.
- A hold behind a BLOCKED branch is released, reconcile named as the cost — a
  human's clock can be days.
- A wave-2 plan is `WAIT` while its wave-1 partner is free in the same pass.
  An in-flight partner is `HOLD` instead; a `HOLD` partner is out of the
  partition.
- An item at the edge (past retire, no workstream file) is withheld from the
  spawn list and its peers are `HOLD`; `dispatch` passes the set to the hook
  as `QUEUE_WITHHELD`.
- `JOHARNESS_MAX_MANAGERS=0` is the human's pause: `PAUSED`, nothing spawned,
  the health pass runs until in-flight managers end.
- Every free plan held with slots idle = `OVERLAP-BOUND`. Most such
  collisions are a plan that only appends to a shared registry, or claims a
  whole directory, declared exclusive. ONE surveyor per holder key per run
  (`manage.md`, R) marks registries `shared:` and narrows directory claims;
  genuine collisions settle in one pass.
- The curate cycle is the one spawn not driven by the queue's state: due on
  plan churn or the clock, under any verdict, one at a time, state in git so a
  re-seeded orchestrator does not re-spawn one already paid for. Repairs
  never need a session: `curate --apply`.

### A plan the queue cannot see

Queue items come from the base branch only. A plan filed on an unmerged
branch has no row: not free, not held, not in flight.

| Shape | Answer | Where |
|---|---|---|
| plan-only pull request | filer drives it to merged before exit | `manage.md`, Finish |
| plan riding a product pull request | row in dispatch's `plans on a branch` block — visible, counted nowhere | `joharness.sh:dispatch_branch_plans` |
| author gone | not answered — accepted gap | — |

The row carries no instruction: the scheduler cannot see a pull request, and
a branch plan has not been reviewed into the queue, so spawning on it is the
human's call (`URGENT` leads the report). The reader drops the plan the
branch's own workstream file claims and every plan on an `abandoned` branch;
one row per stem.

**A spawn the human orders carries the plan, never takes the branch.** The
manager cuts its own branch from the base, copies the plan file across, and
pushes nothing to the owner's branch. Hazard: once the owner's branch merges,
the retired plan comes BACK (its side still adds it against a base that never
had it). The PR body says so; the owner drops it at reconcile.

## The numbers are the human's

| Knob | Default | Means | Basis |
| --- | --- | --- | --- |
| `JOHARNESS_MAX_MANAGERS` | 4 | managers in flight at once — money | p90 of branches active in one clock hour on `main` |
| `JOHARNESS_STALL_MINUTES` | 45 | no push this long = cross-check, nudge | p95 gap between commits on one branch (44m) |
| `JOHARNESS_HEALTH_MINUTES` | 10 | one orchestrator pass every this many | between median commit gap (4) and its p75 (12) |
| `JOHARNESS_RESPAWN_LIMIT` | 2 | respawns per item per orchestrator run | written number |
| `JOHARNESS_MANAGER_HOURS` | 4 | claim older than this, no pull request = `CEILING?` report; 0 lifts it | one consumer run (issue #298) |
| `JOHARNESS_CHURN_THRESHOLD` | 5 | one file rewritten this often = warning | `ci`'s knob; honest branches peak at 4 |
| `JOHARNESS_CHURN_LIMIT` | 2x threshold | one file rewritten this often = `LOOP?` and `ci` red; 0 lifts it | `ci`'s ceiling |
| `JOHARNESS_CURATE_PLANS` | 10 | plan files added or changed since the last curate = due | plan production is bursty; written number |
| `JOHARNESS_CURATE_HOURS` | 168 | hours since the last curate = due (anchors rot with no plan changing); 0 switches the cycle off | written number |
| `JOHARNESS_CURATE_REGISTRY` | 3 | plans declaring one path before `curate` calls it a registry | written number |
| `JOHARNESS_CURATE_SPLIT` | 8 | `## Scope` bullets before `curate` proposes a decompose | written number |
| `JOHARNESS_JANITOR_HOURS` | 12 | hours between claim sweeps; 0 = off | requester's number |
| `JOHARNESS_SCOUT_HOURS` | 168 | hours between scouts, only at DRAINED; 0 = off | written number |
| `JOHARNESS_SCOUT_AUTOMERGE` | off | exactly `on` lets a scout merge its own proposal | a switch: money and product direction in one conf line |
| `JOHARNESS_UPSTREAM_FEEDBACK` | off | on = one reporter per merged edge, beyond the cap, filing on the canonical | a switch; declared in `.agents/scripts/conf-keys.sh` |
| `JOHARNESS_IDLE_ANALYSIS` | off | on = one analyst per condition per item per run, beyond the cap, filing an issue on the canonical | a switch; declared in `.agents/scripts/conf-keys.sh` |

None of these is an `updated_at` threshold — one cannot be written (Health,
above). Read by `dispatch` (and the churn pair by `ci`) from the environment
for one command, `joharness.conf` for the repo, else the default; digits only.
A consumer gets the numbers as prose only — they are not in
`.agents/scripts/conf-keys.sh`. A session proposes a change with a run's
evidence; it never sets one (`.agents/harness/AGENTS.md`, Decide alone).

## Bounds

The rules that bind every session.

- **The core paths are off limits to a session running**: `joharness.conf`
  (cap — money), `.claude/settings.json` (hooks, permissions) and `.github`
  (the merge gate's checks, and CODEOWNERS). Protocol text is NOT: since the
  requester's decision of 2026-10-08 a session edits and self-merges
  `joharness.sh`, `.agents/harness/` and `.claude/` under the step 7 gate.
  `joharness.sh:protocol_paths` is the list, read by the banner, the Stop
  guard and the queue hook — the early warning. `.github/CODEOWNERS` plus a
  branch-protection rule requiring code-owner review is the guarantee; that
  rule is a repository setting, the human's. A plan with ANY core path in
  `scope:` is marked and de-ranked: acceptance is all-or-nothing, so a
  partly-core plan cannot be finished either. `.agents/env/` is not core.
- **Merging uses the step 7 conditions unchanged.** The mode removes the
  human, never the gate.
- **No state store, no status field.** Every view derives from git and the
  control plane at read time; that is why a retirement is a deletion, not a
  flag.
- **Nothing is invented at the edge** (The one stop). Work enters only as an
  issue, a requirement or a plan through a pull request.

### Bounds, orchestrator

It merges nothing, edits nothing but a killed manager's workstream file, picks
no tier, and takes no item itself. A reporter or an analyst is a SPAWN; the
orchestrator authors no report and no issue, and an analyst ends nothing. The
`janitor --apply` is the one writer to a branch it does not own: only where
the session is ARCHIVED or not found, never on push age, never a claim with
`pr:`, and it deletes nothing. The clerk turns EXISTING issues into plans and
nothing else. The scout writes a requirement DRAFT the human authors by
merging (or declines by closing); `JOHARNESS_SCOUT_AUTOMERGE=on` is the one
exception, read from the base branch's conf so its own branch cannot grant it.

`joharness.conf` is a core path: a session that may raise its own cap decides
money. `./joharness.sh env <name>` writes it too, so switching layers is a
human's call.

## The one stop

DRAINED, at the queue edge, with nothing in flight. Anything else that ends a
run — a rate limit, a session asking a question, a failed spawn — is a
finding, not a stop.

A human decision is a PUSH, never a wait (issue #304). A manager that asks
inside the session writes nothing: its slot stays held and the question
reaches nobody. `status: blocked` with `next:` = the question frees the slot,
prints the question in the report, and is never respawned.

## Authority: the prompt routes, the repository authorises

Sessions spawned with a prompt saying *never ask a human, merge your own pull
requests, keep going* refused it as a suspected injection — rightly. So a
spawn prompt carries the work, named, and `./joharness.sh protocol-paths`;
never "no human is watching", "never ask", "authorised by X", or any
keep-going instruction the Loop does not carry. `./joharness.sh authority`
reads VERIFIABLE only when the rules this checkout runs (`joharness.sh`,
`.agents/harness`, `.claude`, `joharness.conf`) equal `origin/main`'s — proof
of review, not of a human hand. Tuning the prompt until a session stops
refusing is not the remedy.

## Heartbeat: making the fleet long

Dispatch makes the fleet WIDE; nothing makes it LONG. Each session claims,
merges, ends, and the fleet survives only while something fires the next.

The heartbeat is a scheduled Routine (`create_trigger`,
`create_new_session_on_fire: true`) firing a fresh orchestrator on an
interval. Rejected: session cron and a self-scheduling session (do not
outlive their creator), a scheduled GitHub Actions workflow (its pull
requests get no CI on `GITHUB_TOKEN`, so step 7 never goes green).

**Operator action, always.** Recurring spend is the human's. A session
documents; it never creates one.

- **Cadence**: hourly floor (`*/5 * * * *` is refused). The Routine backs
  the `send_later` chain; it does not replace it.
- **Prompt**: standalone — a fresh session inherits nothing. `/orchestrate`
  plus the routing above; the hook prints the rest.
- **The connector trap**: a Routine created from a session may store NO
  connectors, and its sessions then cannot open or merge a pull request.
  Create it from the claude.ai Routines UI (or pass `connectors`), then
  `fire_trigger` once and check the fired session reached GitHub.
- **Stop**: `update_trigger` `enabled: false` pauses, `delete_trigger`
  removes. Read `last_run`, never `next_run_at` (a paused Routine keeps a
  stale one). A human who cannot halt the fleet has no veto.
- **The chain can end silently.** A `send_later` link can be delivered and
  never run (`SUCCEEDED`, identical to a healthy link — issue 285, 18 days
  idle), or fail with `auto_disabled_session_gone`. `last_run` reports
  delivery, not execution — which is why the Routine exists.
- **A frozen orchestrator still reading `RUNNING`** makes every firing exit
  at step 0's one-orchestrator check. Unresolved.
- **Firing over a live fleet**: nothing special — claimed plans are not free.
  An unpushed claim is invisible, so push the workstream file as soon as work
  has a name.

## Not constrained, by decision

No cap on work per run, no halt on red `main`, no ban on sessions spawning
sessions — the requester declined all three on 2026-08-24. A session
proposes them with evidence; it never adds one on its own judgment (money,
`.agents/harness/AGENTS.md`, Decide alone). The lever is the Routine pause.
