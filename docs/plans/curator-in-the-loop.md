---
plan: curator-in-the-loop
urgency: normal
agent: opus
effort: high
needs: none
requirement: orchestrated-mode
scope: joharness.sh, .agents/harness/selftest/dispatch.sh, .claude/commands/curate.md, .claude/commands/drain.md, shared:.agents/harness/AGENTS.md, shared:.agents/docs/orchestrated.md, shared:.agents/docs/plans/README.md
---

## Goal

Requester, 2026-09-11, on being shown a curator wired only into orchestrated
mode: *"It should be part of the normal cycle which you start with /start"*,
then *"Work is produced regularly; so it also has to run regularly"*.

Both are corrections of what `docs/plans/curator-role.md` delivered. `/start`
routes by mode (`joharness.sh:cmd_start`) to `.claude/commands/drain.md` under
supervised and unsupervised, and to `orchestrate.md` under orchestrated — and
the curate cadence was printed only by `dispatch`, which only the orchestrator
reads. A repo on the default mode could never reach the curator.

The second sentence kills the trigger, not just the wiring. Counted on this
repo's `origin/main` 2026-09-11, plan files added or changed per week over the
last 12: `0` for weeks -12 to -4, then `32`, `55`, `10` for weeks -3 to -1;
gap between plan-touching commits median `0.6h`, p90 `6.6h`
(`git log --format=%ct origin/main -- docs/plans`). A 168h clock is wrong in
BOTH directions — eight firings over nothing in the quiet stretch, and about
three while 97 plan-file changes landed in the busy one. A cadence for
something whose need is driven by production has to be driven by production.

## Scope

- `joharness.sh` — `dispatch_curate_due`, ONE reader both `drain` and
  `dispatch` call, printing the due state and its reason. Due when EITHER
  holds since the last curate landed:
  - `JOHARNESS_CURATE_PLANS` plan files added or changed on the base branch
    (production: new plans arrive with untrue declarations). Counted from git
    with `--full-history`, same reason the landing is.
  - `JOHARNESS_CURATE_HOURS` elapsed (rot: code moves UNDER a plan, so its
    anchors break with no plan file changing — the staleness rule,
    `.agents/docs/plans/README.md`). Kept for exactly that, not as the
    primary trigger.
  `0` disables either trigger independently; both `0` disables the cycle.
- `joharness.sh:cmd_drain` — the same `curate :` line `dispatch` prints, and
  when due a block naming `/curate` as this session's work. Placed AFTER the
  edge block and BEFORE the queue verdict: finishing still outranks starting,
  and a due curate makes the queue truthful before a session picks from it.
  Reported at `DRAINED` too, where it is the idle queue's real work — the gap
  `curator-role` recorded and did not close.
- `joharness.sh:cmd_dispatch` — reads the same helper, so the orchestrator and
  a supervised session cannot disagree about whether one is due.
- `.claude/commands/drain.md` — one route: curate due and none in flight =
  read `curate.md`, that is the item.
- `.claude/commands/curate.md` — drop the orchestrated framing. The role is
  any mode's; only the SPAWNER differs (a human's `/start`, or the
  orchestrator). It edits `docs/plans/` and no protocol path, so it is not
  SUPERVISED ONLY and an unattended session may take it.
- `.agents/harness/AGENTS.md` step 2 — one clause: a due curate is queue work,
  where it sits in the pick order, and that it is not inventing work because
  every plan it touches already exists.
- `.agents/docs/orchestrated.md`, `.agents/docs/plans/README.md` — correct the
  rows and paragraphs that say orchestrated-only, and replace the accepted
  idle-queue gap with what closes it.

## Out of scope

- A Routine or cron. `/start` is the driver the requester named, and the
  production trigger is what makes it regular.
- Changing what the curator DOES (repair, declutter, propose, and the bounds
  on each). Only when it runs and who can reach it.
- Letting a session take a curate as a SECOND item. One item per session
  holds: a due curate is the item, or it is not this session's.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `.agents/harness/selftest.sh` — 0 failed, count read off the run.
- Cases, each red with its branch reverted: `drain` says a curate is due after
  N plan changes with the hours clock nowhere near; says it is due on hours
  with zero plan changes; says nothing when neither trigger is met; says
  nothing at `JOHARNESS_CURATE_PLANS=0 JOHARNESS_CURATE_HOURS=0`; names the
  in-flight branch instead of spawning when one is running; and prints the
  due block at `DRAINED` as well as beside a free plan.
- `drain` and `dispatch` print the SAME due verdict over one fixture — one
  reader, asserted from both entrypoints.
- `./joharness.sh drain` on this repo names a curate due, and the reason it
  gives matches a hand count of plan files changed since the last curate.

## Where to look

- `joharness.sh:cmd_start` — routes by mode; why the curator must reach
  `drain.md` and not only `orchestrate.md`.
- `joharness.sh:cmd_drain` — the edge block, then `drain_next`, then the
  DRAINED verdict: the three places the new block sits between.
- `joharness.sh:dispatch_curate_age_h` — the landing derivation to generalise,
  including the `--full-history` lesson (verifier r1 on `curator-role`).
- `joharness.sh:dispatch_curate_branches` — the in-flight scan both readers
  share.
- `.agents/harness/selftest/dispatch.sh` — the curate fixture to extend; its
  cadence case already retires on a branch and merges.

## Traps

- A fixture on a linear history cannot see the `--full-history` question at
  all (verifier r2). Any new cadence case retires on a branch and merges.
- `drain` runs in EVERY mode; a curate block that assumed orchestrated would
  be the same defect this plan fixes, one layer down.
- Measured number carries the command and the date, same sentence. The two
  knob defaults are written numbers until a run counts them, and say so.
- This plan's `scope:` holds protocol text, so it is SUPERVISED ONLY.
