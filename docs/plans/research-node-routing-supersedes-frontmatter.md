---
plan: research-node-routing-supersedes-frontmatter
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
research: none
scope: joharness.sh, .agents/harness, .agents/docs/research, .agents/docs/consumer-repos.md
---

## Goal

`research-nodes-red-a-clean-consumer` shipped as candidate 1 (PR 184,
merged `3144936`): a file under `docs/research/` is a node when its first
line is `---`. That fixed the consumer red and left the escape hatch its
own plan named — "omit the whole block and leave the queue" — plus one
reader unconverted. This plan replaces the test with candidate 5,
routing, which the retired plan recommended and the human directed
(2026-09-02).

Two defects measured against merged main at `3144936`, both reproduced
from fixtures in this repo's suite:

| | candidate 1 (merged) | routing (this plan) |
| --- | --- | --- |
| Node rebuilt from its heading (PR 140 shape) | `edges sound (0 research)` — no red, not counted | DEAD, "was a node" |
| Plain document drawn by `joharness.sh graph` | `q_POSTGRES_STACK_2026(["question: ..."])` | not drawn |

The second is the sharper one: `lint_nodes` and `queue-context.sh` were
converted, `cmd_graph` reads `gr_docs` and was not, so the command
`.agents/docs/graph.md` calls "the whole graph as a picture" labels a
consumer's prose an open question while the other two readers correctly
ignore it.

## Scope

- Routing replaces frontmatter-presence in `lint_nodes` /
  `lint_graph` and in `queue-context.sh`; both of PR 184's filters go.
- `cmd_graph` gets the same test — the third reader, converted.
- Decay guard: a file whose history carried `research: <stem>` and whose
  tree no longer does is DEAD. Silent where history cannot answer.
- `cleanup` counts documents and DECAYED nodes already on the base ref.
- `.agents/docs/research/README.md` states the rule and its limits;
  `consumer-repos.md` states the migration (nothing to run).

## Out of scope

- Authoring frontmatter for any consumer's documents.
- Changing what a research node means once it IS one.
- Filtering by file type: `lint_nodes` and `gr_docs` already read only
  `.md` minus TEMPLATE/README/VISION, and every one of gx's 65 DEAD
  lines was a `.md` file.

## Acceptance

- A consumer whose `docs/research/` predates the protocol lints GREEN,
  and its documents are neither listed by the queue nor drawn by
  `graph`.
- A node that drops its whole frontmatter block is DEAD, with a test
  that fails without the fix — the case candidate 1 cannot satisfy.
- A node a plan routes to keeps its missing-key reds whatever its
  frontmatter says.
- `mutate` reds the routing test, the reference half, the decay guard
  and the queue's skip.

## Traps

- PR 184's tests stay and must keep passing: its plain-document and
  keeps-block-forgets-one-key cases are correct under routing too.
- Do not re-add a first-line check as a fast path. Two tests for one
  question is the drift this plan exists to remove.
