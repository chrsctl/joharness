---
research: partly-core-plans-strand-their-slots
urgency: normal
agent: fable
effort: high
graduates: .agents/docs/orchestrated.md
---

## Question

Does dispatch's `DRAINED — nothing free` verdict state a fact it does not
measure when every unclaimed plan is a PARTLY-core plan — so the slots idle,
the requirement behind the plan never moves, and nothing tells the human
that the queue is waiting on their hand rather than empty?

## Echo

A plan whose `scope:` holds one core path among many non-core paths is
marked `CORE ONLY` and ranked out of the free list
(`.agents/docs/plans/README.md`, "A core path in `scope:`"). Dispatch then
reports the fleet DRAINED. Nothing in that verdict distinguishes "the queue
is empty" from "the queue holds work only a human can unblock, and has for
days". The orchestrator, which may not open a plan, cannot see the
difference either; the human only learns of it by asking why slots are
idle. What rests on the answer: whether a partly-core plan needs a route
(split, or a human-ready patch) and whether the verdict should name the
wait, as a `blocked` workstream already does.

## Sweep

`goal-directed`: everything needed to show the stall in one consumer and to
name the harness files that would change; not a survey of every consumer.

## What would settle it

YES if, in a consumer, (a) dispatch says DRAINED with free slots while
CORE ONLY plans exist, (b) at least one of those plans has non-core scope
an agent could build, (c) a requirement depends only on such a plan, and
(d) no output a human reads names the wait. NO if any of (a)–(d) fails —
e.g. the CORE ONLY plans are core-only in full (already red in `ci`), or
the verdict already names the wait somewhere a human sees.

## Method

In consumer `chrsctl/gx`, orchestrator session, 2026-10-13:

```
JOHARNESS_PENDING_SPAWNS=0 ./joharness.sh dispatch        # 00:44Z, pass 6
git ls-tree --name-only origin/main docs/plans/ docs/product/
git show origin/main:docs/plans/<stem>.md | grep -E '^(scope|requirement|agent):'
git log --diff-filter=A --format='%h %cI %s' origin/main -- docs/plans/<stem>.md
./joharness.sh protocol-paths
```

## Findings

- **Dispatch says DRAINED with half the cap idle.** `slots : 2 of 4 free`,
  `spawn ... nothing free`, `verdict : DRAINED — nothing free; 2 manager(s)
  in flight`. The two remaining plans are listed under `NOT YOURS — CORE
  ONLY`. (dispatch, 2026-10-13T00:44Z)
- **Both plans are PARTLY core, not core-only.**
  `crm-write-document-prints-a-pdf`: 14 scope entries, one core
  (`.github/workflows/ci.yml`), thirteen application paths
  (`platform/appform/...`, `platform/web/src/...`, `scripts/...`).
  `repo-scripts-are-shellchecked`: `.github/workflows/ci.yml, scripts/,
  run-all.sh` — two of three non-core. (`git show ... | grep scope`)
- **They have waited ~3 days.** Added 2026-10-10T00:23Z (35fbb4c5) and
  2026-10-10T13:18Z (d946ffe0); still on `main` 2026-10-13T00:44Z.
- **A requirement is stranded behind one of them.**
  `docs/product/propgen-full-surface.md` (on `main` since 2026-08-31) is
  named by `crm-write-document-prints-a-pdf` (`requirement:
  propgen-full-surface`), its only open plan. Dispatch counts the
  requirement as planned, so it never offers a planning manager, and the
  plan is never offered either.
- **Nothing told the human.** The human found the stall by asking the
  orchestrator "why do we have 2 slots unused", then "we have plans and
  product left". The orchestrator could only answer by reading the plan's
  `scope:` — a file its role forbids it to open
  (`.claude/commands/orchestrate.md`, "## Never"). A `blocked` workstream
  gets a push notification (health table, "human's" row); a CORE ONLY plan
  gets none.
- **The rule's stated reason does not cover the split.**
  `.agents/docs/orchestrated.md` (Bounds): "acceptance is all-or-nothing, so
  a partly-core plan cannot be finished either." True of the plan as
  written; it says nothing about splitting the core edit out, which is the
  move the human was told to make by hand.

Cost here: 2 of 4 manager slots idle for every pass since 2026-10-13T00:18Z
(and, by the add dates, available work held since 2026-10-10); one
requirement unmoved; two human round-trips to diagnose.

## Consequence for the queue

Two harness changes, both canonical's to decide:

1. **Name the wait.** Dispatch's verdict, when slots are free and the only
   remaining items are CORE ONLY, says so — e.g. `DRAINED — nothing free;
   2 plan(s) wait on a human core edit (oldest 3d): <stems>` — and the
   orchestrator's health table gets a row that notifies the human once, as
   it does for a `blocked` workstream. Files: `joharness.sh` (dispatch),
   `.claude/commands/orchestrate.md` (row + report), `.agents/docs/orchestrated.md`.
2. **Give a partly-core plan a route.** Options to weigh: (a) a surveyor
   pass (`/manage rescope`) that splits a partly-core plan into a free plan
   with the non-core scope plus a human-only note of the core edit; (b) a
   manager builds the non-core part and leaves the core edit as a patch in
   its pull request for the human to apply, labelled `human-review`; (c)
   keep the rule and only do (1). Note that a plan whose scope is core
   paths ONLY is red in `ci` — so (a)'s core remainder cannot itself be a
   plan file; it needs another home (issue, workstream note, or patch).

## Verification

UNVERIFIED by a second context. The numbers above come from one
orchestrator session's dispatch output and `git` reads in `chrsctl/gx`;
canonical re-counts them before acting (GROUNDED only after a second read).

## Graduates to

`.agents/docs/orchestrated.md` — the Bounds paragraph that de-ranks a
partly-core plan is where the route (or the decision to keep none) and the
verdict's wording belong; `joharness.sh` and `orchestrate.md` follow it.
