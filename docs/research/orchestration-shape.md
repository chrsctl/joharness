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
  No central controller; sessions decide locally. The centralized/peer
  trade — predictable and observable against resilient and scalable — is
  restated across vendor writing, but it is NOT settled literature and no
  source states it in one coupled formulation. Treat it as the industry's
  working consensus, not a result.
- **The costs joharness avoids are real in kind, unquantified in degree.**
  An orchestrator is a single point of failure, a context-window bottleneck
  holding every worker's result, and a throughput ceiling. The figures
  circulating for those costs are blog arithmetic, not measurement — see
  Verification. A design with no lead avoids the failure modes; how much it
  saves is not a number anyone has published.
- **The cost it does pay is measured here, and only here.** 19 of 39 merges
  in the window carried a reconcile — just under half. That count comes
  from this repo, reproducible from the commands above, and is the only
  measured number in this file.
- **Worktrees would not have helped, and this is the well-sourced finding.**
  "Git worktrees provide file isolation without removing conflicts when
  multiple agents touch the same functionality"; "the conflict problem
  moves to the PR merge stage... where they surface as visible git
  conflicts instead of silent runtime overwrites." That is exactly where
  this repo's 19 reconciles landed, so adopting worktrees would move
  nothing. The claim that nine orchestrators were tested and all use
  worktrees does not survive checking and is dropped.
- **Claude Code ships task claiming with file locking, and joharness
  reimplements it by hand.** Agent teams (experimental,
  `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) give tasks three states —
  pending, in progress, completed — with "self-claim: after finishing a
  task, a teammate picks up the next unassigned, unblocked task on its
  own", and "task claiming uses file locking to prevent race conditions
  when multiple teammates try to claim the same task simultaneously". The
  task list lives at `~/.claude/tasks/{team-name}/`. joharness's queue plus
  claim-by-push is the same mechanism built on git instead.
- **A lead plus subagents measurably beats one agent at breadth-first
  work.** Anthropic reports a lead spinning up "3-5 subagents in parallel
  rather than serially", a separate CitationAgent pass, and a multi-agent
  setup outperforming the single-agent baseline "by 90.2% on our internal
  research eval". Internal eval, specific model pairing — attributable, not
  independently reproduced.
- **The duplication gap was ours, and it was bypassed tonight.** Two
  sessions answered the same human request two minutes apart (#55 and
  #57), producing competing designs for one problem; one was closed. The
  queue was never consulted, because a request arriving mid-session does
  not enter it. Claim-by-push only prevents duplication for work that goes
  through the queue.

## Consequence for the queue

The architecture is coherent and its trade is defensible for a fleet of
short-lived sessions: no lead means no bottleneck, and 8 sessions ran
without one. Nothing here argues for adopting worktrees, and the case
against an orchestrator is weaker than this file first claimed — the costs
are real in kind but the numbers behind them are not measurements.

A third option this file did not know about: Claude Code's agent teams
already implement claim-with-file-locking, the mechanism joharness builds
on git. Adopt-or-build, the same question `harness-glossary` now faces
about Vale, and with the same shape — the built-in is experimental and
stores state outside the repo, against a harness whose whole doctrine is
that git holds the state. Worth a research node of its own rather than an
answer here.

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

Checked by an independent context that did not write these
findings. Both figures this file flagged as suspect failed, and so did a
third claim it had not thought to flag.

- **6.7 tasks/second — ILLUSTRATIVE.** One blog's hypothetical: "if the
  orchestrator's LLM call takes 3 seconds and you have 20 workers... roughly
  6.7 tasks per second." No methodology, model or dataset; the arithmetic
  is 20 ÷ 3. It appears verbatim on a second site, which copied it — one
  source, not two. Dropped.
- **950ms against 500ms — ILLUSTRATIVE.** One blog, hedged with "roughly",
  no experimental setup. Dropped.
- **"Nine orchestrators tested, all use worktrees" — WEAK, and the "all" is
  false.** A vendor listicle with no disclosed methodology, and one of the
  nine lists worktrees as optional. Dropped.
- **The centralized/peer trade framing — WEAK.** The verifier could not
  find the quoted phrasing in any source, nor the paired formulation in one
  document. Vendor consensus, not literature. Reworded above.
- **Worktrees are file-level only — GROUNDED**, verbatim, and it is the
  finding this file's conclusion actually rests on.
- **Task claiming with file locking — GROUNDED**, and better than what it
  replaced: it is a shipped Claude Code feature, not a pattern to author.
- **Lead plus 3-5 subagents, separate citation pass, 90.2% — GROUNDED**,
  with the caveat that the eval is Anthropic-internal and model-specific.

The pattern across both verification passes on this branch: every number
that arrived through a search summary was weaker than it read, and every
claim that survived came from a primary source stating it directly.

## Graduates to

`.agents/docs/product/README.md`, which already holds the branch-flow
reasoning this file extends.
