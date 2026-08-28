---
plan: research-node
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: research-capability
scope: .agents/docs/research, .agents/docs/graph.md, .agents/harness/AGENTS.md, .agents/harness/queue-context.sh, joharness.sh, .agents/harness/selftest.sh, docs/research
---

## Goal

Add the research node and nothing else. The requirement asks for research
to have the standing of a plan; this plan gives it a file shape, a place in
the graph, a line in the queue, and a lint. What a session then does with
it — how it actually researches — is not here and is not needed for the
node to be useful, because the node is what makes findings survive the
session that made them.

The type now has instances before it has a definition. Counted on `main`,
2026-08-27: `ls docs/research/*.md | wc -l` → 4. All four landed via the
research-sweep merges AFTER this plan was written and agree on a shape, so
what they already share is the template's first draft. A definition that
fails `ci` on `main`'s own files is wrong on arrival.
Where the definition deliberately diverges from the four, the same diff
migrates them; where they diverge from each other, Scope names it.
Re-count before starting: this paragraph's count went stale within a day
of being written, once already.

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
  - **Consequence for the queue** — which plan changes, in what way, or
    none. Not in this plan's first draft; all four instances grew it
    unprompted, and it is the hop a plan reader acts on. The shape keeps
    what practice already built.
  - **Verification** — who checked, and from where. See below; this is the
    section the harness's own doctrine already demands and my first draft
    omitted.
  - **Graduates to**, the file the answer lands in.

- Frontmatter, taken from the four instances rather than invented:
  `research:` the stem (as `plan:` in plans), `urgency`, `agent`, `effort`,
  `graduates:` the target file. The tier the queue prints comes from here.

- Verification comes from a different context than the one that produced
  the finding. `.agents/docs/graph.md` Rules already states the diamond
  rule for code — "verify outside the context that wrote the code;
  self-grade alone misses own mistakes" — and research is where it bites
  hardest. Two independent sources agree: John's `grounding-checker` is a
  separate agent because "a model can't reliably audit its own grounding",
  and Anthropic's own research design passes findings to a separate
  `CitationAgent` after the subagent fan-out, reporting that the
  lead-plus-subagent setup "outperformed single-agent Claude Opus 4 by
  90.2% on our internal research eval" — an internal eval on a specific
  model pairing, not an independent benchmark. A subagent is the cheap way
  to get the second context (`.agents/docs/subagents.md`).

- Graduating writes a why-explanation under `docs/`, not only a rule line
  in `AGENTS.md`. The rule is what the next session obeys; the
  why-explanation is what stops the session after that from re-opening a
  settled question. ADR practice keeps superseded records forever for this
  reason — this harness deletes the node instead and keeps the reasoning in
  the graduated file, which works only if the graduation actually carries
  the reasoning.
- `.agents/docs/graph.md` — one row in Nodes (`Research` |
  `docs/research/<question>.md` on base branch | task), two rows in Edges:
  `research` | plan → research | plan frontmatter; open target file =
  blocked, the same shape `needs` already uses. And `graduates` | research
  → `AGENTS.md` / `docs/` file | research frontmatter — the declared
  target the existing `graduated` edge later completes; the instances
  already carry it. Nothing else in that file changes.
- `.agents/harness/queue-context.sh` — research files listed beside plans,
  and a plan carrying `research:` shown blocked while its target exists,
  reusing the `needs` machinery rather than a second implementation.
- `joharness.sh`, `lint_graph` — research frontmatter linted like a plan's:
  the file resolves, `research:` edges resolve, vocabulary holds,
  `graduates:` names a file that exists. The four instances on `main` are
  the first fixture: they lint clean as merged, or this diff migrates them
  in the commit that adds the lint. Migration is shape only — frontmatter
  and sections, never findings. One known divergence:
  `glossary-enforcement` has no `## Method`; its queries were not recorded,
  so a migrated Method says that rather than minting them.
- `.agents/harness/AGENTS.md` — the review-churn rule's "research step"
  points at the shape. Loop step 2's queue order gains research: listed
  beside plans under the same ordering, oldest actionable first, urgent
  first — no special rank, because a plan blocked on an open question
  already drops out of the entrypoint, and that is rank enough. Caveman:
  this file loads every session.
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
- Back-filling the mechanism comparison that lives outside git, or any
  other past research not already in `docs/research/`. The four files
  there are not back-fill — they are in scope as fixtures and for
  shape-only migration, their findings untouched. Retrofitting anything
  further proves nothing about whether the shape works.
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
  queue beside plans, with its tier — and so do the four instances already
  on `main`, which need no synthetic fixture. Paste the hook output.
- `./joharness.sh ci` is green over the four instance files as this diff
  leaves them — on this repo, not only in a fixture. Paste the run.
- The template refuses to look complete without its Verification section
  filled: a finding nobody checked from a second context is not settled.
  The README states this as a rule, not a suggestion.
- A plan with `research: <open-question>` is listed blocked, is not
  suggested as an entrypoint, and becomes free when that file is deleted.
  Both states pasted.
- `./joharness.sh ci` fails on a `research:` edge naming a file that does
  not exist, and passes when it resolves. Paste both runs.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — all checks pass, 0 failed. Required: this diff touches
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
- `docs/research/*.md` — the four instances that landed ahead of the type.
  What they agree on is the template's first draft; where they differ (one
  lacks `## Method`) is the migration list.

## Traps

- No stored graph, no index, no status field
  (`.agents/docs/graph.md`, Rules). File existence is the state.
- Single-hop only. A session's question — what is open, what is blocked on
  it — answers from hook output without traversal.
- Caveman in `AGENTS.md`: one node type and one edge, stated once. The
  reasoning goes in `.agents/docs/research/README.md`.
- A node type nobody uses must cost nothing at session start. Assert the
  byte-identical case, do not assume it.
- The provenance rule and the Verification section pull against each
  other: `graph.md` Rules says never hand-write time into a file, the
  requirement demands who checked and from where, and all four instances
  hand-write "Checked 2026-08-25". The requirement asks for who and
  where, not when — commits carry when. Decide once, in the README, not
  file-by-file.
- Every plan whose `scope:` names `joharness.sh` or
  `.agents/harness/selftest.sh` conflicts with this one; the session-start
  hook names them live, and a list written here would rot. Not a wave with
  any of them.
