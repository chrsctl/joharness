---
plan: fanout-live-run
urgency: normal
agent: opus
effort: high
needs: none
requirement: unsupervised-mode
scope: docs/product/unsupervised-mode.md, docs/research/
---

## Goal

`unsupervised-fanout` shipped the mechanism: under unsupervised the queue
hook orders one session per wave-1 plan, naming each tier. Its tests prove
the wording, the gating and the wave arithmetic. They do NOT prove the
requirement's claim — that a fleet started this way keeps going for hours
without a human turn. That claim needs a run, and a run needs counted
numbers: sessions started, pull requests merged, hours unattended.

Carved out of `unsupervised-fanout` rather than left as an open criterion
under it, because the code merged and a plan whose build is done invites the
next session to build it again.

## Precondition, and why this is not claimable today

A fan-out needs a wave with TWO OR MORE members. Measured on `main`
2026-08-28 with `JOHARNESS_RUN_MODE=unsupervised
./.agents/harness/queue-context.sh`: 5 free plans, 5 waves, every wave
holding exactly one plan — each overlapping `unsupervised-sources` on
`joharness.sh`, `.agents/harness/selftest.sh` or `.agents/harness`. The hook
correctly orders "run it here, do not spawn for one", so a run today would
start no fleet and prove nothing.

Re-run that command before claiming this. Two plans in one wave, or the
queue cannot exercise what this measures.

## Scope

- Start one unsupervised session against a queue whose wave 1 holds at least
  two plans. Let it run.
- Record, as counted numbers with the commands that produced them: sessions
  started, pull requests merged, wall-clock hours unattended, and how the
  fleet ended.
- The record goes to `docs/research/` as a research node, and the
  requirement's `Satisfied when` gets the one line the evidence supports.

## Out of scope

- Changing the fan-out mechanism. If the run finds a defect, that is a
  finding and its own plan; this plan measures, it does not redesign.
- Removing the operator's stop. `.agents/docs/unsupervised.md` `## Stop` is
  proved and stays proved.
- Running it on a human's behalf without being asked. The run starts real
  sessions that merge their own pull requests to `main`; that is a resource
  and blast-radius decision, and the session that claims this plan asks
  before it starts and records the answer.

## Acceptance

- The run happened, with the four numbers above and the commands that
  produced them. A written assurance does not satisfy this — it is the one
  criterion `unsupervised-fanout` could not satisfy from a test.
- `./joharness.sh ci` — `ci: pass`.

## Where to look

- `.agents/docs/unsupervised.md` — the cadence, what the firing session is
  told, the operator procedure and the proved stop.
- `.agents/harness/queue-context.sh`, the `qc_mode` branches — what the
  fleet is actually ordered to do.
- `docs/product/unsupervised-mode.md`, Constraints — the three limits the
  requester declined 2026-08-24, which this run does not reinstate.

## Traps

- A fleet with no human watching still merges to `main`. Confirm the go, and
  confirm the stop is reachable before starting, not after.
- Counted numbers or nothing. "It ran for a while" is the written number
  this plan exists to replace.
