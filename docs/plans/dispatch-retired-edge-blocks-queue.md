---
plan: dispatch-retired-edge-blocks-queue
urgency: urgent
agent: opus
effort: high
needs: none
requirement: orchestrated-mode
scope: joharness.sh, .agents/harness/queue-context.sh
---

## Goal

The same serialisation `dispatch-held-plan-blocks-queue` removed for HELD
plans is still reachable through a RETIRED EDGE's item. A plan that
`dispatch` withholds from the spawn list still takes a wave, so every plan
whose scope meets it is told to WAIT for a pass it will sit out — and the
verdict reads `spawn nothing this pass` with slots free.

Found by the `verifier` reviewing PR #227, on the merged head of that branch
and `main`, 2026-09-06.

## The mechanism

Two mechanisms landed within hours of each other and neither knows about the
other:

- The hook holds a plan behind a live claim and, since PR #227, leaves a held
  plan OUT of the wave partition — "a plan that does not run this pass cannot
  make another wait for it".
- `dispatch` withholds an item whose branch is past its retire commit
  (`joharness.sh:dispatch_retired_edges`, PR #225): the branch owns no
  workstream file, so the hook sees no claim, calls the plan FREE and
  partitions it.

So the hook partitions a plan `dispatch` will not spawn. Same symptom, other
half of the same rule.

## The measurement

Reproduced on the merged head. Plans `aretired(src/x src/shared)` and
`zpeer(src/shared)`; branch `mgr-retired` claims `aretired`, then runs step
7's retire commit — deleting `docs/handover/aretired.md` and
`docs/plans/aretired.md` — and pushes:

```
docs/plans/zpeer.md (agent: sonnet)  wave 2  WAIT — overlaps aretired on src/shared in this pass: spawn it only after that one
verdict   : NOT DRAINED — 1 item(s) waiting behind others: spawn nothing this pass
```

with `slots: 3 of 4 free` and `aretired` absent from the spawn list entirely.

## Scope

- A plan withheld as a retired edge's item must not be partitioned, exactly
  as a held plan is not. The rule is already written
  (`.agents/docs/orchestrated.md`, Concurrency); this is the third reader of
  it.
- Decide WHERE, and say why in the pull request: the hook computes the waves
  but cannot see retired edges (it reads claims, and a retired edge has
  none); `dispatch` can see them but does not partition. One of them has to
  learn the other's fact, and the repo's own precedent is that deriving it
  twice is the shape that keeps costing (PR #227's own Decisions, and the
  BLOCKED-CLAIM marker that pull request added for exactly this reason).
- The WAIT note carries only the FIRST collision, so dropping a WAIT because
  its note names a withheld plan is not sound on its own — the plan may also
  collide with a live one. Whatever is built must survive a plan that meets
  both, the way the `bothsides` fixture does for the blocked case.

## Out of scope

- Widening `dispatch_retired_edges`. The scan is right; nothing here says
  what counts as an edge.
- The claims view. Untouched by this, as by PR #225.

## Acceptance

- A fixture with a retired-edge item and a peer sharing one of its paths: the
  peer is NOT told to WAIT, and the verdict counts it as free. Assert on
  `dispatch` output, not on a helper.
- It can fail: the same fixture against the current head prints the WAIT line
  quoted above.
- A plan meeting BOTH a retired-edge item and a live claim is still HELD, and
  the `bothsides` case still passes.
- **Consumer-side** (SHIPS): in a consumer running orchestrated mode, a
  manager at step 7 with its pull request open must not make the queue behind
  its item wait. The cheap version is the fixture above; canonical has no
  fleet (`.agents/docs/plans/README.md`, SHIPS).

## Where to look

- `joharness.sh:cmd_dispatch` — `edge_items`, the free loop's `note`/`hold`
  handling, and the `..unverified` sentinel beside them.
- `.agents/harness/queue-context.sh` — `free_held`, and the wave partition
  that skips a held plan.
- `.agents/docs/orchestrated.md` Concurrency — the rule both readers owe.
