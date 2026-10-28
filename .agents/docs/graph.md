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
| `needs` | plan → plan or requirement; requirement → plan, research or requirement | plan or requirement frontmatter. Open target file = blocked (a requirement: held). A plan names a requirement only while no plan builds what it reads. |
| `research` | plan → research | plan frontmatter. Open target file = blocked. |
| `graduates` | research → `AGENTS.md` / `docs/` file | research frontmatter. Declared target; the `graduated` edge below completes it. |
| `requirement` | plan → requirement | plan frontmatter. Requirement nobody serves = unplanned, `dispatch` flags. |
| `serves` | plan → clause of its requirement | plan frontmatter, clause numbers or `all`; absent = `all`. Clause no open or retired plan serves = PARTLY PLANNED, `dispatch` flags; deleting the requirement with one unserved = `ci` red. |
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

- A `needs:` cycle is red (`ci`, graph lint): plans, requirements and
  questions can wait on each other in a ring, and nothing in it is offered.
- Single-hop only. Every session question (what next, whose is it, what
  overlaps, why this rule) answers in one hop from hook output. Multi-hop
  need = re-run the value test before adding anything: single-hop lookups
  never justify a graph store.
- No stored graph, no auto-extraction, no embeddings. Derived state =
  second copy, rots (derivability rule, `.agents/docs/handover.md`).
- No datastore for the work queue: shell plus markdown travels with a clone,
  a runner or CI, nothing installed. Re-open only for a question files cannot
  answer.
- A harness that lives in the repo has no long-running service of its own:
  only the orchestrator and the heartbeat (`.agents/docs/orchestrated.md`)
  watch, nudge and schedule.
- Fusion manual: graduation ritual, human-reviewed. Wrong merge worse than
  missed merge.
- Provenance = commits. Never hand-write time or source into a file.
- Every edge into main passes a review node, depth by the plan's tier
  (`agent-selection.md`), before the PR. Diamond rule — verify outside
  the context that wrote the code; self-grade alone misses own mistakes.

## Serving

SessionStart hook = retrieval: injects the 1-hop neighborhood (this branch's
workstream, overlap warnings) and prints `git show` commands as edge
traversals. The queue is not printed: a manager gets its item in the prompt,
the orchestrator reads `dispatch`.
