---
workstream: unsupervised-mode
status: in-progress
branch: claude/unsupervised-mode
pr: none
plan: none
session: https://claude.ai/code/session_0126bZYruEVL7vNBLb7RXF4v
agent: opus
updated: 2026-08-24
next: Open PR for the requirement plus its three plans; do not implement them here
---

## Goal

Requester wants Joharness to keep working for hours unattended: when the
queue drains, an idle session should generate its own work, run the full
Loop including the merge, and fan out across free plans — all gated on a
mode. Captured as `docs/product/unsupervised-mode.md` and decomposed into
three plans.

## Decisions

- Autonomy level, endurance mechanism and hard limits were put to the
  requester on 2026-08-24 and answered: full loop including merge; fan-out
  spawning parallel sessions; one limit only, no unsupervised edit under
  `.agents/harness/`. A cap per run, halting on red main, and banning
  session-spawns-session were each offered and declined. Recorded in the
  requirement's Constraints so a decomposing session does not reinstate
  them as a judgment call.
- Three plans, `needs`-chained on the gate: `unsupervised-mode-gate`
  (switch plus guard, ships together — a guard landing after the autonomy
  is a guard landing late), then `unsupervised-edge-work` and
  `unsupervised-fanout`, which both touch `queue-context.sh` and so are
  never parallel with each other.
- The "not invent work" rule (`.agents/harness/AGENTS.md:24`) gains a
  written exception at the rule itself, gated on the mode. Rejected the
  alternative of branching silently in the hook: a rule that stops meaning
  what it says is worse than no rule.
- Edge research surface is a CLOSED list, in `.agents/docs/plans/README.md`.
  Every source is checkable against the checkout, so a generated plan is
  auditable against evidence. Open-ended sourcing is the failure mode for
  a literal reader.
- Fan-out spawning stays in the agent's hands, not `joharness.sh`. Shell
  cannot reach session tooling, and a hook that shells out to an agent
  runtime couples the harness to one client.
- Endurance falls out of fan-out rather than a long-lived session: each
  spawned session runs one plan and ends, its merge changing the queue the
  next one reads. State stays in git, so a hung session costs one plan.

## Rejected

- Implementing any of the three plans on this branch. The requirement is
  product-level and the plans are separately schedulable at opus/xhigh;
  bundling them would put an unattended-merge feature into one unreviewed
  diff.
- Writing the mode into `.agents/harness/` defaults. Mode lives in
  `joharness.conf`, which is per-repo and NOT synced to consumers, so no
  consumer inherits autonomy by syncing the harness.
- A `docs/unsupervised.md` at repo root. Harness-level doc belongs under
  `.agents/docs/`, per the layer split.

## Review

- r1: `unsupervised-fanout` cited `queue-context.sh:325-331` as the
  fan-out branch; 325 is the preceding `Plus one planning session` line and
  the branch opens at 326. Repointed. (fixed)
- r2: all 10 anchors across the three plans re-read against HEAD —
  `joharness.sh` 74 / 733, `AGENTS.md` 24, `queue-context.sh` 16 / 200 /
  205 / 227 / 326 / 327 / 333. Each lands on the named line. (fixed — no
  others wrong)
- r3: stated the risk of full-loop autonomy with one guardrail to the
  requester once, then built to the chosen spec. The declined limits are
  recorded as explicit non-goals rather than argued again in each plan.
  (wontfix — requester's call, ratified 2026-08-24)

## Blockers

None. Note the requirement is satisfied only when the last of its three
plans merges; that PR deletes the requirement file too.

## Where to look

- `docs/product/unsupervised-mode.md` — Constraints, the three declined
  limits.
- `.agents/harness/queue-context.sh:333` and `:205` — the two edge paths
  the mode branches.
- `.agents/harness/queue-context.sh:327` — the fan-out line that already
  exists and is advisory today.
