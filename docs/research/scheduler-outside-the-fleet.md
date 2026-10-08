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
git log -1 --format='%cI' 51556f6a   # last merge before the freeze
git log -1 --format='%cI' 7d629d2    # first merge after it
git log --merges --format='%cI %h %s' origin/main --since=2026-09-10 --until=2026-09-18

# candidate 1 and 3: what does a control-plane Routine bind to, and what
# happens to it when that thing goes?
#   mcp__claude-code-remote__list_triggers limit=20   # 5 Routines, has_more=false

# the ceiling the fired thing inherits
grep -n "status_detail\|updated_at\|control plane" .agents/docs/orchestrated.md
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

**F1 — GROUNDED. The fleet has no scheduler today. It has a chain of
one-shot self-bound wakes, and the platform retires each one when its
session goes.** `list_triggers` (limit 20, `has_more: false`) returns 5
Routines for this account and **every one** carries `cron_expression: ""`
with `persist_session: true` — that is, each is a `run_once_at` reminder
bound to one existing conversation, which is exactly what `send_later`
creates (its own description: "a thin wrapper over create_trigger (a
self-bind + run_once_at Routine)"). `orchestrate.md:29` lists `send_later`
as REQUIRED, "(the next pass)", and `orchestrate.md:560` arms it with
`delay_minutes` = `JOHARNESS_HEALTH_MINUTES`. So the cadence of the health
pass is a chain in which each link is armed by the previous session, and
nothing anywhere fires on a clock of its own. No recurring Routine exists:
the heartbeat `.agents/docs/unsupervised.md` documents has never been
created, and this account's live orchestrator ledger still carries
"heartbeat Routine (#285)" as an item to report to the human.

**F2 — GROUNDED. A self-bound Routine does not merely fail to help: it
fires, fails delivery in milliseconds, and AUTO-DISABLES.** Three of the
five are `ended_reason: auto_disabled_session_gone`
(`trig_015U4LHgo4qM7rj59C1VcxsV`, `trig_017SSQM1G9U2gaNtejz8rbRn`,
`trig_01CiQm78q3MprMA5dYaFKkmy`, created 2026-10-08, 2026-09-10 and
2026-09-07). The first carries the whole mechanism in one record:
`last_run.status: ROUTINE_RUN_STATUS_FAILED`, `fired_at`
`2026-10-08T01:37:21.999685552Z`, `finished_at` `2026-10-08T01:37:22.006743Z`
— **7 milliseconds**, which is a delivery attempt and not a turn. This is
the measured freeze's mechanism, read off the control plane rather than
inferred: the chain does not go quiet because a session forgot to arm the
next pass; it goes quiet because the pass WAS armed, fired into a session
that had gone, and the platform then disabled the Routine. Nothing re-arms,
and nothing is left enabled to notice.

**F3 — GROUNDED, and it is the answer. `create_new_session_on_fire: true`
is the one variant whose delivery target cannot be the thing that died,
because it does not exist until the moment of firing.** `create_trigger`
names the three targeting modes: mode 1 fires into the calling session,
mode 2 into a named existing session, mode 3 "spawns a FRESH SESSION in
this environment on each firing". Modes 1 and 2 are the `persist_session:
true` shape F2 measures auto-disabling. Mode 3 holds no reference to any
session, so there is nothing for `auto_disabled_session_gone` to be true
of. Combined with a `cron_expression` rather than `run_once_at`, its
firing depends on the platform clock alone. That is a NO to the sweep's
first question, which is what settles the question.

What makes it the scheduler for the STALENESS CHECK specifically, with no
second mechanism added: under `JOHARNESS_MODE=orchestrated` a fresh session
whose prompt names no item is the ORCHESTRATOR (`./joharness.sh start`
routes it to `orchestrate.md`; the session-start hook prints the same
split), and an orchestrator pass runs the health table. So a mode-3
recurring Routine does not need to know anything about staleness: it starts
a pass, and the pass already carries the complete decision procedure issue
249 says is complete. The gap #249 names closes by CONFIGURATION, not by
new code — which is why no plan could be written before the mechanism was
chosen.

**F4 — GROUNDED. Its permission ceiling is the connector trap, and the
trap is confirmed on every Routine this account holds.** All 5 records read
`mcp_connections: []`, including the four with `created_via: meta_mcp` —
created from a session. A fired session with no `mcp__*` tools cannot read
a session record and cannot reach GitHub, so it can neither health-check
nor merge: `orchestrate.md:29` makes `create_session` and one liveness read
REQUIRED, "absent, say so and stop, the loop cannot run". So mode 3 fires
outside the fleet and still delivers nothing useful unless it carries
connectors — the remedy `.agents/docs/unsupervised.md` already names
(create it from the claude.ai Routines UI, then `fire_trigger` once and
check the fired session reached GitHub).

**F5 — WEAK, and a correction to what `unsupervised.md` states absolutely.**
That file says "a Routine created from a session stores NO connectors". The
`create_trigger` surface now carries a `connectors` parameter — "Optional
list of connector names the Routine's fired sessions may use" — and its
description says the result warns when a Routine stores none. So the trap
is now conditional on an argument rather than unconditional on the surface.
WEAK deliberately: no Routine on this account exercises it (all five read
`mcp_connections: []`), creating one is recurring spend and therefore the
human's, and a parameter's existence is not a measurement of its effect.
The UI route stays the instruction; the absolute wording does not.

**F6 — GROUNDED. A repository-side schedule fires independently of the
fleet. Proved by firing THROUGH the outage.** `origin/main` shows a
**92.1-hour** merge gap, `51556f6a` at `2026-09-12T19:36:06Z` to `7d629d2`
at `2026-09-16T15:40:58Z` — the canonical-side span of the window the Echo
measures in a consumer. `update.yml`'s scheduled run 6
(`id 34841570372`, `event: schedule`, `conclusion: success`) fired at
`2026-09-14T12:06:00Z`, inside that gap, on `head_sha 51556f6a` — the
pre-freeze tip, because nothing had moved. A scheduler that fired on time
while every session in the fleet was frozen, on the commit the freeze left
behind. GitHub's clock owes the fleet nothing.

**F7 — GROUNDED. It can fire and it cannot judge, so on its own it
relocates the gap.** Every row of the health table keys on fields only the
control plane carries — `session_status`, `status_bucket`, `status_detail`,
`updated_at`, `last_served_model`, `session_context.sources`
(`.agents/docs/orchestrated.md:129-134`) — and an Actions runner has no
`mcp__*` server at all. What it does have is the git view, whose one
available signal the harness has already disqualified twice: push time is
not liveness in either direction (the handover protocol's own rule, and why
`/who` exists), and `liveness-in-a-long-turn` closed by finding that
`updated_at` cannot carry a staleness threshold at all. So the runner holds
exactly the signals that are known not to decide the question. Its write
ceiling is the second half: on `GITHUB_TOKEN` a pull request it opens gets
NO ci runs — recorded at `.github/workflows/update.yml:16-18`, "GitHub
suppresses workflow-on-workflow events" — so it cannot even carry work to
step 7 without the PAT that file names.

**F8 — GROUNDED. Its cadence cannot carry the threshold anyway.** The 7
scheduled runs of `0 6 * * 1` started 60.7, 418.9, 350.9, 366.0, 375.0,
431.2 and 473.9 minutes after their cron time (median 375.0). Reliable, and
late by up to **7h54m**. `JOHARNESS_STALL_MINUTES` is 45
(`joharness.sh:5030`), so a schedule drifting by hours cannot be the clock
for a 45-minute threshold. A mode-3 Routine's hourly floor
(`.agents/docs/unsupervised.md`: `*/5 * * * *` refused, "the minimum
interval is 1 hour") is already coarser than the threshold, and this is
coarser again by an order of magnitude.

**F9 — GROUNDED, and it is the residue the answer cannot engineer away.
Nothing notices the scheduler itself stopping, and one bounded mechanism
can.** A mode-3 Routine is recurring spend, so creating it is the human's
(`.agents/harness/AGENTS.md`, Decide alone) — already this file's position
for the fleet. Pausing is the veto, and a paused Routine keeps a stale
`next_run_at` that reads like a missed firing: confirmed again here, where
`trig_015U4LHgo4qM7rj59C1VcxsV` is `enabled: false` with
`ended_reason: auto_disabled_session_gone` and still advertises
`next_run_at: 2026-10-09T01:37:21Z`. So the operator cannot learn from the
Routine's own record that it stopped. What F6 and F7 together leave is one
narrow thing a repository-side schedule CAN do: the predicate "this
repository has merged nothing in N hours" needs no per-session judgement,
reads only the git view, and is actionable inside `GITHUB_TOKEN`'s ceiling
via `issues: write` — and an open GitHub issue is a queue item the Loop
already reads (step 2). It cannot health-check a manager and must never
try; it can convert "nobody notices" into "an issue appears", including when
what stopped is the Routine. Its own failure mode, named: GitHub disables
scheduled workflows after a long stretch of repository inactivity, so the
watchdog dies in exactly the outage that outlasts the threshold it watches
for — which is why it is an ALERT and not a mechanism the fleet rests on.

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
the thing `## Graduates to` exists to prevent.

## Verification

Second context, `general-purpose` subagent, re-ran the control-plane and
GitHub reads from a session that made none of the findings above
(`.agents/docs/research/README.md`, "Verification is not optional"). It
confirmed F1, F2, F4, F6 and F8 against the same sources and challenged
F5 down from GROUNDED to WEAK — the `connectors` parameter exists on the
surface and no record on this account shows it taking effect, which is not
the same claim. F3's mode-3 behaviour is GROUNDED on the tool surface's own
targeting contract and on F2's measured contrast; it is NOT measured
end to end, because measuring it means creating a recurring Routine, which
is spend and therefore the human's. Stated here rather than smoothed over:
the one candidate that settles the question is the one this session may not
fire.

## Graduates to

`.agents/docs/unsupervised.md`. That file already carries the fleet-outlives-
its-sessions problem and names the heartbeat as its answer with the operator
cost attached; a scheduler for the staleness check is the same question about
the same fleet, and splitting them across two documents is how two readers
get two answers.
