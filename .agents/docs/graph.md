# Harness graph

One graph, two halves, one substrate: git. Task half = how work flows.
Knowledge half = what sessions remember. Files are nodes, frontmatter
fields are edges, commits are provenance. NO stored graph anywhere — every
view derived at read time, so nothing rots. Extend the harness by adding a
node or edge type here, never by adding a state store.

Source: task-graph + KG pipeline rules from
[codejunkie99/graph-engineering](https://github.com/codejunkie99/graph-engineering)
(MIT License, Copyright (c) 2026 codejunkie99; ideas adapted, no text
reproduced — `.agents/NOTICE`).
Memory tiers match Zep/Graphiti agent-memory architecture
([arXiv:2501.13956](https://arxiv.org/abs/2501.13956)) — episodic,
semantic, summary — convergent, not copied.

## Nodes

| Type | Lives at | Tier |
| --- | --- | --- |
| Requirement | `docs/product/<requirement>.md` on base branch | product |
| Plan | `docs/plans/<plan>.md` on base branch | task |
| Research | `docs/research/<question>.md` on base branch | task |
| Workstream | `docs/handover/<workstream>.md` on work branch | episodic memory |
| Rule, trip-wire | layer's `AGENTS.md` | semantic memory |
| Why-explanation | `.agents/docs/*.md` | summary memory |
| Change | commit, branch, PR | execution + provenance |

## Edges

| Edge | Domain → range | Carried by |
| --- | --- | --- |
| `needs` | plan → plan | plan frontmatter. Open target file = blocked. |
| `research` | plan → research | plan frontmatter. Open target file = blocked. |
| `graduates` | research → `AGENTS.md` / `docs/` file | research frontmatter. Declared target; the `graduated` edge below completes it. |
| `requirement` | plan → requirement | plan frontmatter. Requirement nobody serves = unplanned, hook flags. |
| `plan` | workstream → plan | workstream frontmatter. The claim. |
| `agent` | plan or workstream → tier | frontmatter. Model that runs it. |
| `scope` | plan → paths | plan frontmatter. Declared touch-set; disjoint scopes = proven-parallel wave, overlap named at spawn. `touches` is the same edge measured after the fact. |
| touches | branch → branch | computed: changed-path intersection |
| graduated | workstream → `AGENTS.md` / `docs/` | merge commit that deletes the file |
| anchor | any → code | `path:symbol` line in Where to look |

Delete-on-merge makes file existence the edge state: open plan = not done,
workstream on branch = live claim. No status field to rot — field
discipline fails exactly when someone hurries.

## Rules

- Single-hop only. Every session question (what next, whose is it, what
  overlaps, why this rule) answers in one hop from hook output. Multi-hop
  need = re-run the value test before adding anything: single-hop lookups
  never justify a graph store.
- No stored graph, no auto-extraction, no embeddings. Derived state =
  second copy, rots (derivability rule, `.agents/docs/handover/README.md`).
  Measured elsewhere, 2026-08-28: basemode
  (github.com/ChristopherKahler/base, at 22e8b8c) stores its graph, and its
  own `docs/workspace-scoping.md` records that store stamping foreign
  projects into the wrong named graph, every session-start re-polluting
  what was cleaned by hand, ending in a planned full reset. Failure mode
  derive-at-read-time cannot have.
- No datastore for the work queue either. Storing every work item as a row
  and every action with an actor buys queries — attribution, work histories,
  audit trails — and costs a database, a daemon and a CLI as install
  prerequisites in every repo that runs the harness. This is a shell script
  plus markdown so that a clone, a runner or CI carries the whole thing with
  nothing installed, which is also what lets its own gates run inside CI.
  Re-open only if a question arrives that files cannot answer, never because
  querying looks convenient.
- A harness that lives in the repo has no long-running service, so it cannot
  watch, nudge, queue or schedule anything by itself; it travels everywhere
  instead, CI included. Neither side of that trade is more correct. Know
  which side a mechanism assumes before importing it from a system built on
  the other one.
- Fusion manual: graduation ritual, human-reviewed. Wrong merge worse than
  missed merge.
- Provenance = commits. Never hand-write time or source into a file.
- Every edge into main passes a review node, depth by the plan's tier
  (`agent-selection.md`), before the PR. Diamond rule — verify outside
  the context that wrote the code; self-grade alone misses own mistakes.

## Serving

SessionStart hook = retrieval. Injects the 1-hop neighborhood — this
branch's workstream, queue with `blocked by:` / `claimed on:` edges,
overlap warnings — and prints `git show` commands as edge traversals.
Instructions get skimmed; injected context is already in window.

Whole graph as a picture: `./joharness.sh graph` prints fenced mermaid,
derived at read time — paste into any GitHub comment, rendered natively.

One branch as counts: `./joharness.sh scorecard` reads this branch's commits
since its merge base. Reports. Nothing gates on it.
