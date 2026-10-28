---
research: parked-defect-waits-for-clerk-cadence
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/orchestrated.md
---

## Question

Does `dispatch` leave a manager parked on a `defect:` issue that no plan names to wait out the clerk's full `JOHARNESS_CLERK_HOURS` cadence, when that issue is the only thing between the park and a RESUME?

## Echo

A manager that finds a defect outside its scope files an issue and parks (`defect: #<n>`). The only path from an issue into the queue is the clerk, and the clerk runs every 24h. So a defect filed just after a clerk pass sits unplanned for up to 24h, and nothing in dispatch shortens that, although a parked manager is waiting on exactly that plan. `UNPLANNED` at 48h only notifies a human. The open question is whether that wait is a cadence gap or intended.

## Sweep

`goal-directed`: one consumer run (chrsctl/gx, 2026-10-28), and the dispatch knobs that govern the park-to-plan path.

## What would settle it

- **Yes:** dispatch prints `clerk : not due` while a manager is `PARKED #<n>` on an issue no plan names.
- **No:** some dispatch line makes the clerk due (or otherwise routes #<n> to a plan) as soon as a park names an unplanned issue.

## Method

From the consumer, on 2026-10-28 at about 18:15Z:

```
JOHARNESS_PENDING_SPAWNS=0 ./joharness.sh dispatch
./joharness.sh clerk
grep -n "DEFECT_PLAN_HOURS\|CLERK_HOURS" .agents/docs/orchestrated.md joharness.sh
```

The issues were read through GitHub MCP `issue_read`.

## Findings

- **Two managers were parked on unplanned defects while the clerk read "not due".**
  - dispatch printed `clerk : not due — 10h since the last clerk landed (clerk-2026-10-28, #1008) (of 24h)`.
  - In the same output: `PARKED #1011: a defect's, holds no slot, parked 10h ago: waits for a plan naming #1011 to retire, or the base to move` (pm-milestones).
  - A second manager, crm-layer-verify, had parked on #1033 (filed 15:50Z).
  - `./joharness.sh clerk` printed `planned : #206 #823 #889 #979 #980 #986`, so neither #1011 nor #1033 was planned.
  - #1011 was filed at 08:13Z, minutes after clerk #1008 landed. Its own text says it stays red until 2026-11-01 unless it is fixed.
- **The only escalation is a notification at 48h.**
  - `orchestrated.md` sets `JOHARNESS_DEFECT_PLAN_HOURS` at 48, described as "two clerk cycles".
  - It turns the row into `PARKED #<n> UNPLANNED`, notified once. It never makes the clerk due.
  - Worst case is 24h before the clerk sees the issue, plus a plan cycle, plus the fix, while the parked branch drifts from main and its recheck respawns cost money. In this run one RECHECK respawn re-parked on the same red check.
- **What the human did to unblock it.**
  - The human asked to unblock the managers. The orchestrator spawned an extra clerk on the human's order (`orchestrate-reference.md` § Role sessions, "The human orders an extra role session").
  - That is the only lever the protocol has today, and it needs a human in the loop.

One finding was dropped. The keeper had started a fresh orchestrator with an empty ledger, after a human archived the live orchestrator by hand on purpose. That restart is by design, so the finding did not pass the gate.

## Consequence for the queue

One candidate change, for canonical to decide. Dispatch would mark `clerk DUE` early when an in-flight claim is `PARKED #<n>` on an issue that no plan on the base or a live branch names, and that park is older than a new knob. The knob could be `JOHARNESS_DEFECT_CLERK_HOURS`, default about 1, with 0 lifting it. It would ride the existing "at most one clerk in flight" bound. `orchestrated.md` would gain the knob row, and `JOHARNESS_DEFECT_PLAN_HOURS` would then measure a real clerk miss rather than cadence latency. Another option is to record that the 24h wait is intended, and say so beside `DEFECT_PLAN_HOURS`.

## Verification

Not yet verified from a second context. This is a consumer's report. Each finding quotes command output from one run.

## Graduates to

`.agents/docs/orchestrated.md`, which holds the knob table and the "parked on a defect" lifecycle that this changes.
