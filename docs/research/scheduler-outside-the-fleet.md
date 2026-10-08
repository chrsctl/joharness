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
`.agents/docs/unsupervised.md` documents has never been created. (A live
orchestrator ledger still lists "heartbeat Routine (#285)" as an item to
report; issue 285 itself CLOSED 2026-10-07T23:56:27Z, so that ledger line is
stale — and 285's body is evidence this node had to read, not a pointer to
forward. Reading it refuted F2 and overturned the first draft's "no plan".)

**F2 — GROUNDED as a shape, REFUTED as the freeze's mechanism.** The first
draft of this finding called the auto-disable "the freeze mechanism". That is
false, and the repository's own closed issue 285 says so — it measured the
18-day outage and recorded the terminating link as
`trig_014mzpnKTVrFHdz8mggYE7HA`: `last_run.status:
ROUTINE_RUN_STATUS_SUCCEEDED`, `ended: run_once_fired`, 5 ms, "identical in
every field to the nineteen healthy links before it". The wake WAS
delivered; the message "sat queued and was delivered on resume
2026-10-05T22:45Z, 18 days and 2 hours later". No failed delivery, no
auto-disable.

What this session measured is real and is a SECOND shape.
`list_triggers` with `enabled: false` returns exactly 3 Routines
(`has_more: false`), all 3 `ended_reason: auto_disabled_session_gone`; two
of them also carry a failed run — `trig_015U4LHgo4qM7rj59C1VcxsV` at
`fired_at` `2026-10-08T01:37:21.999685552Z`, `finished_at`
`2026-10-08T01:37:22.006743Z` (7.06 ms), `trig_017SSQM1G9U2gaNtejz8rbRn` at
6.67 ms. The third carries no `last_run` at all.

So a chain ends two ways, and the contribution of this node is the
distinction rather than either shape:

| shape | last link reads | leaves behind |
| --- | --- | --- |
| delivered, turn never ran (issue 285) | `SUCCEEDED`, `run_once_fired` | nothing distinguishable from health |
| delivery failed (measured here) | `FAILED`, `auto_disabled_session_gone` | a disabled Routine carrying a reason |

The first is the expensive one and is invisible after the fact, because
`last_run` reports delivery and not execution — `list_triggers`' own
contract, quoted in 285: "records that the wake was delivered (SUCCEEDED) or
failed to deliver, not how the turn went". Neither shape leaves pending work
to find: a dead chain has no next link to examine.

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

The second half is GROUNDED but NOT sufficient, and the first draft claimed
it was. Routing checks out: under `orchestrated` a fresh session naming no
item is the orchestrator (`joharness.sh:cmd_start`; `.agents/docs/
orchestrated.md:34`, `:91`), and the health pass is `orchestrate.md:99`. But
two preconditions sit ABOVE that line, and the first draft's own Method
(`sed -n '1,60p'`) stopped one line short of the one that matters:
`orchestrate.md:61-63` makes a session that finds another titled
`orchestrator: <owner/repo>` with `session_status: RUNNING` exit before
reaching step 2.

So there IS a path where a mode-3 firing runs no health pass: an
orchestrator frozen but still `RUNNING`. That state is measured, not
hypothetical — `orchestrated.md:129` defines `stalled` as "`RUNNING`,
`status_detail` unchanged across two passes", on a row read byte-identical
across 172.273s. Every firing then exits, forever, while the Routine's own
record stays enabled and healthy.
`orchestrated.md:547-549` names the live case and the dead case and not this
one: "Firing over a live orchestrator is safe — the new one finds the title
`RUNNING` and exits. Firing over a dead one is the point." Frozen-but-
`RUNNING` is neither. Recorded in the graduation as unresolved, with the
second-order point that the precondition is itself a one-signal verdict on a
control-plane field, which the same file forbids.

What survives of the claim: a mode-3 Routine needs no new decision procedure
(the pass carries it) and 249's missing half is configuration rather than
code — but "it fires, therefore the check runs" does not hold.

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

**F8 — GROUNDED, and it cuts against the answer as well as the workflow.**
The 7 scheduled runs of `0 6 * * 1` started 60.7, 418.9, 350.9, 366.0,
375.0, 431.2 and 473.9 minutes after their cron time: six between 5h51m and
7h54m late, one at 1h01m. So "fires on time" is false of the workflow —
"fires at all" is the true claim, and the first draft used the wrong one.
`JOHARNESS_STALL_MINUTES` is 45 (`joharness.sh:5030`), so this schedule
cannot clock a 45-minute threshold.

The same test disqualifies mode 3 as a CADENCE, which the first draft noted
in a subordinate clause and then ignored. Its floor is 1 hour — 60 > 45 —
and `orchestrate.md:560` arms the chain at `JOHARNESS_HEALTH_MINUTES`,
default 10 (`joharness.sh:8012`), so the recommended Routine is 6x slower
than the thing it was being offered to replace. Issue 285 is explicit that
the chain is not wrong as a cadence: 19 consecutive passes, median gap under
12 minutes. The correct conclusion, and the one now in the graduation: mode
3 is DURABILITY, not cadence. It backs the chain rather than carrying it.

**F9 — GROUNDED, and it is the residue the answer cannot engineer away.
Nothing notices the scheduler itself stopping, and one bounded mechanism
can.** A mode-3 Routine is recurring spend, so creating it is the human's
(`.agents/harness/AGENTS.md`, Decide alone) — already this file's position
for the fleet. Pausing is the veto. The operator cannot learn from a
Routine's own record that it stopped: all three AUTO-disabled Routines still
advertise a `next_run_at` after their own disable
(`trig_015U4LHgo4qM7rj59C1VcxsV`: `enabled: false`,
`auto_disabled_session_gone`, `next_run_at: 2026-10-09T01:37:21Z`) — which
is the same trap as the pause rule and NOT an instance of it, since nobody
paused these. The pause path stays tested only by the throwaway Routine the
graduation target already cites. And per F2 the expensive shape leaves no
disabled Routine at all.

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

**One plan, and the first draft was wrong to say none.** It rested "no plan"
on the mechanism being recurring spend, which is true of the Routine and
true of nothing else. Issue 285's own "Shape of a fix" names two changes
that are neither spend nor product direction, and neither is implemented:

1. `/orchestrate`'s first pass checks for a live heartbeat Routine and says
   so loudly when there is none — "no heartbeat: this fleet dies with this
   session." `grep -n -i heartbeat .claude/commands/orchestrate.md` returns
   one unrelated hit at `:639`. 285 calls this "what would have surfaced
   this on 2026-09-17 rather than 18 days later".
2. `orchestrate.md` § 4 says what the `send_later` chain is NOT. It reads as
   the continuity mechanism; it is the cadence mechanism, and F8 now puts a
   number on the difference.

`docs/plans/heartbeat-is-a-precondition.md` carries both, plus the
frozen-but-`RUNNING` hole F3 found, which belongs with them because it is
the same question — what an orchestrator pass owes the fleet before it
spawns anything. Both files it touches are protocol text, so the queue hook
marks the plan `SUPERVISED ONLY` from its `scope:` and ranks it out of the
free list automatically (`queue-context.sh:519-521`). That is the correct
home: a session under this mode may not commit there, and this node's
session did not.

What stays unplanned is the mechanism itself. Creating the Routine is
recurring spend, which the Loop reserves for the human
(`.agents/harness/AGENTS.md`, Decide alone), so the graduation records which
mechanism, with which argument, and what to check after creating it —
`fire_trigger` once, then confirm the fired session reached GitHub, NEVER
`last_run`, per F2.

F9's repo-quiet alert stays unfiled: a new always-on alerting mechanism is
product direction, and the current direction for this repo is removal. Named
in the graduation and in the pull request body for the human to take or drop.

Issue 249's remaining half is untouched and stays open: the duplicate-holder
check (flag any branch named by more than one non-archived session) is a row
in the health table, not a question about what runs it.

One interaction the next session needs. `docs/plans/drop-unsupervised-docs.md`
deletes this node's `graduates:` target and names this file in its `scope:`.
Its own Scope commits to moving the Heartbeat section into
`.agents/docs/orchestrated.md`, and the answer above is written INSIDE that
section so the move carries it. Worth knowing before that plan runs: the
section is now ~135 lines and the destination already has its own 6-line
`## Heartbeat` to reconcile against.

## Verification

TWO second contexts, neither of which wrote the diff.

**Research verification** (`general-purpose`, opus) re-derived every number
and changed seven claims: F7 refuted (4 of 11 health-table rows read `any`,
so "every row" was false); F1 and F4 re-based after the first draft read
`list_triggers` defaults as a census when they hide fired one-shots — 5
versus 203 sampled, with `recurring: true, include_completed: true`
returning `{"data":[]}` as the decisive server-side test; F2 narrowed from 3
records to 2; F6 strengthened by a larger gap the draft had missed (435.02h,
three weekly firings on one frozen `head_sha`); F5 softened; F8
re-characterised off its median; F3's hinge marked as reasoning.

**Branch verifier** (`.claude/agents/verifier.md`, opus, step 5) then found
what the first pass could not, because it read the repository's own closed
issues rather than only the control plane. Six findings this node would not
have merged over:

- F2's attribution was FALSE. Issue 285 measured the 18-day freeze and
  records it as delivered, `SUCCEEDED`, `run_once_fired` — not failed
  delivery and not auto-disable. The shape this node measured is a second,
  different shape. Rewritten; the distinction is now the contribution.
- The post-creation check this node prescribed, `last_run` SUCCEEDED, is the
  exact signal 285 proves cannot work: the contract says `last_run` reports
  delivery, not execution, and the terminating link read SUCCEEDED while the
  fleet sat dead. Replaced with the execution check.
- F3's "it fires, therefore the pass runs" skips `orchestrate.md:61-63`: a
  frozen-but-`RUNNING` orchestrator makes every firing exit before the
  health pass. The first draft's Method stopped one line short of it.
- Mode 3's 1-hour floor exceeds `JOHARNESS_STALL_MINUTES` 45 and is 6x
  `JOHARNESS_HEALTH_MINUTES` 10 — the same cadence test this node used to
  rule the workflow out. Conclusion corrected to durability-not-cadence.
- "Firing on time" contradicted this node's own next paragraph.
- "No plan" overstated: 285 names two free, unimplemented fixes. Now a plan.
- Plus: the "5 of 5" census survived in a bullet the correction never
  reached; auto-disabled Routines were offered as instances of the PAUSE
  rule; 285 was cited as live when it closed the day before.

Both contexts confirmed F1, F6 and F8's numbers to the digit, and the
verifier re-derived both merge gaps and all seven cron delays independently
(435.025h, 92.081h; 374.97/431.17/473.90 min for the three in-gap runs).

The remaining gap is stated rather than closed, and is now smaller than the
first draft implied: mode 3's durability is REASONING, nobody can fire it
from here, and the frozen-`RUNNING` path means even a fired Routine is not
proof a pass ran.

## Graduates to

`.agents/docs/unsupervised.md`. That file already carries the fleet-outlives-
its-sessions problem and names the heartbeat as its answer with the operator
cost attached; a scheduler for the staleness check is the same question about
the same fleet, and splitting them across two documents is how two readers
get two answers.
