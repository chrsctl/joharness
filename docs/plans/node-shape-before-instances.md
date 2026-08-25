---
plan: node-shape-before-instances
urgency: normal
agent: sonnet
effort: medium
needs: research-node
requirement: none
scope: joharness.sh, .agents/harness/selftest.sh
---

## Goal

Instances of a node type can land before the type exists, and nothing
says so. Measured on `main` 2026-08-25, after PR 64 merged:

    docs/research/*.md                 4 files, on main
    .agents/docs/research/             does not exist
    queue-context.sh                   0 occurrences of "research"
    joharness.sh                       2 occurrences, both the
                                       review-churn prose

So four research files sit in a repo where nothing lists them, nothing
lints them, and no README or TEMPLATE defines their shape. They are
reachable by a human who already knows to look — which is the
"research evaporates" failure `docs/product/research-capability.md` was
written to fix, one notch better only because they are in git.

The graph lint checks EDGES between nodes. It does not check that a
directory of nodes has a type. That is the gap: `lint_graph` would have
caught a dangling `research:` edge and had nothing to say about four
nodes of a type the harness does not implement yet.

## Scope

- `joharness.sh:lint_graph` — a directory holding node files whose type
  the harness does not know is a WARNING, naming the directory and the
  count. Warning, not red: the files are not wrong, they are early, and
  failing `ci` on them would punish the session that did the research.
- `.agents/harness/selftest.sh` — a fixture with node files under an
  unknown type warns; the same fixture once the type is implemented is
  silent; a repo with no such directory is byte-identical to before.

## Out of scope

- **Deciding what a node type IS.** `research-node` defines the research
  type and is still an unimplemented plan; this plan only notices instances of a type nothing implements.
  Hence the `needs:` edge — without that plan there is no second type to
  test against, and the lint would be written against a hypothesis.
- **Failing `ci`.** Early is not wrong. A warning that names the gap is
  what the next session needs.
- **Auto-creating a shape.** Inventing a TEMPLATE for a type nobody
  designed is exactly the invented-methodology the caveman rule forbids.

## Acceptance

- A fixture repo with `docs/<unknown-type>/*.md` and no corresponding
  `.agents/docs/<unknown-type>/`: `ci` prints a warning naming the
  directory and the count, and stays green.
- The same fixture with the type implemented: no warning.
- A repo with neither: session-start and `ci` output byte-identical to a
  pre-change capture.
- `./joharness.sh ci` — `ci: pass`. Prove the new test goes red.

## Where to look

- `joharness.sh:lint_graph` — the edge rules and the warn/red split it
  already keeps.
- `.agents/docs/graph.md` — Nodes and Edges; a new node type is a row in
  each, which is what makes "unknown type" answerable at all.

## Traps

- Derived at read time, never a registry file to maintain
  (`.agents/docs/graph.md`, Rules): the known types are the ones the
  harness already reads, not a list someone keeps in sync.
