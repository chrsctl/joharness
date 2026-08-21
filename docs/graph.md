# Harness graph

One graph, two halves, one substrate: git. Task half = how work flows.
Knowledge half = what sessions remember. Files are nodes, frontmatter
fields are edges, commits are provenance. NO stored graph anywhere — every
view derived at read time, so nothing rots. Extend the harness by adding a
node or edge type here, never by adding a state store.

Source: task-graph + KG pipeline rules from
[codejunkie99/graph-engineering](https://github.com/codejunkie99/graph-engineering).
Memory tiers match Zep/Graphiti agent-memory architecture
([arXiv:2501.13956](https://arxiv.org/abs/2501.13956)) — episodic,
semantic, summary — convergent, not copied.

## Nodes

| Type | Lives at | Tier |
| --- | --- | --- |
| Plan | `docs/plans/<plan>.md` on base branch | task |
| Workstream | `docs/handover/<workstream>.md` on work branch | episodic memory |
| Rule, trip-wire | layer's `AGENTS.md` | semantic memory |
| Why-explanation | `docs/*.md` | summary memory |
| Change | commit, branch, PR | execution + provenance |

## Edges

| Edge | Domain → range | Carried by |
| --- | --- | --- |
| `needs` | plan → plan | plan frontmatter. Open target file = blocked. |
| `plan` | workstream → plan | workstream frontmatter. The claim. |
| `agent` | plan or workstream → tier | frontmatter. Model that runs it. |
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
  second copy, rots (derivability rule, `docs/handover/README.md`).
- Fusion manual: graduation ritual, human-reviewed. Wrong merge worse than
  missed merge.
- Provenance = commits. Never hand-write time or source into a file.

## Serving

SessionStart hook = retrieval. Injects the 1-hop neighborhood — this
branch's workstream, queue with `blocked by:` / `claimed on:` edges,
overlap warnings — and prints `git show` commands as edge traversals.
Instructions get skimmed; injected context is already in window.
