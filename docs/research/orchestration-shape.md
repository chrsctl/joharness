---
research: orchestration-shape
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/product/README.md
---

## Question

Is this harness's orchestration — peer sessions, claim-by-push, scope waves,
no lead — the right shape, and what does it cost?

## Echo

joharness runs N sessions with no coordinator. Each cuts a branch from
`main`, claims by pushing a workstream file, and merges its own pull
request. Parallel safety comes from `scope:` prefixes declared in plan
frontmatter, proven disjoint by the queue hook. There is no orchestrator
anywhere in the harness. I am asking whether that is a considered position
or an accident, and what the field says it costs.

## Sweep

Goal-directed. Architecture class and its named failure modes; not the
whole of multi-agent systems, and not agent-to-agent protocols, which this
harness has no channel for anyway.

## What would settle it

The architecture class named, its predicted failure modes listed, and each
checked against what this repo actually did in a measured window. A match
means the design is coherent and its costs are known; a mismatch means
something else is going on.

## Method

Web search 2026-08-25 on orchestration patterns and on parallel coding
agents. Local measurement over `87d130a..origin/main`, the window from this
evening's first comparison to now:

```
git log --oneline --merges 87d130a..origin/main | wc -l          -> 39
git log --oneline 87d130a..origin/main --grep=Reconcile... | wc  -> 19
git log 87d130a..origin/main --format='%b' | grep session_ | ... -> 8
git branch -r | grep -c 'origin/claude/'                         -> 37
```

## Findings

- **The class is decentralized peer, and the harness is a clean example.**
  No central controller; agents make local decisions. The literature's
  stated trade is control and observability against resilience and
  scalability: peer systems "scale to hundreds of agents without
  architectural changes" and are "significantly harder to debug, observe,
  and predict".
- **The costs joharness avoids are real and quantified.** An orchestrator
  is a single point of failure, a context-window bottleneck holding every
  worker's result, and a throughput ceiling — one source works it to ~6.7
  tasks/second at a 3-second lead call with 20 workers, and ~950ms of
  coordination overhead against 500ms of processing in a 4-agent pipeline.
  A design with no lead pays none of that.
- **The cost it does pay showed up in the measurement.** 19 of 39 merges in
  the window carried a reconcile — just under half. The literature predicts
  precisely this: "coordinating global behavior becomes challenging...
  enforcing system-wide priorities gets difficult without central
  oversight."
- **Worktrees would not have helped.** Nine open-source orchestrators all
  isolate with git worktrees, and this harness deliberately does not,
  isolating by branch plus claim instead. But worktrees give file-level
  isolation only: "the conflict problem moves to the PR merge stage",
  which is exactly where this repo's 19 reconciles landed. Adopting them
  would move nothing.
- **The field's answer to duplicate work is what joharness already has.** A
  shared task document every agent reads, where each "picks up a task,
  marks it in-progress, and marks it done" — the queue plus claim-by-push,
  one for one.
- **And it was bypassed tonight anyway.** Two sessions answered the same
  human request two minutes apart (#55 and #57), producing competing
  designs for one problem; one was closed. The queue was never consulted,
  because a request arriving mid-session does not enter it. The shared task
  document only prevents duplication for work that goes through it.

## Consequence for the queue

The architecture is coherent and its trade is the right one for a fleet of
short-lived sessions: no lead means no bottleneck, and 8 sessions ran
without one. Nothing here argues for adopting an orchestrator or worktrees.

Two consequences that do follow.

`unsupervised-fanout` spawns one session per free plan in a wave. At 8
sessions the reconcile rate was 19 of 39; fan-out raises session count,
and contention at the merge stage is the cost that scales with it. The plan
should carry that number and say what it expects to happen to it, rather
than treating width as free.

The duplication gap is unclaimed by any plan. Claim-by-push covers work
that enters through the queue; a request typed at a running session enters
nowhere, and two sessions took the same one tonight. Neither more isolation
nor a lead fixes that — the queue is the shared document, and the gap is
that mid-session requests never reach it.

## Verification

PENDING — no second context has checked these claims. The checks that
matter: whether the ~6.7 tasks/second and ~950ms coordination figures come
from a measured source or an illustrative one, and whether "nine
open-source orchestrators all use worktrees" is a real survey result or a
vendor blog's framing. The local counts are reproducible from the commands
above and need no external check.

## Graduates to

`.agents/docs/product/README.md`, which already holds the branch-flow
reasoning this file extends.
