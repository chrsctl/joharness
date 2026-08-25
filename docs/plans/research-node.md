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
  shape of `.agents/docs/plans/`. The template's sections, each earning its
  place from a measured practice rather than taste:

  - **Question**, one sentence, answerable. A question with no settling
    evidence is not a research question and the README says so in those
    words.
  - **Echo** — the question restated in the researcher's own words before
    any method runs. John's `self-correction-echo` generalises the pattern:
    a model that misreads its input then reasons competently on the wrong
    input produces an answer correct in shape and wrong in substance, and
    the echo is the cheapest place to catch it.
  - **Sweep** — `comprehensive` or `goal-directed`, named explicitly.
    John's `sweep-strategy` makes this the choice that decides what
    "complete" means: everything there is, or everything needed for what.
    Unnamed, completeness is unfalsifiable and the question never closes.
  - **What would settle it** — the evidence that closes the question either
    way, written before the method runs so the answer cannot be fitted to
    what was found.
  - **Method**, the commands to run.
  - **Findings**, each with its command and that command's output.
  - **Verification** — who checked, and from where. See below; this is the
    section the harness's own doctrine already demands and my first draft
    omitted.
  - **Graduates to**, the file the answer lands in.

- Verification comes from a different context than the one that produced
  the finding. `.agents/docs/graph.md` Rules already states the diamond
  rule for code — "verify outside the context that wrote the code;
  self-grade alone misses own mistakes" — and research is where it bites
  hardest. Two independent sources agree: John's `grounding-checker` is a
  separate agent because "a model can't reliably audit its own grounding",
  and Anthropic's own research design runs a **separate citation pass**
  after the subagent fan-out. Measured citation accuracy across commercial
  deep-research systems spans 78% to 94%, which is the size of the error
  this section exists to catch. A subagent is the cheap way to get the
  second context (`.agents/docs/subagents.md`).

- Graduating writes a why-explanation under `docs/`, not only a rule line
  in `AGENTS.md`. The rule is what the next session obeys; the
  why-explanation is what stops the session after that from re-opening a
  settled question. ADR practice keeps superseded records forever for this
  reason — this harness deletes the node instead and keeps the reasoning in
  the graduated file, which works only if the graduation actually carries
  the reasoning.
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

- A research methodology beyond the template's sections. Those sections
  come from measured practice — John's echo and sweep, the harness's own
  diamond rule, the separate-citation-pass finding — and each one is a
  field a reader fills, not a procedure to follow. No source list, no
  confidence scoring, no loop shape. A session already has Bash, the web
  and subagents; anything further, written before a single research file
  exists, would be invented rather than observed.
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
- The template refuses to look complete without its Verification section
  filled: a finding nobody checked from a second context is not settled.
  The README states this as a rule, not a suggestion.
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
