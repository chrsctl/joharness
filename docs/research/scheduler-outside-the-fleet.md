---
research: scheduler-outside-the-fleet
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/unsupervised.md
---

## Question

What can run the fleet's staleness check on a cadence without being a thing
that goes stale with the fleet?

## Echo

Issue #249 asks for a mechanism that regularly checks whether sessions have
gone stale and acts accordingly. The requester's own comment separates the
two halves and says only one is missing: the DECISION PROCEDURE already
exists and is complete — `orchestrate.md`'s health table distinguishes
`RUNNING` from `IDLE` from `FAILED`, requires two observations rather than
one, names the action per row, and already disqualifies two fields that look
decisive and are not. What does not exist is anything that makes the
procedure RUN. It runs inside an orchestrator pass, and an orchestrator pass
happens only because a previous pass armed the next one. The checker is
itself a session, subject to exactly the staleness it watches for, and when
it stops nothing notices — including itself.

So this is not "how do we detect staleness". It is: what has a liveness that
does not depend on an agent session staying alive, and is reachable from
this harness. Every candidate that is itself a session inherits the failure,
which the issue states outright and which is why it was filed as the whole
remaining question rather than as a plan.

What rests on the answer: the measured cost of not having one. The self-armed
chain broke at 2026-09-13 04:14Z and did not resume until 2026-09-16 14:54Z
— three days, zero merges, every manager frozen (four control-plane reads
after the thaw showed `updated_at` within 30 seconds of each other, so they
resumed together rather than working through it), and `dispatch` then
printing ~82h push ages that measured the freeze rather than the work.
Measured in a consumer repository, orchestrated run of 2026-09-16.

## Sweep

`comprehensive`, over candidate schedulers only. Everything that could fire
a recurring check against this repository's fleet, with its failure mode
named — not a survey of scheduling generally, and not a re-derivation of the
health table, which is settled.

Comprehensive rather than goal-directed because the answer is a choice among
mechanisms, and a shortlist that omits one is indistinguishable from a
shortlist where that one loses. The first cut of #249 was withdrawn for
exactly that class of error.

## What would settle it

For each candidate: does its firing depend on an agent session being alive?
A candidate settles the question when the answer is NO and it can reach the
control plane and the git view. A candidate whose firing depends on a
session is ruled out by that fact alone, however good the rest of it is.

Then, because a scheduler that fires is not yet a scheduler that acts: what
does the thing it starts have permission to do? The measured run recorded
`archive_session` refused with `Interfere With Workloads`, and the session
working #249 was denied a plain `kill` on a process it had started itself,
same reason — so a procedure that depends on STOPPING something needs a
branch for being refused, wherever it runs. A candidate that can fire but
cannot act does not settle it either; it relocates the gap.

Either answer closes this: a candidate exists and is named with its failure
mode and its permission ceiling, or none does, and what is written down is
that the fleet's liveness is an operator responsibility with no mechanism
behind it — which is a real answer and changes what `unsupervised.md`
promises.

## Method

Run on this repository and this account's control plane, 2026-10-08.

```bash
# candidate 2: does a repository-side schedule fire while the fleet is frozen?
#   mcp__github__actions_list method=list_workflow_runs resource_id=update.yml
#   workflow_runs_filter={"event":"schedule"}        # 7 runs, all Mondays
# every first-parent merge gap, largest first — not two chosen commits
git log --first-parent --merges --format='%H %cI' origin/main   # then diff
                                                 # consecutive pairs
git rev-parse 7d629d2^1                            # = 51556f6a: consecutive

# candidates 1 and 3: what does a control-plane Routine bind to, and what
# happens to it when that thing goes?
#   list_triggers recurring=true include_completed=true   # {"data":[]} = zero
#                                                         # recurring, all pages
#   list_triggers enabled=false                           # the 3 auto-disabled
#   list_triggers limit=100 (x2 pages)                    # 203 sampled
# NOTE: plain `list_triggers limit=20` hides fired one-shots
# (include_completed defaults false) and returns 5 with has_more=false. Read
# as a census it is wrong by two orders of magnitude; the first draft of F1
# and F4 did exactly that. Use the server-side filters above.

# the ceiling the fired thing inherits
sed -n '120,140p' .agents/docs/orchestrated.md     # health table: count the
                                                   # `any` rows, do not assume
sed -n '1,60p' .claude/commands/orchestrate.md     # REQUIRED tools, OPTIONAL table
grep -n "send_later" .claude/commands/orchestrate.md
sed -n '1,25p' .github/workflows/update.yml        # GITHUB_TOKEN, suppressed events
```

- The heartbeat `.agents/docs/unsupervised.md` already describes. Read what
  it is, what arms it, and whether it re-arms from outside a session.
- A repository-side scheduler (a scheduled workflow in `.github/workflows/`).
  Fires on GitHub's clock; the question is what it can reach.
- A Routine or scheduled trigger on the control plane. Fires on the
  platform's clock rather than a session's — but the fired thing IS a
  session, so the question is whether the FIRING survives the fleet, which
  is a different claim from the session surviving.
- An operator action with money attached, stated as such rather than
  engineered around. `.agents/docs/unsupervised.md` already takes this
  position for the fleet outliving its sessions, and it may be the honest
  answer here too.

For each, record the evidence — the file, the command, or the platform
behaviour observed — not an assertion about what the mechanism ought to do.

## Findings

CLOSED. The question had a hidden third term: a Routine's firing and its
DELIVERY are separate, and only the delivery dies with the fleet. Every
candidate sorts on that distinction.

Verdicts below are after a second context re-derived every number and
refuted three claims (Verification, below). What it corrected is kept
visible rather than smoothed out, because two of the three were in
load-bearing sentences.

**F1 — GROUNDED. The fleet has no scheduler today. It has a chain of
one-shot self-bound wakes.** Decisive test, server-side rather than a
sample: `list_triggers` with `recurring: true` and `include_completed: true`
returns `{"data":[],"has_more":false}` — **zero** cron-driven Routines on
this account, across all pages. Corroborated by enumeration: 203 Routines
sampled, every one `cron_expression: ""` with `persist_session: true`, which
is a `run_once_at` reminder bound to one existing conversation — exactly
what `send_later` creates (its own description: "a thin wrapper over
create_trigger (a self-bind + run_once_at Routine)").
`.claude/commands/orchestrate.md:28-30` makes `send_later` REQUIRED, "the
next pass", and `:560` arms it at `delay_minutes` =
`JOHARNESS_HEALTH_MINUTES`. So the health pass has no clock of its own: it
has a chain, each link armed by the session before it. The heartbeat
`.agents/docs/unsupervised.md` documents has never been created, and this
account's live orchestrator ledger still carries "heartbeat Routine (#285)"
as an item to report to the human.

**F2 — GROUNDED on the auto-disable, narrower than first written on the
mechanism.** `list_triggers` with `enabled: false` returns exactly 3
Routines (`has_more: false`), and **all 3** carry `ended_reason:
auto_disabled_session_gone`. So the platform retiring a self-bound Routine
when its session goes is 3 of 3.

The fire-then-fail-in-milliseconds shape is **2 of 3**, not 3.
`trig_015U4LHgo4qM7rj59C1VcxsV` carries `last_run.status:
ROUTINE_RUN_STATUS_FAILED`, `fired_at` `2026-10-08T01:37:21.999685552Z`,
`finished_at` `2026-10-08T01:37:22.006743Z` — 7.06 ms, a delivery attempt
and not a turn; `trig_017SSQM1G9U2gaNtejz8rbRn` fits too, at 6.67 ms. The
third, `trig_01CiQm78q3MprMA5dYaFKkmy`, has **no `last_run` field at all**:
it auto-disabled with no recorded run, by a path these records do not show.
Stated rather than averaged away — the conclusion does not need it, and
"all three" was false.

What the two do establish is the freeze mechanism, read off the control
plane rather than inferred: the chain does not go quiet because a session
forgot to arm the next pass. The pass WAS armed, it fired, it failed to
deliver into a session that had gone, and the platform then disabled the
Routine. Nothing re-arms, and nothing enabled is left to notice.

**F3 — the orchestrator half GROUNDED; the hinge is REASONING, and is
labelled as such.** `create_trigger`'s targeting contract names three
modes: mode 1 "fires into THIS SESSION", mode 2 "fires into a SPECIFIC
OTHER SESSION you name", mode 3 "spawns a FRESH SESSION in this environment
on each firing". Only mode 3's delivery target does not pre-exist. That
much is read off the surface.

That `auto_disabled_session_gone` therefore **cannot** apply to mode 3 is
INFERENCE from that contract plus F2's contrast, not an observation: per F1
this account holds zero mode-3 Routines, so there is no measurement in
either direction. This is the claim the whole answer rests on, so it is
named as untested here and in the graduation rather than presented as
measured. Closing it means creating a recurring Routine, which is spend and
therefore the human's — the one check this session may not run, and the
reason the graduation ends with what to verify after creating it.

The second half is GROUNDED and is what makes mode 3 enough on its own:
under `orchestrated` a fresh session naming no item IS the orchestrator
(`.agents/docs/orchestrated.md:34`, "nothing named = orchestrator, run
`/orchestrate`"; `:91`, "The default role is the orchestrator"), and
`orchestrate.md:99` is "## 2. Health pass — before any spawn". So a mode-3
firing lands in the existing procedure. The Routine need know nothing about
staleness: it starts a pass, and the pass already carries the complete
decision procedure issue 249 says is complete. 249's missing half is
CONFIGURATION, not code — which is also why a recurring check built INTO
the orchestrator loop cannot close it: that one cannot catch the
orchestrator dying.

**F4 — GROUNDED on a large sample, not a census. The ceiling is the
connector trap.** Every one of the 203 Routines sampled reads
`mcp_connections: []`; `has_more` was still true at 200, so this is a large
consecutive sample and the claim is written as one. A fired session with no
`mcp__*` tools cannot read a session record and cannot reach GitHub, so it
can neither health-check nor merge: `orchestrate.md:28-30` makes
`create_session` and one liveness read REQUIRED — "absent, say so and stop,
the loop cannot run" — and `:104-105` repeats it for the liveness read. So
mode 3 fires outside the fleet and still delivers nothing useful unless it
carries connectors. The remedy is the one already in
`.agents/docs/unsupervised.md`: create it from the claude.ai Routines UI,
then `fire_trigger` once and check the fired session reached GitHub.

**F5 — WEAK, and a narrower correction than first written.**
`.agents/docs/unsupervised.md` says "a Routine created from a session stores
NO connectors", and the `create_trigger` surface now carries a `connectors`
parameter — "Optional list of connector names the Routine's fired sessions
may use… the stored grant applies to every future firing" — so the trap is
an argument's default rather than a property of the surface. WEAK, not
UNGROUNDED, because the doc's measured OUTCOME still holds everywhere it can
be checked (F4: all sampled `mcp_connections: []`); nothing has ever passed
the parameter, so the observation is consistent and only the general clause
is stale. And the doc is not silent about its evidence: the same bullet
discloses "Verified from two sessions for this organization". The leading
clause overreaches; the bullet does not.

**F6 — GROUNDED, and the sharpest evidence in this file. A repository-side
schedule fires independently of the fleet, proved by firing THROUGH two
outages.** First-parent merge gaps on `origin/main`:

| gap | from | to |
| --- | --- | --- |
| 435.02h | `c96088a3` `2026-09-17T19:55:00Z` | `0d726e09` `2026-10-05T22:56:30Z` |
| 92.08h | `51556f6a` `2026-09-12T19:36:06Z` | `7d629d29` `2026-09-16T15:40:58Z` |

The 92.08h gap is the canonical-side span of the window the Echo measures
in a consumer, and `update.yml`'s scheduled run `34841570372` fired at
`2026-09-14T12:06:00Z` inside it — `conclusion: success`, on `head_sha
51556f6a`, the tip the freeze left behind. The 435.02h gap is 18.1 days and
is stronger still: **three consecutive weekly scheduled runs fired inside
it** — `2026-09-21T12:14:58Z`, `2026-09-28T13:11:10Z`,
`2026-10-05T13:53:54Z` — and all three carry the same `head_sha
c96088a3`, the frozen tip. A scheduler that fired on time, three times, on
the same dead commit, while the fleet merged nothing for eighteen days.
GitHub's clock owes the fleet nothing. Both gaps are genuine rather than
cherry-picked: `git rev-parse 7d629d2^1` is `51556f6a`, so those two are
consecutive on the first-parent line, and the table is the top of a sorted
enumeration of every first-parent gap.

**F7 — GROUNDED once corrected. It can fire and it cannot judge, so on its
own it relocates the gap.** The first version of this finding said every row
of the health table keys on the control plane. That is **false**: of the 11
rows at `.agents/docs/orchestrated.md:128-138` (header `:126`), 4 read `any`
in the control-plane column — `looping`, `leftover`, `blocked`, `done` — and
`looping` sat inside the range the claim cited. **7 of 11** key on
`session_status`, `status_bucket`, `status_detail`, `updated_at`,
`last_served_model` or `session_context.sources`, and the file's own verdict
rule is the load-bearing part: "a verdict here needs both halves, and
dispatch prints only the git half" (`:122-124`).

That is enough to rule the runner out, and it is why the corrected version
still concludes the same thing. An Actions runner has no `mcp__*` server at
all, so it holds one half of a verdict the procedure says needs two — and
the half it holds is the one this harness has disqualified twice: push time
is not liveness in either direction, and `liveness-in-a-long-turn` closed by
finding that `updated_at` carries no staleness threshold at all. The 4 rows
it could read are not the staleness rows; they are `blocked`, `done`,
`leftover` and a churn count. Its write ceiling is the second half: on
`GITHUB_TOKEN` a pull request it opens gets no ci runs
(`.github/workflows/update.yml:15-18`, "GitHub suppresses
workflow-on-workflow events"). An issue is inside that ceiling.

**F8 — GROUNDED. Its cadence cannot carry the threshold anyway, and the
spread is worse than a median shows.** The 7 scheduled runs of `0 6 * * 1`
started 60.7, 418.9, 350.9, 366.0, 375.0, 431.2 and 473.9 minutes after
their cron time. Six of the seven started **5h51m to 7h54m** late; one
started 1h01m late. Not a tight distribution around a median — a cluster
hours out, with a single early outlier. `JOHARNESS_STALL_MINUTES` is 45
(`joharness.sh:5030`), so this schedule cannot be the clock for a
45-minute threshold. A mode-3 Routine's hourly floor
(`.agents/docs/unsupervised.md`: `*/5 * * * *` refused, "the minimum
interval is 1 hour") is already coarser than the threshold; this is coarser
again by an order of magnitude.

**F9 — GROUNDED, and it is the residue the answer cannot engineer away.
Nothing notices the scheduler itself stopping, and one bounded mechanism
can.** A mode-3 Routine is recurring spend, so creating it is the human's
(`.agents/harness/AGENTS.md`, Decide alone) — already this file's position
for the fleet. Pausing is the veto, and a paused Routine keeps a stale
`next_run_at` that reads like a missed firing: confirmed on all three
disabled Routines, each advertising a `next_run_at` AFTER its own disable
(`trig_015U4LHgo4qM7rj59C1VcxsV`: `enabled: false`,
`auto_disabled_session_gone`, `next_run_at: 2026-10-09T01:37:21Z`). So the
operator cannot learn from the Routine's own record that it stopped.

What F6 and F7 leave is one narrow thing a repository-side schedule CAN do:
the predicate "this repository has merged nothing in N hours" needs no
per-session judgement, reads only the git view, and is actionable inside
`GITHUB_TOKEN`'s ceiling via `issues: write` — and an open GitHub issue is a
queue item the Loop already reads (step 2). F6's 435-hour gap is exactly
what it would have caught, three times over. It cannot health-check a
manager and must never try; it can convert "nobody notices" into "an issue
appears", including when what stopped is the Routine. Its own failure mode,
named: GitHub disables scheduled workflows after a long stretch of
repository inactivity, so it dies in exactly the outage that outlasts the
threshold it watches for — which is why it is an ALERT and not a mechanism
the fleet rests on.

## Consequence for the queue

No plan, and that is the answer rather than a gap. F3 names a mechanism
whose creation is recurring spend, which the Loop reserves for the human
(`.agents/harness/AGENTS.md`, Decide alone) — so there is nothing here for a
session to build, and the plan this node was holding open can never be
written. What a session CAN do is record which mechanism, with which
argument, and what to check after creating it. That is the graduation, and
it is the whole deliverable.

F9's repo-quiet alert is the one buildable piece and is deliberately NOT
filed as a plan: a new always-on alerting mechanism is product direction
(same clause), and the requester's current direction for this repo is
removal. It is named in the graduation and in this pull request's body for
the human to take or drop. Filing a plan for it would commit the queue to
building something nobody asked for.

Issue 249's remaining half is untouched by this node and stays open: the
duplicate-holder check (flag any branch named by more than one
non-archived session) is a row in the health table, not a question about
what runs it.

One interaction the next session needs. `docs/plans/drop-unsupervised-docs.md`
deletes this node's `graduates:` target and names this file in its `scope:`.
Its own Scope commits to moving the Heartbeat section into
`.agents/docs/orchestrated.md`, and the answer above is written INSIDE that
section so the move carries it. The declaration was not changed: the target
still exists on `main` and is still where the heartbeat is documented, so
redirecting `graduates:` would have split one question across two files —
the thing the Graduates-to rule exists to prevent.

## Verification

Second context, `general-purpose` subagent at opus, re-ran every
control-plane and GitHub read from a session that made none of these
findings (`.agents/docs/research/README.md`, "Verification is not
optional"). It re-derived the numbers rather than accepting them, and it
changed the file:

- **F7 refuted.** "Every row of the health table keys on the control plane"
  is false — 4 of 11 rows read `any`, and one of them (`looping`) sits
  inside the line range the claim cited. Re-counted here before the fix:
  `looping`, `leftover`, `blocked`, `done`. The finding now reads 7 of 11
  and rests on the file's own both-halves rule instead. It was the one
  outright error, and it was load-bearing.
- **F2 narrowed.** The fire-then-fail-in-milliseconds shape is 2 of 3
  disabled Routines, not 3: `trig_01CiQm78q3MprMA5dYaFKkmy` carries no
  `last_run` at all. The auto-disable is still 3 of 3.
- **F1 and F4 re-based.** The first draft read `list_triggers limit=20` as a
  census — 5 Routines, `has_more: false` — when the default hides fired
  one-shots. The verification found 203 Routines over two pages with
  `has_more` still true, and supplied the decisive test instead:
  `recurring: true` with `include_completed: true` returns `{"data":[]}`,
  server-side, so zero recurring Routines across all pages. F1 is stronger
  for it; F4 now claims a sample and not a census.
- **F6 strengthened by its own evidence.** The verification found a larger
  first-parent gap the first draft had missed — 435.02h, with three
  consecutive weekly scheduled runs inside it on one frozen `head_sha`.
  Re-derived here from a sorted enumeration of every first-parent gap, not
  from the window the Echo named.
- **F5 softened.** "States absolutely" was unfair: the same bullet discloses
  "Verified from two sessions for this organization".
- **F8 re-characterised.** Six of seven delays cluster 5h51m–7h54m with one
  outlier at 1h01m, so a median misdescribes the spread.
- **F3's hinge marked as reasoning.** That `auto_disabled_session_gone`
  cannot apply to a mode-3 Routine follows from the targeting contract and
  F2's contrast; it is not observed, because this account holds no mode-3
  Routine. GROUNDED and measured are not the same word, and the claim the
  answer rests on is the unmeasured one.

F1, F6 and F8 were confirmed to the digit. The remaining gap is stated
rather than closed: the one candidate that settles the question is the one
this session may not fire, because firing it is recurring spend.

## Graduates to

`.agents/docs/unsupervised.md`. That file already carries the fleet-outlives-
its-sessions problem and names the heartbeat as its answer with the operator
cost attached; a scheduler for the staleness check is the same question about
the same fleet, and splitting them across two documents is how two readers
get two answers.
