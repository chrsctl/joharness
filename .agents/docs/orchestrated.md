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
| `dispatch` wait line | Under any `DRAINED` verdict, when `CORE ONLY` plans wait: `<n> plan(s) wait on a human core edit (oldest <d>d): <stems>`. The verdict word is unchanged; the orchestrator reports the line and pushes each stem to the human once per run. Never on `NOT DRAINED`, `OVERLAP-BOUND` or `PAUSED`. |
| `dispatch` verdict `OVERLAP-BOUND` | Slots free but every free plan HELD behind work in flight. A `rescope :` block names the holder key and the held paths; the verdict spawns ONE surveyor to correct the `scope:` declarations. |
| `./joharness.sh curate` + `curate :` line | Whether the plan queue's declarations are still true. Mechanical repairs: `./joharness.sh curate --apply`, and `ci` fails a branch whose added plans still need one. A curator session is offered only for PROPOSE findings (decompose, order). Due on plan churn (`JOHARNESS_CURATE_PLANS`) or the clock; state read from git: the last curate landing, or a newer merged `curate-noop-<stamp>` branch (a pass with nothing to propose), which resets both triggers. Orthogonal to the verdict. |
| `./joharness.sh janitor` + `janitor :` line | Claims whose session is gone. Mechanical: `./joharness.sh janitor --apply` writes `status: abandoned` into the claim's own file — only where the session is ARCHIVED or not found, never a claim with `pr:` — and deletes nothing. No session, no pull request. Listed only when stale claims exist; the caller proves each session gone and passes the branches: `janitor --apply <branch>...`. |
| `./joharness.sh clerk` + `clerk :` line | Open issues become plans only through the clerk (`dispatch` reads `docs/plans/` only). Clock-driven, batch `JOHARNESS_CLERK_BATCH`, dated from git: the last `clerk-<digit>…` merge on the base's first parent (GitHub's default merge subject), or a newer `clerk-noop-<stamp>` branch. An unmerged `clerk-<digit>…` branch younger than `JOHARNESS_CLERK_STALE_HOURS` is in flight and takes a slot, due or not. Orthogonal to the verdict. |
| `./joharness.sh analysis` | One unmerged branch's condition (BLOCKED / STALL? / LOOP?) beside the base branch's current conf. Read by hand; spawns nothing. |
| `./joharness.sh scout` + `scout :` line | No clock, no backlog trigger, no DRAINED gate. A pass runs on the reviewer's order (`/scout` typed by a human, or the orchestrator's `+human` extra session) or on a `scout` issue waiting on the scout, which the orchestrator reads on GitHub (`.claude/commands/orchestrate.md`): `joharness.sh` stays git-only: `scout` prints `off` (empty `JOHARNESS_SCOUT_REVIEWER`, or no `docs/product/SCOUT.md` brief on the base branch), `IN FLIGHT` or `none in flight`; dispatch adds `held` (stale view, a pending spawn, `JOHARNESS_MAX_MANAGERS=0`). The report prints every conf value a pass reads: brief, reviewer, research and budget. Every misread fails closed — never spawns a second scout. |
| `./joharness.sh conduct` + `conduct :` line | A sample of retired managers' own artifacts, read for how the item was worked, never the diff. Clock-driven (`JOHARNESS_CONDUCT_HOURS`), dated from the ledger `docs/conduct-log.md`; the command prints the sample and the ledger tally. NOT gated on DRAINED; suppressed while a curate or clerk spawns this pass or is in flight (one held for a slot does not hold it: the reviewer needs none). Every misread fails closed. |
| `.claude/commands/*.md` | The roles, as commands. |

## Roles

| Role | Tier | Runs as | Spawns | Owns | Ends when |
| --- | --- | --- | --- | --- | --- |
| orchestrator | low, mechanical on purpose | a session; the keeper starts one | manager sessions, and one orchestrator at hand-off (`create_session`) | the cap, the health pass, the kill handover | dispatch says DRAINED with nothing in flight, or at hand-off |
| keeper | sonnet | one session per repo, `keeper: <owner/repo>`, woken hourly by the heartbeat | one orchestrator a wake, when none is live (`create_session`) | nothing but that check | archived at the next REGISTER or replace |
| manager | the item's `agent:`; fable at xhigh for an unplanned requirement | a session with its own branch, claim and merge | worker subagents (`Agent`) | one item, until its file retires | its pull request merges, or it blocks on a human |
| worker | at or below the plan's tier, lower by default | a subagent in the manager's container | nothing | the files its sub-task names | it returns |
| curator | sonnet | a session, on `curate DUE` with proposals to make; prelude `./joharness.sh role curate` | nothing | decompose/order proposals for ONE pass, changing no plan | its pull request merges |
| surveyor | sonnet | a session, on the `OVERLAP-BOUND` verdict | nothing (declarations, not code) | the held plans' and holders' `scope:` lines for one holder key | its pull request merges, or `done` with nothing to change |
| clerk | sonnet, opus verifier | a session, on the `clerk DUE` tail line; prelude `./joharness.sh role clerk` | nothing | one plan-only pull request, no workstream file; never closes or opens an issue, never writes code, never a core-path-only plan, never plans a scout issue without the reviewer's `approved` comment newer than the scout's newest footed `scout:` comment | its pull request merges, no plan to write (pushes `clerk-noop-<UTC stamp>` at `origin/main`), or `TWIN: deferred` |
| scout | fable | a session, on the reviewer's order or a `scout` issue waiting on the scout, while `scout :` reads `none in flight`; prelude `./joharness.sh role scout` | nothing | proposal issues on this repository, typed Feature, labelled scout; a research request's answer | its claim retires: NOTHING TO PROPOSE, or the pass's issues filed and replies posted |
| conduct | sonnet | a session on `conduct DUE`, beyond the cap; prelude `./joharness.sh role conduct` | nothing | one pull request appending ledger rows to `docs/conduct-log.md`, no workstream file; never acts on a CONCERN | its pull request merges, or `TWIN: deferred` |

Managers and role sessions (curator, surveyor, clerk) count against
`JOHARNESS_MAX_MANAGERS` together. The scout and the conduct reviewer do
not: each runs as one session beyond the cap, at most one in flight, and
each run is the owner's money. A role command that says nothing to do
spawns nothing.

### The role prelude is a command

Counted 2026-10-14 at `6edf9b2` (`git grep -c <word> 6edf9b2 --
'.claude/commands/*.md'`): `authority` on 15 lines in 8 command files,
`fetch --prune` on 6 lines in 5; the twin check written out in 3 roles
(clerk, scout, conduct). Prelude prose is where that week's two harness defects sat (#459,
#460). So the clerk, scout, curator and conduct reviewer open with
`./joharness.sh role <name>`: authority, the pruned fetch, the role's own
report and its plain exits, the branch under the role's name, the claim
file where the role writes one; `--twin` and `--retire` after. It prints
`GO <branch>` or `STOP: <reason>` last; the command file keeps only the
judgement. Selftest: `.agents/harness/selftest/role.sh`.

### Scout, read on gx

Read 2026-10-13 on `chrsctl/gx` with `list_issues` (label `scout`, OPEN and
CLOSED) and `issue_read` `get_comments`; one pass, 2026-10-12, session
`session_01EP5uDwJBroSNv9Qwr77mHE`. gx main carries `docs/product/SCOUT.md`,
`JOHARNESS_SCOUT_REVIEWER=chrsctl`, `JOHARNESS_SCOUT_RESEARCH=on`.

- Issues opened: 1, [gx#645](https://github.com/chrsctl/gx/issues/645), open,
  labels `scout`, `approved`. Brief part: `## Competitors` (Attio), also
  `## Users`. Source kind: gap with a competitor as the reason to act now.
  Body has `## Brief`, `## Source`, `## Evidence`, `## Memory`.
- Cost, as the issue recorded it: `cost: 2.09 USD (get_session
  usage.cost_usd, 2026-10-12)`.
- Approved: #645, by the label; the reviewer left no reason in writing.
- Declined: none. Closed scout issues: 0.
- Back-and-forth: NOT held. #645 has two comments, both the scout's
  ([revising](https://github.com/chrsctl/gx/issues/645#issuecomment-6129890888),
  [revised](https://github.com/chrsctl/gx/issues/645#issuecomment-6129894544)):
  a self-revision after its verifier found four citation errors. No reviewer
  comment, question or answer.
- Not read: the `./joharness.sh scout` lines (`backlog`, `throughput`,
  `brief`) on gx; running gx's script from this session was refused.
- lead for the next plan: the requirement's "Evaluated on gx" clause wants a
  reviewer question answered by the scout and a recorded decline; neither
  happened. The human freed this plan anyway (2026-10-13), so the requirement
  was retired with those two parts open.

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
| clerk | `./joharness.sh clerk`, the open issues, the source each issue cites | the queue order, another branch, product code beyond what an issue cites, this doc (except the design doc where an issue cites it: only the cited section; and the files the plan names as anchors, which outrank the product-code limit) |
| scout | `./joharness.sh scout` and the evidence it lists — `upstream`, `feedback`, canonical issues, session cost, a dated release-note or Models API read; the brief `docs/product/SCOUT.md`; the open and closed `scout` issues; under `research  : on`, the web | a plan beyond its frontmatter and `## Goal`, the queue order, product code, another branch's code |
| conduct | `./joharness.sh conduct`; per sampled stem its workstream file before the retire commit, the branch's commit order (subjects, file names), the plan's `## Goal` and `## Acceptance` | any diff body, product code, the queue, this doc |
| worker | its sub-task prompt and the files it names | everything else |

Two spawn levels, never three. A worker that needs a branch of its own is a
plan, and enters the queue through the manager's pull request
(`.agents/docs/plans/README.md`, same-session plan handed off). Subagents
cannot claim, get no hook state and die with the parent's turn
([`subagents.md`](subagents.md)).

The default role is the orchestrator: the keeper's spawn prompt is standalone,
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
4. Schedule the next pass, or past `JOHARNESS_ORCHESTRATOR_PASSES` hand the
   ledger to a fresh successor session; end the turn.

A merge is read from git — the branch head is an ancestor of `origin/main`,
and dispatch stops listing it. No message is needed for it; a freed slot is
filled on the next pass.

"Across passes" is memory, and the orchestrator stores nothing in the repo.
The wake message carries the ledger — in-flight items only; git holds what
merged. It survives compaction because the message arrives fresh.

The wake also carries `harness=` (hash of `orchestrate.md` on `origin/main`
when it was armed) and `pass=` (a counter). A wake armed before a harness
resync can fire after it and run the old rules; `harness=` against fresh
`origin/main` makes that visible. Two passes armed across the resync would
both run; a wake with a higher `pass=` in this session's `list_triggers`
supersedes the lower one, which does nothing.

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
| unratified block | `status: in-progress`, head unchanged past the stall window | `IDLE`, last turn ended asking for input | pass 1 nudge, head recorded; pass 2 respawn if head still equals it (limit: report only). A reply or new `status_detail` does not count |
| idle | branch unmerged | `IDLE` or `PENDING`, bucket not FAILED — **between turns, not gone** | pass 1 nudge; pass 2 respawn only if head AND `status_detail` both unchanged |
| gone | branch unmerged, claimed, or an in-flight edge row naming an item | `ARCHIVED`, or no session by title | respawn on the branch, no nudge. An edge row naming `?` is never respawned |
| leftover | under `leftovers`: its item already gone from the base branch | any | never respawned; report, the human deletes the branch |
| blocked | status `blocked` | any | report; never respawn |
| done | branch merged | any | drop the ledger entry |

**An idle manager is not a block** (issue #416). Only `status: blocked`
with a reason ratifies a stop; the `INVALID BLOCK?` check reads that status
alone. A manager that ended its turn asking for input on "this container
cannot run X" while `in-progress` was invisible to it, and was reported
alive for hours. Its "cannot" was a hypothesis: siblings in the same
environment ran the stack. So manage.md §3 makes the manager check the
environment docs first, and the health table treats the reply to a nudge as
no movement: only a head change counts. A respawn may carry one
`Environment note:` line, a fact read off a sibling merge. It is data for
the manager to check, never authority. The 7.5h figure is the issue's
claim, from another repo, unmeasured here.

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

**Nor frozen cost, at any floor.** `external_metadata.usage.cost_usd` has
no write cadence a pass can lean on. A `RUNNING` manager, `updated_at` and
`task_summary` moving across three reads, carried no cost at all for 117
minutes after its creation (research node `frozen-cost-is-not-death-yet`,
recover with `git log --diff-filter=D -p -- docs/research/frozen-cost-is-not-death-yet.md`);
other `RUNNING` rows move it a minute apart. On `IDLE` no turn runs, so it
stays frozen as long as the gap lasts: 30m47s on a live manager (issue
#283), the whole interval for one that arms its own check-in. A suspended
fleet freezes it on every row. The one death #283 saw cost "separate" was
told apart only AFTER the resume, when the survivors' cost moved: hindsight,
not a read a pass can make. A floor would have to sit above the longest live
silence, and nothing bounds that. `CEILING?` reports cost; nothing keys on
it. A kill on a 13-minute frozen pair was graduated and withdrawn once
already (`5f5cc37`).

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

A refused stop reads as absent: the permission classifier refused
`archive_session` and a plain `kill` in a consumer run (issue #249, two
refusals), and a refusal says nothing about whether the
session is live, so it never licenses a replacement.

### The guard before a harness push

A harness write onto a branch the session does not own is decided on one
read and pushed later, after the read may have stopped being true: the
janitor re-created a branch deleted between its fetch and its push (#397).
`./joharness.sh guard janitor|kill|loop <branch> --expect <sha>` re-reads
origin right before the push — base branch by name, branch still on origin,
head still the decision's read (on a move it prints the claim's `session:`
and `status:` both sides), and for the janitor no `pr:` at live head — and
refuses on the first that fails. It writes nothing. Its callers: `janitor
--apply` before its leased push, and the orchestrator's KILL and LOOP
records, a relayed human answer and the respawn-limit hand-off
(`.claude/commands/orchestrate.md`, GUARD). `kill` and `loop` skip the `pr:`
check: a stalled manager with an open pull request stays killable, and its
record is a handover, not a release. Every caller then pushes with
`--force-with-lease` at the same sha, which covers the window after the
guard read: a plain push onto a branch deleted in that window re-creates
it. Guard makes "re-read before writing" a property of the write path
instead of a rule each author remembers.

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
  whole directory, declared exclusive. ONE surveyor (it takes a slot) per holder key per run
  (`manage.md`, R) marks registries `shared:` and narrows directory claims;
  genuine collisions settle in one pass.
- The curate cycle is the one spawn not driven by the queue's state: due on
  plan churn or the clock, under any verdict, one at a time, taking a slot, state in git so a
  re-seeded orchestrator does not re-spawn one already paid for. Repairs
  never need a session: `curate --apply`.

### A plan the queue cannot see

Queue items come from the base branch only. A plan filed on an unmerged
branch has no row: not free, not held, not in flight.

| Shape | Answer | Where |
|---|---|---|
| plan-only pull request | filer drives it to merged before exit | `manage.md`, Finish |
| plan riding a product pull request | row in dispatch's `plans on a branch` block — visible, counted nowhere | `joharness.sh:dispatch_branch_plans` |
| plan-only pull request whose plan was carried to the base by another branch, built and retired | the carrying session closes or comments on the source pull request at its own step 7 (its carry commit names the number); the reader prints the branch as a leftover (the human closes the pull request and deletes the branch); a carry that retired it with `status: done, pr: none` (ledger line, or a done workstream file on any other ref, merged or not) prints the row `DONE ON MAIN` — drop it, never spawn on it | `joharness.sh:dispatch_branch_plans` |
| author gone: doc-only branch (`docs/plans`, `docs/product`, `docs/research`, `docs/handover`), every plan live or DONE ON MAIN, no workstream file blocked, in review or naming a `pr:`, last push older than `HANDOVER_STALE_SECONDS`; or its only diff a `status: done, pr: none` workstream file naming a `plan:` (no wait; `free` retires that plan too) | dispatch prints `free <branch> ... FREEABLE` under spawn; the orchestrator proves the owner's session not RUNNING and spawns one sonnet manager; `free` merges the branch into the manager's claim, drops the owner's workstream files and retired stems, `curate --apply`, `ci`, commits; the manager's pull request closes the owner branch by merging it. A janitor-released (`status: abandoned`) branch is not offered: dispatch hides its plans | `joharness.sh:cmd_free`, `joharness.sh:dispatch_freeable`, `manage.md` §0 |

The row carries no instruction: the scheduler cannot see a pull request, and
a branch plan has not been reviewed into the queue, so spawning on it is the
human's call (`URGENT` leads the report) — to BUILD it. Bringing a
FREEABLE branch in whole (author-gone row) builds nothing: that spawn is
the orchestrator's. The reader drops the plan the
branch's own workstream file claims and every plan on an `abandoned` branch;
one row per stem.

**A spawn the human orders carries the plan, never takes the branch.** The
manager cuts its own branch from the base, copies the plan file across, and
pushes nothing to the owner's branch. Hazard: once the owner's branch merges,
the retired plan comes BACK (its side still adds it against a base that never
had it). The guard is the ledger, not the owner: the carry's retire appends
the stem to `docs/plans/RETIRED.md`, also when it finds the plan already done,
and `ci` refuses a diff adding a plan the base branch's ledger lists
(`joharness.sh:lint_plans_in_diff`). It fires on a `ci` run after the retire
lands: Loop step 7's 0-behind rule forces one for a session; a human merging
on an older green check is covered only when branch protection requires an
up-to-date branch. Removing the line, on the base first, is the human
override.
The owner was gone every time in consumer `chrsctl/gx`, where
`kanban-board-drag-move-persist` came back and held a slot.

**Why the first row can fail, and why the reader cannot tell.** The filer
cannot merge on red; when the base is red for a defect the plan itself fixes,
the plan reaches the base another way (a second branch carries it, builds it,
retires it). Read on consumer `chrsctl/gx` (taken there, not re-taken in canonical), `origin/main` at `38b2f015`,
2026-10-10: PR #469's plan-only branch stayed open two days after #477 fixed
the defect. `dispatch_branch_plans` drops a branch plan that neither its own workstream file claims nor an `abandoned` branch carries only when the plan path exists
on the base, so a carried-and-retired plan (absent) reads as never landed.
Only `git log --full-history -m --diff-filter=D -- <plan>` on the base sees
the retire (the merge commit is treesame for that path; plain `--diff-filter=D`
finds nothing). `dispatch_retired_edges` does not catch it either: it skips
a branch that deletes no plan or workstream file, and a branch that only adds
is not an edge. `dispatch_branch_plans` now tests this and prints a leftover row.
A carry that found the plan done deletes nothing on the base, so that test
misses it (3 of 9 held plans in `chrsctl/gx`, issue #423): the row also reads
the base's ledger (any line, as `ci` does) and every other ref's `status:
done` workstream files written after the plan's filing commit and still done,
or retired, at a tip; it carries `held Nd` from that commit.

## The numbers are the human's

| Knob | Default | Means | Basis |
| --- | --- | --- | --- |
| `JOHARNESS_MAX_MANAGERS` | 4 | managers in flight at once — money | p90 of branches active in one clock hour on `main` |
| `JOHARNESS_STALL_MINUTES` | 45 | no push this long = cross-check, nudge | p95 gap between commits on one branch (44m) |
| `JOHARNESS_HEALTH_MINUTES` | 10 | one orchestrator pass every this many | between median commit gap (4) and its p75 (12) |
| `JOHARNESS_ORCHESTRATOR_PASSES` | 6 | passes one orchestrator session carries before it hands the ledger to a fresh successor; 0 lifts it | written number: 304,615 tokens over 13 passes is about 23k a pass; six stay under 150k |
| `JOHARNESS_RESPAWN_LIMIT` | 2 | respawns per item per orchestrator run | written number |
| `JOHARNESS_MANAGER_HOURS` | 4 | claim older than this, no pull request = `CEILING?` report; 0 lifts it | one consumer run (issue #298) |
| `JOHARNESS_CHURN_THRESHOLD` | 5 | one file rewritten this often = warning | `ci`'s knob; honest branches peak at 4 |
| `JOHARNESS_CHURN_LIMIT` | 2x threshold | one file rewritten this often = `LOOP?` and `ci` red; 0 lifts it | `ci`'s ceiling |
| `JOHARNESS_CURATE_PLANS` | 10 | plan files added or changed since the last curate = due | plan production is bursty; written number |
| `JOHARNESS_CURATE_HOURS` | 168 | hours since the last curate (or merged `curate-noop-<stamp>` record) = due (anchors rot with no plan changing); 0 switches the cycle off | written number |
| `JOHARNESS_CURATE_REGISTRY` | 3 | plans declaring one path before `curate` calls it a registry | written number |
| `JOHARNESS_CURATE_SPLIT` | 8 | `## Scope` bullets before `curate` proposes a decompose | written number |
| `JOHARNESS_CLERK_HOURS` | 24 | hours between clerk passes over the open issues; 0 = off | written number |
| `JOHARNESS_CLERK_BATCH` | 3 | open issues one clerk pass takes at most | written number |
| `JOHARNESS_CLERK_STALE_HOURS` | 24 | an unmerged clerk branch older than this holds nothing; 0 = every one holds | written number |
| `JOHARNESS_SCOUT_READS` | 12 | outside reads one scout pass makes before it stops researching | counted by the scout in its claim's `## Decisions` |
| `JOHARNESS_SCOUT_REVIEWER` | empty | GitHub login whose approved comment gates a scout proposal issue; read from the base branch's conf; empty = nothing can be approved | a name the human gives |

| `JOHARNESS_SCOUT_RESEARCH` | off | exactly `on` lets a scout pass read outside the repository; read from the base branch's conf | a switch: money in one conf line |
| `JOHARNESS_CONDUCT_HOURS` | 168 | hours since the ledger last landed before a conduct reviewer is due; 0 = off. An unmerged branch named `conduct-<digit>...` (any prefix) unpushed for a seventh of it, at least 24h, is read as closed by a human | written number: weekly; issue #251 has no baseline, the tally builds one |
| `JOHARNESS_CONDUCT_SAMPLE` | 3 | retired branches one run samples, lowest `sha1(<stem>)` first; 0 = off | written number: few enough that one sonnet pass reads each whole |

`./joharness.sh conf` prints every knob the script reads with its live value
and source; the selftest `knobs-declared` keeps this table complete for the
`dispatch`-scoped ones and in step with `KNOBS` and `conf-keys.sh`.

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
  `scope:` is marked `CORE ONLY` and de-ranked: acceptance is all-or-nothing,
  so a partly-core plan cannot be finished either. `.agents/env/` is not
  core.
- **A `CORE ONLY` plan is a wait on a human, and the verdict must say so.**
  With slots free and nothing left but `CORE ONLY` plans, `dispatch` reads
  `DRAINED` — true of the fleet, false of the queue: the orchestrator opens
  no plan, pushes the human only on `status: blocked`, and exits; the
  heartbeat re-seeds and exits again. A requirement whose only plan is
  `CORE ONLY` counts as planned, so no planning manager is offered either.
  Measured 2026-10-14 with `DRAIN_FETCH=0 DISPATCH_FETCH=0 ./joharness.sh
  dispatch` on a scratch queue built as `selftest/dispatch.sh` builds its
  fixture (one requirement, one plan serving it, `scope:
  .github/workflows/ci.yml, platform/web/src, scripts`, nothing in flight):
  `slots : 4 of 4 free`, `nothing free`, the plan under `NOT YOURS — CORE
  ONLY`, no `Requirements without plans` block, verdict `DRAINED — nothing
  free, nothing in flight: exit, the heartbeat re-seeds`. In gx the human
  found that stall by asking; the plans had waited two to three days
  (research `partly-core-plans-strand-their-slots`, one session's reading
  of 2026-10-13; recover with `git log --diff-filter=D -p --
  docs/research/partly-core-plans-strand-their-slots.md`). Decided: the
  de-rank stays. A manager spawned on a partly-core plan spends a slot to
  end `core path:` blocked — the same human hand at the same place, paid
  for first — and a surveyor never splits a plan. What changes is the
  silence. `dispatch` prints the
  wait under its verdict (count, oldest age, stems) and the orchestrator
  pushes it to the human once per run, never spawning on it — a heartbeat
  run included, so hourly while the plan waits, as a block already is.
  The human's move
  is a split by hand: the core edit on their own commit, then the plan
  without it in BOTH `scope:` and `## Scope` — dropping the path from one
  is hiding (`.agents/docs/plans/README.md`, "A core path in `scope:`").
- **Merging uses the step 7 conditions unchanged.** The mode removes the
  human, never the gate.
- **No state store, no status field.** Every view derives from git and the
  control plane at read time; that is why a retirement is a deletion, not a
  flag.
- **Nothing is invented at the edge** (The one stop). Work enters only as an
  issue, a requirement or a plan through a pull request. A scout proposal
  enters as an issue and becomes a plan only through the clerk, after the
  reviewer's `approved` comment, newer than the scout's newest footed
  `scout:` comment; closing the issue declines it.
- **`human-review` label.** An agent applies it when it blocks on a human,
  and to the issue holding its plan's human remainder
  (`.agents/docs/plans/README.md`, "A human remainder"); a human applies it
  to hold an issue or pull request. It stops the clerk
  planning that issue and any session merging that pull request. Only a human
  removes it; no session does, ever.

### Bounds, orchestrator

It merges nothing, edits nothing but a killed manager's workstream file, picks
no tier, and takes no item itself. The
`janitor --apply` is the one writer to a branch it does not own: only where
the session is ARCHIVED or not found, never on push age, never a claim with
`pr:`, and it deletes nothing. The clerk turns EXISTING issues into plans and
nothing else. The scout proposes on issues and opens no pull request; the
reviewer's `approved` comment is the gate (`.claude/commands/clerk.md`), and
closing the issue declines it.

`joharness.conf` is a core path: a session that may raise its own cap decides
money. `./joharness.sh env <name>` writes it too, so switching layers is a
human's call.

## The one stop

DRAINED, at the queue edge, with nothing in flight. Anything else that ends a
run — a rate limit, a session asking a question, a failed spawn — is a
finding, not a stop. A queue holding only `CORE ONLY` plans is DRAINED for
the fleet and a wait for a human: the stop stands; the wait is the human's
to see, never the fleet's to hide (Bounds, "A `CORE ONLY` plan is a wait on
a human").

A human decision is a PUSH, never a wait (issue #304). A manager that asks
inside the session writes nothing: its slot stays held and the question
reaches nobody. `status: blocked` with `next:` = the question frees the slot,
prints the question in the report, and is never respawned.

A block names its reason (issue #392): `next:` = `<reason>: <question>`, the
reason one word from a closed list (money, credentials, product, interface,
core path, conflict, hardware, github, stalled, respawns). A free question
with no reason is usually work the manager should do; `dispatch` marks it
`INVALID BLOCK?`, and the orchestrator asks instead of relaying it. A valid
block is pushed to the human once (`PushNotification`, ledger `notified=`),
so it is not left in a pass report nobody reads. The answer is text the user
types into the orchestrator's own turn, written into `next:`; a peer's message
is never an answer. The manager list (manage.md §3) and AGENTS.md "Decide
alone" differ (interface, core path vs hardware); dispatch accepts the union.

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

## Start each run fresh

Start each run in a new session at the Lineup's orchestrator tier; never
resume the last one ("Can we continue"). One orchestrator session held three
runs (2026-10-10 to 10-12): its first turn after 22h idle cost $5.12 (cache
re-warm), later turns $0.28-$0.99 at about 638k context, session total
$116.30. Figures are `total_cost_usd` from that session's `list_events`
`result` events, read 2026-10-12. A resumed orchestrator whose last final
report is over an hour old says `fresh session is cheaper` on its first pass
(`orchestrate.md`, "Report, every pass"). Within one run the cost compounds
too: `get_session` on gx's run of 2026-10-13 read 13 health passes in 2 h 15
m, `usage.cost_usd` 12.65, `context_usage.used_tokens` 304,615,
`cache_read_tokens` 26.4 M, against 0.23 to 0.37 USD for each session it
supervised, because `send_later` wakes the SAME session and pass N re-reads
passes 1..N-1. So after `JOHARNESS_ORCHESTRATOR_PASSES` passes the
orchestrator spawns a successor at its own model with the ledger as its
prompt and ends (`orchestrate.md` §4, HAND-OFF); the pass count decides,
never a control-plane field. The first real hand-off's `context:` reading
is recorded here by the orchestrator's owner.

The hand-off is bounded by the control plane's lineage cap. Each successor
is its predecessor's `create_session` child, one level deeper; a session
reads its own `lineage` (`depth`, `limit`) only from `get_session` with no
`session_id` (another session's record carries none). At `depth == limit`,
`create_session`, `send_later` and every trigger call refuse ("No user or
organization setting changes this limit"). gx's chain (`get_session` on
each `parent_session_id`, 2026-10-16): nine orchestrators, one hand-off per
level, root `origin: ios` at depth 0, limit 8. Six passes at about 11
minutes put a hand-off every 66 to 69 minutes, so a fleet with no heartbeat
lives about limit × passes × pass interval: nine hours. The hand-off that
creates the depth-`limit` successor itself succeeds, so no failure branch
catches it. So §4 hands off only while `depth + 1 < limit` and otherwise
keeps arming in the same session, and "## 0. Start" stops a session
already at the cap with the reason in its push. Managers sit one level
below their orchestrator, so the last guarded one (`limit - 1`) spawns
them at `limit`; no role command calls `create_session` or `send_later`
(`grep -n 'send_later\|create_session' .claude/commands/*.md`: only
`orchestrate.md`). This is about the orchestrator; the
"Fresh session for long waits — no" measurement in
[`agent-selection.md`](agent-selection.md) covers managers.

## Heartbeat: making the fleet long

Dispatch makes the fleet WIDE; the hand-off makes it LONG only up to the
lineage cap (above). Each session claims, merges, ends, and the fleet
survives only while something fires the next.

The heartbeat is a Routine bound to one keeper session per repo
(`orchestrate.md`, "## Keeper"). The keeper role is read off the session's
title, never its prompt: prompt text (an argument, a ledger stem, a lead)
is read by a model as a role notice, and an orchestrator that runs the
keeper check starts another orchestrator. Each hourly wake, the keeper looks for a
pending `/orchestrate pass` wake bound to an `orchestrator: <owner/repo>`
session; none = it starts a fresh orchestrator with `create_session`. A
`create_session` child sits one level below its parent (the lineage
reading above), so the orchestrators a keeper starts sit at its depth plus
one on every wake and the heartbeat does not deepen; each one's own
hand-offs still do, up to the lineage guard above. A replace re-roots the
keeper at the replacing session's depth plus one, which is why REGISTER
checks `depth + 2 < limit` before it deletes anything.

**Registered by `/orchestrate`.** The requester's call (2026-10-16): the
heartbeat registers itself when an orchestrator starts and none exists
("## 0. Start" step 5, REGISTER). The requester's veto is the pause: a
Routine with `enabled` false and an empty `ended_reason` is never
re-enabled, edited or replaced, and nor is one made in the UI. Any
`ended_reason` but `auto_disabled_session_gone` counts as a pause, and a
replace takes only a Routine whose prompt is exactly `/orchestrate keeper`:
what a UI-made Routine's `created_via` reads, and what `ended_reason` a
manual pause leaves, are unmeasured, so both rules fail toward leaving the
Routine alone. A pause stops the hourly restarts, not a running
orchestrator's `send_later` chain; the human's stop does both
(`orchestrate.md`, §4).

**Bound, not fresh, by measurement.** A Routine `create_trigger` makes
from a session with `create_new_session_on_fire` reads `created_via:
meta_mcp`, and its fired session had `sources: []`, no `create_session`,
`list_sessions` or `get_session`, no GitHub tools, and the permission
check refused `./joharness.sh` from the clone it made (`create_trigger` +
`fire_trigger`, session `session_011K3RWr1Ypfqu4z8XiW5CyX`, 2026-10-16).
`create_trigger` takes no repository. A keeper made with `create_session`
and a `source_url` has the repository and the tools, so the Routine wakes
it instead. Rejected: session cron and a self-scheduling session (do not
outlive their creator), a scheduled GitHub Actions workflow (its pull
requests get no CI on `GITHUB_TOKEN`, so step 7 never goes green).

**Keeper liveness reads wakes, not sessions.** `list_sessions` answered
77,897 characters at `limit` 30 (2026-10-16), read hourly into one
persistent context; a pending wake costs one `list_triggers` and a
`get_session` per candidate. `list_triggers` is account-wide: from a
session that is not the orchestrator it listed the gx orchestrator's
pending `/orchestrate pass` wake with its `persistent_session_id` and
`derived_state.prompt` (2026-10-16). An orchestrator mid-pass has no
pending wake: the keeper starts a second one, and "## 0. Start" step 3
lets the older `RUNNING` one proceed and the newer exit. A DRAINED fleet
costs one short orchestrator session an hour.

The spec every orchestrator checks at start (`orchestrate.md`, "## 0.
Start" step 5; a session-made stale one is replaced, any other `heartbeat
stale` or `heartbeat duplicated` line pushes):

- **Name**: exactly `heartbeat: <owner/repo>` — how the check tells it from
  another repo's heartbeat or a nightly `/curate`.
- **Binding**: `persistent_session_id` = a session titled `keeper:
  <owner/repo>`, not `ARCHIVED`. An archived keeper disables the Routine
  (`auto_disabled_session_gone`); the next `/orchestrate` replaces both.
- **Cadence**: hourly floor (`*/5 * * * *` is refused). The Routine backs
  the `send_later` chain; it does not replace it.
- **Prompt**: exactly `/orchestrate keeper`. It invokes the command; the
  keeper's title, not this argument, routes it to its one section.
- **Stop**: `update_trigger` `enabled: false` pauses (the veto),
  `delete_trigger` removes and lets the next `/orchestrate` register a new
  one. A Routine not named exactly `heartbeat: <owner/repo>` never counts
  and is never touched: an older one under another name stays wherever a
  human left it. Read `last_run`, never `next_run_at` (a paused Routine keeps a
  stale one). A human who cannot halt the fleet has no veto.
- **The chain can end silently.** A `send_later` link can be delivered and
  never run (`SUCCEEDED`, identical to a healthy link — issue 285, 18 days
  idle), or fail with `auto_disabled_session_gone`. `last_run` reports
  delivery, not execution — which is why the Routine exists.
- **A frozen orchestrator still reading `RUNNING`** makes every started
  orchestrator exit at step 0's one-orchestrator check. Unresolved.
- **Firing over a live fleet**: nothing special — claimed plans are not free.
  An unpushed claim is invisible, so push the workstream file as soon as work
  has a name.

### Periodic roles ride the heartbeat

The conduct reviewer adds no scheduler and no Routine. #249's question —
must the scheduler be a session that can freeze with the fleet — has a
partial answer: the keeper is a session, but it holds no fleet state and
does one check a wake; an archived keeper disables its Routine, and the next
`/orchestrate` replaces both. The orchestrator a keeper starts reads
`dispatch`, and `conduct DUE` rides it.

## Not constrained, by decision

No cap on work per run, no halt on red `main`, no ban on sessions spawning
sessions — the requester declined all three on 2026-08-24. A session
proposes them with evidence; it never adds one on its own judgment (money,
`.agents/harness/AGENTS.md`, Decide alone). The lever is the Routine pause.
