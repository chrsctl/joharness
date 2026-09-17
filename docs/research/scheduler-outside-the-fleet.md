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

Not yet run. The candidates to enumerate and test, each against the two
questions above:

```
# does it fire without a session alive?
# what can the thing it starts actually do?
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

OPEN. Nothing measured yet. Filed so the question survives the session that
found it, and so nobody builds the checker into the orchestrator loop again:
a recurring check that lives there cannot catch the orchestrator dying,
which is the failure that cost the most in the measured run by a wide
margin.

## Consequence for the queue

Issue #249's first cut merged (PR #253) narrowed to two items that do not
depend on this: the caution that a workstream file's `session:` line names a
writer rather than a worker, and the worked reading of a dead manager
wearing the LOOP row's shape. The rules half of that issue is carried by
`docs/research/liveness-in-a-long-turn.md`, which was a different question —
what the health pass may KEY ON — and was not blocked by this one. That one
has since CLOSED: its answer is the `status_detail`, `updated_at` row of
step 2's evidence table in `.claude/commands/orchestrate.md`, and the why is
under the knob table in `.agents/docs/orchestrated.md`. What it settles for
this node is narrow and worth knowing before designing a monitor: the
session record's `updated_at` cannot carry a staleness threshold at all,
because a frozen reading on a RUNNING row is ambiguous between a slow writer
and a session that has stopped — measured on a row whose every field, usage
counters included, was byte-identical across 172.273s.

No plan is blocked on this node today, deliberately. A plan for the
scheduler cannot be written before the mechanism is chosen, and one written
anyway would hand an unattended session a spawn with money attached.

## Verification

None yet; no finding to verify. When one exists it needs a second context
per `.agents/docs/research/README.md`, and that context must be able to
check the candidate's firing independently of whoever proposed it.

## Graduates to

`.agents/docs/unsupervised.md`. That file already carries the fleet-outlives-
its-sessions problem and names the heartbeat as its answer with the operator
cost attached; a scheduler for the staleness check is the same question about
the same fleet, and splitting them across two documents is how two readers
get two answers.
