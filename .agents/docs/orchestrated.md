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

| Where | What it does |
| --- | --- |
| `joharness.sh:unattended` | The ONE predicate the boundary, the marking and `authority` read. |
| `session-start` banner | Routes by role: prompt names `/manage <item>` = manager; nothing named = orchestrator, run `/orchestrate`. Prints the core-path boundary. |
| Queue hook | Marks a plan with ANY core path (`./joharness.sh protocol-paths`) in `scope:` `CORE ONLY` and ranks it after every other free plan. Prints `in flight: <free> overlaps <claimed> on <path>` per collision with a held plan. |
| `./joharness.sh dispatch` | The orchestrator's one read: the human's numbers, managers in flight with push age and marks (`STALL?`, `LOOP?`, `CEILING?`), slots under the cap, the spawn order with waves and `HOLD`s, the `deferred  :` lines for held requirements, the cycle lines, one verdict. Reports only. |
| `dispatch` wait line | Under any verdict, when claims are parked `core path: waiting on #<N>` and the base carries no merge of #<N>: `<n> pull request(s) wait on a human merge: #<N> (<stem>), …`. Read from git, so a closed pull request stays listed until the human answers the block. The verdict word is unchanged; the orchestrator reports the line and pushes each pull request to the human once per run. |
| `dispatch` verdict `OVERLAP-BOUND` | Slots free but every free plan HELD behind work in flight. A `rescope :` block names the holder key and the held paths; the verdict spawns ONE surveyor to correct the `scope:` declarations. |
| `./joharness.sh release` (no argument) + `release   :` lines | The report of claims to release, in the dispatch read too. `stale, session gone?` (stale claim, in-progress/review/no status, no `pr:`; the caller proves the session ARCHIVED or not found first), `done, no pull request` (`status: done, pr: none`, a `plan:` named, whole branch diff workstream files, stale), `queue holds it by needs: <stem>` (no session check). Report-only `no claim: plans not landed: <stems>`: a doc-only branch that never claimed; nothing is written, a human re-files the plans. A stale claim that does not qualify is listed indented with why. Writes nothing. |
| `./joharness.sh release <branch>...` | The write: releases each listed branch through the guard and the lease (`status: abandoned`), refuses any other with the reason. Subjects `release: session gone (<date>)`, `release: done, no pull request (<date>)`, `release: the queue holds <plan> by a needs: edge (<date>)`. Deletes nothing; git only, never the GitHub API. Output per file: `release   : <branch>  <path>  <reason>` or `... plan <p>  held by needs: <s>`, then `pushed    : <branch> <sha>`. |
| `./joharness.sh release --human <branch>...` (alias `halt`) | A human's order, never a session's judgement: any age, any status, `pr:` allowed; on an edge branch it restores the branch's own retired record, released. Subject `release: a human released the claim (<date>)`. The item returns to the queue; the session and any pull request stay the control plane's and the human's. |
| `RELEASE:` row flag + `release DUE` | A block the queue has since absorbed (#626). Dispatch prints a parked claim `RELEASE: the queue holds it by needs: <stem> since <date>, holds no slot` when its `next:` opens with a reason word the queue can answer (a manage.md §3 reason, not `money:`, `credentials:`, `hardware:`, `core path:`, `github:`, `respawns:`, `defect:`), names `<stem>` as a token, and carries no `pr:`, and its plan on the base is `blocked by:` that `needs: <stem>` edge, added after the park. The tail line `release DUE: <branches>` names every stale, done and needs: branch (a needs: one at once; a stale or done one only once its session reads ARCHIVED or not found); the orchestrator runs `release <branch>...` on it. The session stays alive and may set the word back. Every other block stays the human's. |
| `./joharness.sh clerk` + `clerk :` line | Open issues become plans only through the clerk (`dispatch` reads `docs/plans/` only). Clock-driven, dated from git, a new open issue (`JOHARNESS_ISSUE_CLERK_HOURS`, dispatch's `clerk issue read:` line, read by the orchestrator) also calls it early, at most one in flight (`joharness.sh:cmd_clerk`, `.claude/commands/clerk.md`). Orthogonal to the verdict. |
| `./joharness.sh analysis` | One unmerged branch's condition (BLOCKED / STALL? / LOOP?) beside the base branch's current conf. Read by hand; spawns nothing. |
| `./joharness.sh scout` + `scout :` line | No clock, no backlog trigger, no DRAINED gate: a pass runs on the reviewer's order or on a `scout` issue waiting on the scout (`orchestrate-reference.md`, "A scout issue needs the scout"). Every misread fails closed — never a second scout (`joharness.sh:cmd_scout`, `.claude/commands/scout.md`). |
| `./joharness.sh retro --audit` + `retro : audit` line | A sample of retired managers' own artifacts, read for how the item was worked, never the diff. Clock-driven, dated from `docs/conduct-log.md`, due early past `JOHARNESS_RETRO_FLOOR_HOURS` on a full sample; every misread fails closed (`.claude/commands/retro-audit.md`). |
| `./joharness.sh retro` + `retro : trace` line | Sessions that did not come back clean (blocked, abandoned, killed), plus the oldest untraced audit CONCERN, read from their transcripts for the check that should have caught each failure. Clock-driven, dated from `docs/retro-log.md`, due early on a claim the queue can hold (no floor) and, past `JOHARNESS_RETRO_FLOOR_HOURS`, on a claim parked `stalled:` or `respawns:`, an untraced audit CONCERN, or a full sample; every misread fails closed (`joharness.sh:cmd_retro`, `.claude/commands/retro.md`). |
| `.claude/commands/*.md` | The roles, as commands. |

## Roles

| Role | Tier | Runs as | Spawns | Owns | Ends when |
| --- | --- | --- | --- | --- | --- |
| orchestrator | low, mechanical on purpose | a session; the keeper starts one | manager sessions; never an orchestrator | the cap, the health pass, the kill handover | dispatch says DRAINED with nothing in flight, or the keeper retires it |
| keeper | haiku | one session per repo, `🔑 keeper: <owner/repo>`, woken hourly by the heartbeat | the only spawner of orchestrators: one a wake when none is live, or a successor when the live one's wake asks to retire (`create_session`) | nothing but that check | archived at the next REGISTER or replace |
| manager | the item's `agent:`; fable at xhigh for an unplanned requirement | a session with its own branch, claim and merge | worker subagents (`Agent`) | one item, until its file retires | its pull request merges, or it blocks on a human |
| worker | at or below the plan's tier, lower by default | a subagent in the manager's container | nothing | the files its sub-task names | it returns |
| surveyor | sonnet | a session, on the `OVERLAP-BOUND` verdict | nothing (declarations, not code) | the held plans' and holders' `scope:` lines for one holder key | its pull request merges, or `done` with nothing to change |
| clerk | sonnet, opus verifier | a session, on the `clerk DUE` tail line, or on the human's order (`--ordered`); prelude `./joharness.sh role clerk` | nothing | one plan-only pull request, no workstream file; closes an issue only on DOES NOT HOLD, DUPLICATE or UPSTREAM, opens none but UPSTREAM's on canonical, never writes code, never a core-path-only plan, never plans a scout issue without the reviewer's `approved` comment newer than the scout's newest footed `scout:` comment | its pull request merges, no plan to write (pushes `clerk-noop-<UTC stamp>` at `origin/main`), or `TWIN: deferred` |
| scout | fable | a session, on the reviewer's order or a `scout` issue waiting on the scout, while `scout :` reads `none in flight`; prelude `./joharness.sh role scout` | nothing | proposal issues on this repository, typed Feature, labelled scout; a research request's answer | its claim retires: NOTHING TO PROPOSE, or the pass's issues filed and replies posted |
| retro (audit) | sonnet | a session on `retro audit DUE`, or on the human's order (`--ordered`), beyond the cap; prelude `./joharness.sh role retro --audit` | nothing | one pull request appending ledger rows to `docs/conduct-log.md`, no workstream file; never acts on a CONCERN | its pull request merges, or `TWIN: deferred` |
| retro (trace) | sonnet | a session on `retro DUE`, or on the human's order (`--ordered`), beyond the cap; prelude `./joharness.sh role retro` | nothing (it files plans, fixes nothing) | one pull request: ledger rows in `docs/retro-log.md` and new plans for mechanisms, no workstream file; never a rule-only fix | its pull request merges, or `TWIN: deferred` |

`JOHARNESS_MAX_MANAGERS` caps managers only; every role session runs beyond
the cap, one of each in flight, a blocked one included (`orchestrate.md` §3).

### The role prelude is a command

The clerk, scout and retro reviewer open with `./joharness.sh role
<name>` (authority, fetch, the role's report and exits, branch, claim file;
`--twin` and `--retire` after), which prints `GO <branch>` or `STOP: <reason>`
last; the command file keeps only the judgement (selftest `role.sh`).
`--ordered` (clerk and retro, either mode; scout has no clock and refuses
it) is an ordered pass. Clerk: a no-op, its clock was never an exit.
Retro: the clock alone is no exit. In flight, unreadable, off and nothing
to review still are. So are the human's pause (`JOHARNESS_MAX_MANAGERS=0`)
and dispatch's `suppressed` (a clerk in flight holds audit; a clerk or an
audit holds trace), for a bare pass too. Its `--twin` defers once the ledger
changes on the base branch. Its merged ledger dates the clock as a due pass's does.

### What each role reads

Session start prints the banner, the environment pointer and THIS branch's
workstream files (`HANDOVER_SCOPE=branch`) — no queue. Every line injected is
paid by every session. A role whose command states its reads is listed by
its limits only.

| Role | Reads | Never opens |
| --- | --- | --- |
| orchestrator | `orchestrate.md` | a plan, a requirement, a research file, another branch's workstream file, this doc |
| keeper | `keeper.md`, its trigger list and the sessions it names, the Lineup table | dispatch, the queue, a plan, any workstream file, this doc |
| manager | `manage.md` | the queue, other plans, other branches, this doc |
| surveyor | the `rescope :` block in its prompt, and the `## Scope` of each plan it renames | the queue, product code, this doc |
| clerk | `clerk.md` | the queue order, another branch, product code beyond what an issue cites, this doc (except the design doc where an issue cites it: only the cited section; and the files the plan names as anchors, which outrank the product-code limit) |
| scout | `scout.md` | a plan beyond its frontmatter and `## Goal`, the queue order, product code, another branch's code |
| retro (audit) | `retro-audit.md` | any diff body, product code, the queue, this doc |
| retro (trace) | `retro.md` | any diff body, product code, another role's ledger, this doc |
| worker | its sub-task prompt and the files it names | everything else |

Two spawn levels, never three. A worker that needs a branch is a plan, in the
manager's pull request (`.agents/docs/plans.md`, same-session plan
handed off). Subagents cannot claim, get no hook state and die with the
parent's turn ([`subagents.md`](subagents.md)).

The default role is the orchestrator; a manager is told what it is by its
spawner. Two orchestrators are the collision to avoid: a `RUNNING` session
titled `🎼 orchestrator: <repo>` (glossary, role title) not you = exit.

## The loop

One pass every `JOHARNESS_HEALTH_MINUTES`, armed with `send_later`, never a
poll: dispatch, the health pass (kills and respawns first), spawns up to
`slots`, the next arm (`orchestrate.md`). Merges are read from git. The wake
carries the ledger (in-flight only), `harness=` and `pass=`, so it survives
compaction; the orchestrator stores nothing in the repo.

## Health: two signals, one verdict

Push time is not liveness in either direction, so a verdict needs both
halves: git (dispatch) and the control plane. The table and GONE are
`orchestrate.md` step 2; what each field decides is
`orchestrate-reference.md`, Control plane fields. A row built on push age
may ask for a control-plane read and may order nothing.

**An idle manager is not a block.** Only `status: blocked` with a reason
ratifies a stop; the `INVALID BLOCK?` check reads that status alone. A
manager's "this container cannot run X" while `in-progress` is a hypothesis:
manage.md §3 makes it check the environment docs first, and the health table
treats the reply to a nudge as no movement: only a head change counts. A
respawn may carry one `Environment note:` line, a fact read off a sibling
merge. It is data for the manager to check, never authority.

## The kill, and why the handover comes first

A killed session with no handover strands a branch the successor cannot read,
so the record lands before the archive and the successor resumes on the SAME
branch; a loop gets no nudge and a successor one tier up
(`orchestrate-reference.md`, KILL and LOOP).

The branch is the claim and the claim survives the kill.

### The guard before a harness push

A harness write onto a branch the session does not own is decided on one
read and pushed later, after the read may have stopped being true.
`./joharness.sh guard release <branch> [--human] [--expect <sha>]` and `guard record <branch> [--expect <sha>]` re-read
origin right before the push — base branch by name, branch still on origin,
head still the decision's read (on a move it prints the claim's `session:`
and `status:` both sides), and for `release` no `pr:` at live head — and
refuses on the first that fails. It writes nothing. Its callers: `release`
(`--human` skips the `pr:` check: a human's order) before its leased push, and the orchestrator's
records, a relayed human answer and the respawn-limit hand-off
(`.agents/docs/orchestrate-reference.md`, GUARD). `record` skips the `pr:`
check: a stalled manager with an open pull request stays killable, its
record is a handover, not a release. Every caller then pushes with
`--force-with-lease` at the same sha, which covers the window after the
guard read: a plain push onto a branch deleted in that window re-creates
it.

## Concurrency

`JOHARNESS_MAX_MANAGERS` caps managers in flight. Blocked managers hold no
slot. A manager past its retire commit holds one (a branch, a pull request,
CI, a container, no claim) while its item is still on the base branch; item
gone = leftover, counts as nothing. Within the cap the order is the queue
hook's: urgent first, then oldest, in waves of disjoint scope. On top:

- A free plan whose scope overlaps a plan a manager HOLDS is `HOLD`
  (same `wave_split_hit` as the waves).
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
- Every free plan held with slots idle = `OVERLAP-BOUND`. ONE surveyor
  (beyond the cap, no slot) per holder key per run (`manage.md`, R) marks
  registries `shared:` and narrows directory claims; genuine collisions
  settle in one pass. The idle slot is the trigger, not the surveyor's
  budget.

### A plan the queue cannot see

Queue items come from the base branch only. A plan filed on an unmerged
branch has no row: not free, not held, not in flight.

| Shape | Answer | Where |
|---|---|---|
| plan-only pull request | filer drives it to merged before exit | `manage.md`, Finish |
| plan riding a product pull request | row in dispatch's `plans on a branch` block — visible, counted nowhere | `joharness.sh:dispatch_branch_plans` |
| plan-only pull request whose plan was carried to the base by another branch, built and retired | the carrying session closes or comments on the source pull request at its own step 7 (its carry commit names the number); the reader prints the branch as a leftover (the human closes the pull request and deletes the branch); a carry that retired it with `status: done, pr: none` (ledger line, or a done workstream file on any other ref, merged or not) prints the row `DONE ON MAIN` — drop it, never spawn on it | `joharness.sh:dispatch_branch_plans` |

The row carries no instruction: the scheduler cannot see a pull request, and a
branch plan has not been reviewed into the queue, so spawning on it is the
human's call (`URGENT` leads the report) — to BUILD it. The reader drops the plan the branch's own workstream file
claims and every plan on an `abandoned` branch; one row per stem.

**A spawn the human orders carries the plan, never takes the branch.** The
manager cuts its own branch from the base, copies the plan file across, and
pushes nothing to the owner's branch. The carry's retire appends the stem to
`docs/plans/RETIRED.md`, also when it finds the plan already done, and `ci`
refuses a diff adding a plan the base branch's ledger lists
(`joharness.sh:lint_plans_in_diff`), so the owner branch's merge cannot bring
the plan back. It fires on a `ci` run after the retire lands: Loop step 7's
0-behind rule forces one for a session; a human merging on an older green
check is covered only when branch protection requires an up-to-date branch.
Removing the line, on the base first, is the human override.

## The numbers are the human's

| Knob | Default | Means | Basis |
| --- | --- | --- | --- |
| `JOHARNESS_MAX_MANAGERS` | 4 | managers in flight at once — money | p90 of branches active in one clock hour on `main` |
| `JOHARNESS_STALL_MINUTES` | 45 | no push this long = cross-check, nudge | p95 gap between commits on one branch (44m) |
| `JOHARNESS_HEALTH_MINUTES` | 10 | one orchestrator pass every this many | between median commit gap (4) and its p75 (12) |
| `JOHARNESS_ORCHESTRATOR_PASSES` | 6 | passes one orchestrator session carries before its wake asks the keeper to swap in a successor; 0 lifts it | written number: 304,615 tokens over 13 passes is about 23k a pass; six stay under 150k |
| `JOHARNESS_RESPAWN_LIMIT` | 2 | respawns per item per orchestrator run | written number |
| `JOHARNESS_MANAGER_HOURS` | 4 | claim older than this, no pull request = `CEILING?` report; 0 lifts it | one consumer run |
| `JOHARNESS_CHURN_THRESHOLD` | 5 | one file rewritten this often = warning | `ci`'s knob; honest branches peak at 4 |
| `JOHARNESS_CHURN_LIMIT` | 2x threshold | one file rewritten this often = `LOOP?` and `ci` red; 0 lifts it | `ci`'s ceiling |
| `JOHARNESS_CURATE_REGISTRY` | 3 | plans declaring one path before `curate` calls it a registry | written number |
| `JOHARNESS_CURATE_SPLIT` | 8 | `## Scope` bullets before `curate` proposes a decompose | written number |
| `JOHARNESS_CURATE_LAYERS` | 3 | distinct top-level directories in a plan's `scope:` before `curate` proposes a decompose; 0 = off | written number |
| `JOHARNESS_CLERK_HOURS` | 24 | hours between clerk passes over the open issues, for unordered passes only (`--ordered` runs any time); 0 = off | written number |
| `JOHARNESS_CLERK_BATCH` | 3 | open issues one clerk pass takes at most | written number |
| `JOHARNESS_CLERK_STALE_HOURS` | 24 | an unmerged clerk branch older than this holds nothing; 0 = every one holds | written number |
| `JOHARNESS_SCOUT_READS` | 12 | outside reads one scout pass makes before it stops researching | counted by the scout in its claim's `## Decisions` |
| `JOHARNESS_SCOUT_REVIEWER` | empty | GitHub login whose approved comment gates a scout proposal issue; read from the base branch's conf; empty = nothing can be approved | a name the human gives |
| `JOHARNESS_SCOUT_RESEARCH` | off | exactly `on` lets a scout pass read outside the repository; read from the base branch's conf | a switch: money in one conf line |
| `JOHARNESS_CONDUCT_HOURS` | 168 | hours since the ledger last landed before an audit is due, the ceiling: a full sample makes it due sooner, past `JOHARNESS_RETRO_FLOOR_HOURS`; for unordered passes only (`role retro --audit --ordered` skips this clock, never in flight, off, the pause or an empty sample); with no ledger yet, also how far back the sample reaches; 0 = off. An unmerged `retro-audit-<digit>...` or `conduct-<digit>...` branch (any prefix) unpushed for a seventh of it, at least 24h, is read as closed by a human | written number: weekly; no baseline, the tally builds one |
| `JOHARNESS_RETRO_HOURS` | 168 | hours since `docs/retro-log.md` last landed before a trace is due, the ceiling: evidence makes it due sooner, past `JOHARNESS_RETRO_FLOOR_HOURS`; for unordered passes only (`role retro --ordered` skips this clock, never in flight, off, the pause or nothing to trace); 0 = off. An unmerged `retro-<digit>...` branch is in flight, dropped as audit's | written number: weekly, as audit |
| `JOHARNESS_RETRO_SAMPLE` | 3 | sessions that did not come back clean one trace run samples; 0 = off | written number: as audit |
| `JOHARNESS_RETRO_EVENTS` | 200 | transcript events a trace run reads per sampled session, counted before the kinds filter | written number: a session's end; earlier failures read secondhand |
| `JOHARNESS_RETRO_FLOOR_HOURS` | 24 | hours since a mode's ledger last landed before its evidence makes it due ahead of its clock: trace on a claim parked `stalled:` or `respawns:`, an untraced audit CONCERN, or a full sample; audit on a full sample. The queue-block path keeps no floor; 0 = clock only | written number: a day, as the clerk |
| `JOHARNESS_DEFECT_PLAN_HOURS` | 48 | hours after the first `defect:` park on an issue with no plan naming it = `PARKED #<n> UNPLANNED`, notified once; 0 lifts it | written number: two clerk cycles |
| `JOHARNESS_DEFECT_CLERK_HOURS` | 1 | hours after the first `defect:` park on an issue no plan names (base or any unmerged branch), no clerk having read the issues since (a landed one: its first commit less this knob; a no-op: its stamp less this knob), before the clerk is due ahead of `JOHARNESS_CLERK_HOURS`; holds as a cadence due does; 0 lifts it | written number: a parked manager waits on the clerk alone |
| `JOHARNESS_ISSUE_CLERK_HOURS` | 1 | hours an open issue no clerk has read (created after `./joharness.sh clerk`'s `last read`), not planned or claimed, waits before the orchestrator spawns the clerk ahead of `JOHARNESS_CLERK_HOURS` (dispatch's `clerk issue read:` line); never below `JOHARNESS_DEFECT_CLERK_HOURS`; holds as a cadence due does; 0 = off | written number: a new issue waits on the clerk's cadence |
| `JOHARNESS_DEFECT_FIX_HOURS` | 72 | hours after the first `defect:` park on an issue with no RESUME = `PARKED #<n> STUCK`, notified once; 0 lifts it | written number: a plan cycle plus a day |
| `JOHARNESS_DEFECT_RECHECK_HOURS` | 2 | hours after a `defect:` block, no plan naming its issue and the base moved since, before `PARKED #<n> RECHECK`; 0 lifts it | written number: a few merges on an active base |
| `JOHARNESS_CONDUCT_SAMPLE` | 3 | branches one run samples, from those retired since the last reviewer drew its sample — the commit its ledger branch was cut from (no ledger: the last `JOHARNESS_CONDUCT_HOURS`), riskiest first: plan `agent:` haiku or sonnet, then opus or fable, then no plan; then harness code touched; then lowest `sha1(<stem>)`. The rest are never offered again once the next ledger lands: a sample of recent work, not a backlog; 0 = off | written number: few enough that one sonnet pass reads each whole |

`./joharness.sh conf` prints every knob the script reads with its live value
and source; the selftest `knobs-declared` keeps this table complete for the
`dispatch`-scoped ones and in step with `KNOBS` and `conf-keys.sh`.

Read by `dispatch` (and the churn pair by `ci`) from the environment for one
command, `joharness.conf` for the repo, else the default; digits only. A
consumer gets the numbers as prose only — they are not in
`.agents/scripts/conf-keys.sh`. A session proposes a change with a run's
evidence; it never sets one (`.agents/harness/AGENTS.md`, Decide alone).

**Why the knobs stay knobs** (settled by a sweep of all 49 `KNOBS` rows).
None can be made a constant on evidence in this repository. 45 of 49 are
assigned by a selftest to reach a branch, and constanting one means first
showing the test reaches it another way; 6 are set by this repo's conf and
11 are seeded into every consumer's conf (`conf-keys.sh`). The two nothing
here sets, `JOHARNESS_RESPAWN_LIMIT` and `JOHARNESS_RETRO_EVENTS`, are read
through `num_knob`, so a consumer conf can set them. The one known consumer,
`chrsctl/gx`, was not readable in the sweep, so they stay UNKNOWN, never
CONSTANT. A plan cutting them waits on a session granted `gx` that reads its
`joharness.conf`. A doc table row, or no doc at all, is not evidence of no
setter.

## Bounds

The rules that bind every session.

- **The core paths are off limits to a session running**: `joharness.conf`
  (cap — money), `.claude/settings.json` (hooks, permissions) and `.github`
  (the merge gate's checks, and CODEOWNERS). Protocol text is NOT: a session
  edits and self-merges `joharness.sh`, `.agents/harness/` and `.claude/`
  under the step 7 gate. `joharness.sh:protocol_paths` is the list, read by
  the banner, the Stop guard and the queue hook — the early warning;
  `.github/CODEOWNERS` plus a branch-protection rule requiring code-owner
  review (the human's setting) is the guarantee. A plan with ANY core path in
  `scope:` is `CORE ONLY` and ranked after every other free plan.
  `.agents/env/` is not core. One exception, merged by a human: a manager's
  `human/<stem>` pull request labelled `human-review`, carrying only the
  core-path edit, from a separate worktree (`.claude/commands/manage.md` §2). A hook `.claude/settings.json` registers
  runs from the working tree: it is built unregistered, tested through
  fixtures, and registered in that pull request, never edited in place.
- **A `CORE ONLY` plan: the agent builds it, a human merges it.** A human
  waits on a pull request, never on an implementation. dispatch spawns a
  manager on it after every other free item, so it never takes a slot ahead
  of work that needs no human. The manager builds the core edit in a
  `human/<stem>` pull request (`.agents/docs/manage-reference.md` § Human
  remainder) and, when its Acceptance needs that merged, parks `core path:
  waiting on #<N>` — no slot held, RESUMEd once #<N> merges. Nothing left but
  such parked claims reads `DRAINED`; the orchestrator pushes `dispatch`'s
  wait line to the human once per run, so the human's one move is the merge.
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
- **`human-review` label.** An agent applies it when it blocks on a human (never a `defect:` block),
  after a clerk HUMAN verdict or a clerk NARROWER verdict with a human
  remainder, to a `defect:` issue a manager files whose fix needs a human's
  call (`.agents/docs/manage-reference.md` § Defect step 3), and to the `human/<stem>` pull request holding its plan's human remainder
  (`.agents/docs/plans.md`, "A human remainder"); a human applies it
  to hold an issue or pull request. It stops the clerk
  planning that issue and any session merging that pull request. Only a human
  removes it; no session does, ever.

### Bounds, orchestrator

`release <branch>...` and, on a
human's order, `release --human` (How the harness runs) are its writers to a branch it does not own. `./joharness.sh env <name>` writes `joharness.conf` (core path), so switching
layers is a human's call.

## The one stop

DRAINED, at the queue edge, with nothing in flight. Anything else that ends a
run — a rate limit, a session asking a question, a failed spawn — is a
finding, not a stop. Claims parked on a human merge hold no slot: with
nothing else left the queue is DRAINED and a wait for a human (Bounds).

A human decision is a PUSH, never a wait. A manager that asks inside the
session writes nothing: its slot stays held and the question reaches nobody.
`status: blocked` with `next:` = the question frees the slot, prints the
question in the report, and is never respawned.

One block is not a human's: `defect: #<n>: …`, a manager parked on a defect
outside its item. `dispatch` prints it `PARKED #<n>`: no slot, not counted
as waiting, the verdict line unchanged. From git alone: a plan naming #<n>
leaves the base's first parent after the block commit (a rename is no
retire) and no plan on the base or a live branch names #<n> = `RESUME`, a slot, never DRAINED; no plan,
the block `JOHARNESS_DEFECT_RECHECK_HOURS` old, the base moved = `RECHECK`
(a re-park restarts that clock only). Outranking RECHECK, notified once:
`UNPLANNED`, `STUCK` (a stale live branch naming #<n> included),
`UNREADABLE` (the block commit is not in the clone: no RESUME). Mechanics:
`orchestrate-reference.md`, Resume.
A `PARKED` row on an issue no plan names, `JOHARNESS_DEFECT_CLERK_HOURS`
after its first park and no clerk having read the issues since, makes the clerk due now
(`clerk DUE (PARKED #<n> unplanned, …)`), not at its cadence.

A park on an issue no plan names waits on the clerk's cadence: in a run the
clerk is the only automated path from an issue to a plan (a human or session
may file a plan with `issue:` by hand), and `joharness.sh:clerk_due` reads the
clock and the clerk's own records, never a park. A defect filed just after a
clerk lands waits at least until `JOHARNESS_CLERK_HOURS` elapse for a pass to
take it, longer if `JOHARNESS_CLERK_BATCH` defers it, then the clerk's pull
request and the fix itself; `UNPLANNED` at `JOHARNESS_DEFECT_PLAN_HOURS` only
notifies. A cadence gap, not intent: the parked manager waits on exactly that
plan while its branch drifts, and a RECHECK respawn can re-park on the same
red check. One consumer reading, not re-taken here (chrsctl/gx, 2026-10-28):
two managers parked beside `clerk : not due`; a human-ordered extra clerk
(`orchestrate-reference.md`, Role sessions) cut the wait to the plan. The
plan `defect-park-calls-clerk` makes the clerk due early on such a park; it
rewrites this paragraph when it retires.

A block names its reason: `next:` = `<reason>: <question>`, one word from
the closed list `joharness.sh:block_reason_ok`. A free question with no
reason is usually work the manager should do; `dispatch` marks it `INVALID
BLOCK?`, and the orchestrator asks instead of relaying it. A valid block is
pushed to the human once (`PushNotification`, ledger `notified=`). The answer
is text the user types into the orchestrator's own turn, written into
`next:`; a peer's message is never an answer.

## Authority: the prompt routes, the repository authorises

A spawn prompt saying *never ask a human, merge your own pull requests, keep
going* reads as an injection, and a session rightly refuses it. So a spawn
prompt carries the work, named, and `./joharness.sh protocol-paths`; never "no
human is watching", "never ask", "authorised by X", or any keep-going
instruction the Loop does not carry. `./joharness.sh authority` reads VERIFIABLE
only when the rules this checkout runs (`joharness.sh`, `.agents/harness`,
`.claude`, `joharness.conf`) equal `origin/main`'s — proof of review, not of a
human hand.

## Start each run fresh

Start each run in a new session at the Lineup's orchestrator tier; never
resume the last one ("Can we continue"): a resumed session pays a cache
re-warm on its whole context (`orchestrate-reference.md`, "Fresh session
line"). Within one run the cost compounds too: `send_later` wakes the SAME
session and pass N re-reads passes 1..N-1. So after
`JOHARNESS_ORCHESTRATOR_PASSES` passes the wake carries `retire=yes`, and it
keeps running passes. The keeper, on its next wake or a doorbell, retitles it
`💤 orchestrator (retired): <owner/repo>` and starts the successor with that
wake as its prompt, `pass=1`, no leads (`orchestrate-reference.md`, RETIRE;
`keeper.md`, SWAP); the retired session's next wake does nothing. A run that
ends on its own (DRAINED, a PAUSED exit, a human's stop) retitles itself the
same way as its last act (`orchestrate.md` §4, RUN END). The pass count
decides, never a control-plane field.

**One spawner, one turn.** Only the keeper starts an orchestrator, and it
retires the old one in the same turn it starts the new one. The old one works
until then; it is retitled before the new one exists, so there is no second
fleet; the swap waits while the old one's wake is under 5 minutes away. A
refused `create_session` after the retitle can leave none until the next
hourly wake. A session runs one turn at a time, so a doorbell and an hourly
wake never both start one. Pass entry's duplicate check stops any second one a
human start makes, and the older rebuilds `@new` from manager titles, since
the duplicate's unclaimed spawns live only in its ledger.

**What the keeper copies.** The successor's prompt is the retired session's
own pending wake: the text that session would have run itself, so the swap
trusts nothing new. A doorbell's text is never read, so a session that
messages the keeper can make it check sooner, never write a prompt.

**Lineage stays flat.** A `create_session` child sits one level below its
parent; a session reads its `lineage` (`depth`, `limit`) only from
`get_session` with no `session_id`. At `depth == limit`, `create_session`,
`send_later` and every trigger call refuse ("No user or organization setting
changes this limit"). Every orchestrator the keeper
starts sits at the keeper's depth plus one, so retiring never deepens.
Without an up-to-date heartbeat nothing swaps: the orchestrator keeps arming
in the same session, and "## 0. Start" stops one at the cap with the reason
in its push. Managers sit one level below their orchestrator; only
`orchestrate.md` and `keeper.md` call `create_session` or `send_later`
(`grep -ln 'send_later\|create_session' .claude/commands/*.md`). Managers:
[`agent-selection.md`](agent-selection.md), Cost levers, "Fresh session".

## Heartbeat: making the fleet long

Role titles open with one emoji per role (glossary, role title); the
platform adds the Routine's `⚡`.

Dispatch makes the fleet WIDE; the heartbeat makes it LONG. Each session
claims, merges, ends, and the fleet survives only while something fires
the next. Periodic roles add no scheduler and no Routine: their `DUE` lines
ride `dispatch`, which the orchestrator the keeper starts reads.

The heartbeat is a Routine bound to one keeper session per repo
(`.claude/commands/keeper.md`); its prompt `/keeper` names the role and the
title guards it (Prompt, below). The keeper rules live outside
`orchestrate.md`, so an orchestrator never holds the keeper check, which
would start another orchestrator. Each hourly wake, the keeper looks for a
pending `/orchestrate pass` wake bound to an `🎼 orchestrator: <owner/repo>`
(glossary, role title) session, or a `RUNNING` or `PENDING` orchestrator it started itself or
that started it; none = it starts a fresh orchestrator with `create_session`. A live one
whose wake carries `retire=yes` is swapped (above). A replace re-roots the
keeper at the replacing session's depth plus one, which is why REGISTER
checks `depth + 2 < limit` before it deletes anything.

**Registered by `/orchestrate`.** The heartbeat registers itself when an
orchestrator starts and none exists ("## 0. Start" step 5, REGISTER). REGISTER
starts the keeper with `/keeper register`: that first turn takes the post and
starts nothing, so it never starts a second orchestrator onto the registering
one's DRAINED queue. The first hourly wake (`/keeper`) runs the check. The
requester's veto is the pause: a Routine with `enabled` false and an empty
`ended_reason` is never re-enabled, edited or replaced, and nor is one made in
the UI. Any `ended_reason` but `auto_disabled_session_gone` counts as a pause,
and a replace takes only a Routine whose prompt is exactly `/keeper` (or the
older spec's `/orchestrate keeper`). A pause stops the hourly restarts, not a
running orchestrator's `send_later` chain; the human's stop does both
(`orchestrate-reference.md`, "Human stop").

**Bound, not fresh.** A Routine `create_trigger` makes from a session with
`create_new_session_on_fire` reads `created_via: meta_mcp`; its fired session
has `sources: []`, no `create_session`, `list_sessions`, `get_session` or
GitHub tools, and the permission check refuses `./joharness.sh` from the
clone it makes (`create_trigger` + `fire_trigger`). `create_trigger` takes no
repository. A keeper made with `create_session` and a `source_url` has the
repository and the tools, so the Routine wakes it instead. "Run now" fires a
fresh session titled `⚡ <Routine name>` with no repository and no
`/orchestrate`, live keeper or not; on a Routine whose keeper is `ARCHIVED` it
also rebinds `persistent_session_id` to it while `last_run` reads
`SUCCEEDED`. So "Run now" never restarts the fleet; a new `/orchestrate`
session does, keeper archived or not: the check reads `keeper-gone` and
REPLACE restores the keeper. The check runs every pass and its `get_session`
on the bound session is never skipped: its `ok` line carries `session_status`
and `updated_at`, which only that read returns.

**Keeper liveness reads wakes, not sessions.** `list_sessions` is too large
to read hourly into one persistent context; a pending wake costs one
`list_triggers` (account-wide, each wake with its `persistent_session_id` and
`derived_state.prompt`) and a `get_session` per candidate. An orchestrator
mid-pass has no pending wake, so the keeper also counts the one it last
started, and its own `parent_session_id`, while that reads `RUNNING` or
`PENDING`: an hourly wake can land inside the parent's first start (the
orchestrator whose REGISTER or replace made the keeper), before it arms a
wake. A human-started orchestrator missed that way makes two; "## 0. Start"
step 3 lets the older proceed and the newer exit. A DRAINED fleet costs one
short orchestrator session an hour.

The spec every orchestrator checks at start and on every pass after the first
(`orchestrate-reference.md`, "## 0. Start" step 5; a session-made stale one is
replaced, any other `heartbeat stale` or `heartbeat duplicated` line pushes):

- **Name**: exactly `heartbeat: <owner/repo>` — how the check tells it from
  another repo's heartbeat.
- **Binding**: `persistent_session_id` = a session titled `🔑 keeper:
  <owner/repo>` (glossary, role title), not `ARCHIVED`. An archived keeper disables the Routine
  (`auto_disabled_session_gone`); the next `/orchestrate` replaces both.
- **Cadence**: hourly floor (`*/5 * * * *` is refused). The Routine backs
  the `send_later` chain; it does not replace it.
- **Prompt**: exactly `/keeper`. It invokes the keeper command; the
  keeper's title guards it. A Routine on the older spec's `/orchestrate keeper`
  still counts as up to date: `orchestrate.md` sends a keeper-titled
  session to `keeper.md`, so a rename never costs a replace.
- **Stop**: `update_trigger` `enabled: false` pauses (the veto),
  `delete_trigger` removes and lets the next `/orchestrate` register a new
  one. A Routine not named exactly `heartbeat: <owner/repo>` never counts and
  is never touched. Read `last_run`, never `next_run_at` (a paused Routine
  keeps a stale one).
- **The chain can end silently.** A `send_later` link can be delivered and
  never run (`SUCCEEDED`, identical to a healthy link, however long idle), or fail with `auto_disabled_session_gone`. `last_run` reports
  delivery, not execution — which is why the Routine exists.
- **A frozen orchestrator still reading `RUNNING`** makes every started
  orchestrator exit at step 0's one-orchestrator check. Unresolved.
- **Firing over a live fleet**: nothing special — claimed plans are not free;
  an unpushed claim is invisible.

## Not constrained, by decision

No cap on work per run, no halt on red `main`, no ban on sessions spawning
sessions. A session proposes them with evidence; it never adds one on its
own judgment (money, `.agents/harness/AGENTS.md`, Decide alone). The lever is the Routine pause.
