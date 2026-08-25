---
plan: research-node
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: research-capability
scope: .agents/docs/research, .agents/docs/graph.md, .agents/harness/AGENTS.md, .agents/harness/queue-context.sh, joharness.sh, .agents/harness/selftest.sh
---

## Goal

Add the research node and nothing else. The requirement asks for research
to have the standing of a plan; this plan gives it a file shape, a place in
the graph, a line in the queue, and a lint. What a session then does with
it — how it actually researches — is not here and is not needed for the
node to be useful, because the node is what makes findings survive the
session that made them.

Everything it needs already exists in the model. Files are nodes,
frontmatter fields are edges, delete-on-done is the state, and `graduated`
is already defined as a workstream reaching `AGENTS.md` or `docs/`. Research
reuses all four. If this plan finds itself adding a store, an index or a
status field, it has gone wrong — `.agents/docs/graph.md` Rules says why.

## Scope

- `.agents/docs/research/README.md` and `TEMPLATE.md` — new, matching the
  shape of `.agents/docs/plans/`. The template's sections: the Question, in
  one sentence, answerable; What would settle it, naming the evidence that
  would close it either way; Method, the commands to run; Findings, each
  with its command and that command's output; Graduates to, the file the
  answer lands in. A question with no settling evidence is not a research
  question and the README says so in those words.
- `.agents/docs/graph.md` — one row in Nodes (`Research` |
  `docs/research/<question>.md` on base branch | task), one row in Edges
  (`research` | plan → research | plan frontmatter; open target file =
  blocked, the same shape `needs` already uses). Nothing else in that file
  changes.
- `.agents/harness/queue-context.sh` — research files listed beside plans,
  and a plan carrying `research:` shown blocked while its target exists,
  reusing the `needs` machinery rather than a second implementation.
- `joharness.sh`, `lint_graph` — research frontmatter linted like a plan's:
  the file resolves, `research:` edges resolve, vocabulary holds.
- `.agents/harness/AGENTS.md` — the review-churn rule's "research step"
  points at the shape. Loop step 2's queue order gains research where it
  belongs. Caveman: this file loads every session.
- `.agents/harness/selftest.sh` — the queue shows a research file; a plan
  blocked on an open question is listed blocked and never suggested; the
  block clears when the file is deleted; the lint catches a `research:`
  edge naming a file that does not exist.

## Out of scope

- How to research. No method, no source list, no tooling for doing the
  work. The node is the deliverable; a session already has Bash, the web
  and subagents (`.agents/docs/subagents.md`). A methodology written before
  a single research file exists would be invented, not observed.
- Back-filling tonight's mechanism comparison, or any other past research,
  into the new shape. Seeding a node type with retrofitted content proves
  nothing about whether the shape works.
- A research index, dashboard or `./joharness.sh research` sweep. The queue
  hook already lists nodes; a second view is the stored-copy failure
  `.agents/docs/graph.md` forbids.
- Requirements. Sessions file questions, never requirements
  (`.agents/docs/product/README.md`).
- Letting research carry implementation. A research file that edits code is
  a plan wearing the wrong frontmatter; the README names this as the
  failure to watch for.

## Acceptance

- A research file created from `TEMPLATE.md` appears in the session-start
  queue beside plans, with its tier. Paste the hook output.
- A plan with `research: <open-question>` is listed blocked, is not
  suggested as an entrypoint, and becomes free when that file is deleted.
  Both states pasted.
- `./joharness.sh ci` fails on a `research:` edge naming a file that does
  not exist, and passes when it resolves. Paste both runs.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 7 passed, 0 failed. Required: this diff touches
  non-`*.md` files under `joharness.sh` and `.agents/harness/`.
- `./.agents/harness/selftest.sh` — passes, count higher by the tests added.
- Supervised session-start output for a repo with no research files is
  byte-identical to before. Diff against a pre-change capture; a node type
  nobody uses must cost nothing.

## Where to look

- `.agents/docs/plans/README.md` and `TEMPLATE.md` — the shape to mirror,
  including how frontmatter fields are documented for a literal reader.
- `.agents/docs/graph.md`, Nodes and Edges — the two tables gaining a row,
  and the Rules paragraph that forbids the easy wrong answer.
- `joharness.sh:lint_graph` — how plan frontmatter and `needs` edges are
  linted today; research reuses it rather than adding a parallel path.
- `.agents/harness/queue-context.sh` — where plans are read and where
  `blocked by:` is printed.
- `.agents/harness/AGENTS.md`, the review-churn clause — the one existing
  reference to research, and the dangling pointer this plan closes.

## Traps

- No stored graph, no index, no status field
  (`.agents/docs/graph.md`, Rules). File existence is the state.
- Single-hop only. A session's question — what is open, what is blocked on
  it — answers from hook output without traversal.
- Caveman in `AGENTS.md`: one node type and one edge, stated once. The
  reasoning goes in `.agents/docs/research/README.md`.
- A node type nobody uses must cost nothing at session start. Assert the
  byte-identical case, do not assume it.
- `ci-scope-selftest`, `queue-shared-scope`, `harness-glossary`,
  `process-scorecard` and `unsupervised-sources` all touch `joharness.sh`
  or `.agents/harness/selftest.sh`. Not a wave with any of them.
