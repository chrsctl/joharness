---
workstream: research-nodes-red-a-clean-consumer
status: in-progress
branch: claude/document-routing-metadata-ib6nfc
pr: none
plan: research-node-routing-supersedes-frontmatter
issue: none
session: https://claude.ai/code/session_01Tf1txC8UWbDudKu12aPUfA
agent: opus
updated: 2026-09-02
next: Re-run mutate on the reconciled tree, then open the pull request
---

## Reconcile with main (2026-09-02)

Main merged a COMPETING implementation of the same plan mid-build — PR
184 (`3144936`), candidate 1: a node is a file whose first line is
`---`. It also retired the plan file. Merged main in (branch flow,
"Conflict at finish" — merge, never rebase); one conflict, the retired
plan file, resolved by accepting the deletion. Human directed routing to
supersede (2026-09-02), so PR 184's two filters are removed:
`lint_nodes`' `frontmatter` arg and `queue-context.sh:frontmatter_only`.
Its TESTS stay and pass unchanged under routing — its plain-document and
keeps-block-forgets-one-key cases are correct under both rules.

Two defects in the merged implementation, both reproduced against
`3144936` before removing it:

- a node rebuilt from its `## Question` heading onward (the PR 140
  shape) printed `edges sound (0 plans, 0 research, ...)`: no red, not
  listed, not counted. Its own code comment claimed such a node is "a
  legibly-not-a-node document"; legible to a human, invisible to every
  reader that schedules.
- `cmd_graph` was never converted — it reads `gr_docs`, not
  `lint_nodes` — so `joharness.sh graph` drew a plain document as
  `q_POSTGRES_STACK_2026(["question: POSTGRES-STACK-2026"])` while lint
  and queue correctly ignored it. Two readers converted of three.

New plan file `docs/plans/research-node-routing-supersedes-frontmatter.md`,
because the old one is retired and nothing builds unplanned.

## Goal

A sync turns a green consumer red: 65 DEAD lines over 13 documents that
lived in `docs/research/` before the research-node protocol existed
(plan's own table, gx at `847f64e`). The human directed candidate 5 —
nodehood decided by routing through documents — plus cleanup mechanisms
that keep the graph sound long term, not just at this edge.

## Decisions

- Candidate 5 implemented, per the human's steer (2026-09-01) and the
  plan's updated recommendation. A `docs/research/` file is a NODE when
  it self-names (`research: <stem>`) or an open plan's `research:` edge
  names its stem; anything else is a document, skipped by lint, queue
  and graph alike. One rule, three readers, or the queue schedules what
  the lint just excused.
- `research:` present but not equal to the stem is DEAD, not a document:
  a key that exists is intent to be a node, and a typo'd self-name that
  silently left the queue would be a new escape hatch.
- Escape-by-omission closed by a decay guard, not a marker: a non-node
  file whose history once carried `research: <stem>` (git pickaxe over
  the file's own path) was a node and is DEAD until restored or deleted.
  Shallow history that finds no hit stays SILENT — same doctrine as
  lint_unknown_types: a check that cannot distinguish says nothing.
  Red-locally/green-on-depth-1 is the acceptable direction; the reverse
  is not.
- Canonical repo (JOHARNESS_CANONICAL=1): a plain document under
  docs/research/ additionally WARNS — consumers keep domain documents
  there legitimately, canonical does not, and routing would otherwise
  make a stray file in canonical invisible forever.
- `cleanup` counts documents and decayed nodes already on the base ref
  (lint only guards edges; what main accreted before this feature never
  crosses an edge again until touched). Count only — never staged by
  --apply: a consumer's documents are not the harness's to delete.
- Verified 2026-09-02, this branch: suite 1199 passed / 1 failed
  (`bash .agents/harness/selftest.sh`; the 1 is `perf graph` over budget
  on UNMODIFIED main in this container too — environmental, green on
  GitHub). Both ways: fix stashed, tests kept, 17 new cases red. Mutate
  (suite wrapper controlling that one environmental red): joharness.sh
  1717→`false` reds 10, 1717→`true` reds 2 (the escape-hatch pair),
  content-guard deleted reds 1 (the prose case), 1720 pickaxe blinded
  reds 3, queue-context.sh 259→`false` reds 3. Perf counted same day:
  queue-context 505→509 (+4 constant), graph 432→432
  (`./joharness.sh perf <entrypoint>`, this container).

## Rejected

- Explicit per-file opt-out marker (candidate 2): no hole, but costs
  every consumer a migration edit per legacy file; the human's steer and
  the zero-migration property decided against it. Recorded in the plan.
- Shallow-history aggregate warning for unresolvable decay: would print
  on every depth-1 CI run of every consumer with legacy documents,
  forever — the false-warning channel pollution lint_anchors documents.

## Review

- r1: cmd_graph read `research:` values raw where lint_stem and the
  hook's stem() strip path and .md — a plan writing
  `research: docs/research/x.md` counted for routing in lint and queue
  but not in graph, so the one picture skipped a node the queue lists,
  and the pre-existing blocked-edge/existence checks in the same loop
  missed path form too. Stemmed once at the top of the rneed loop, all
  readers now tolerate path, name or stem alike; graph selftest pins the
  path-form case. (fixed)
- r2: residual decay false positive — a document whose OLD revision
  mentioned `research: <its-stem>` in prose and whose current content
  does not reds as decayed; the content guard can only see the tree. No
  such file can be distinguished from a real dropped block by machine,
  the red names both remedies, and candidate 2 was rejected knowing
  routing carries residuals. (wontfix — accepted; now stated in
  .agents/docs/research/README.md, which r6 found it was not)
- r3: (verifier) origin/main merged PR 184, a competing implementation
  of this same plan, and retired the plan file; the auto-merge was clean
  everywhere but the plan file and would have landed main's
  frontmatter filter AHEAD of routing, silently disabling the decay
  guard. Loop step 4's periodic ahead/behind re-check would have caught
  it hours earlier; this session never ran one. (fixed — reconciled per
  the section above; the re-check is the lesson, recorded here because
  it cost the most)
- r4: (verifier) whitespace-separated `research: alpha beta` split four
  ways across readers — lint and queue treated it as two stems,
  cmd_graph and cleanup flattened it to `alphabeta`, so the graph drew
  no question and painted the plan unblocked. The README's "one rule,
  three readers" was false for that input. (fixed — one `gr_edge_stems`
  helper, comma OR whitespace, path/name/stem, used by all four)
- r5: (verifier) two decay escapes: a key written `research:decayed`
  with no space defeated the pickaxe (it searches the spaced spelling),
  and the content guard's substring grep let prose reading
  `see research: qr-followup` mask the real decay of `qr.md`.
  (fixed — pickaxe and guard both anchored to the frontmatter line
  shape, optional space, end-anchored stem)
- r6: (verifier) r2's disposition cited README limits that did not
  mention the prose-history false positive at all. (fixed — stated,
  with both remedies and why neither is right for a consumer)
- r7: (verifier) `cleanup` did not filter `none` from its reference
  set, so a document literally named `docs/research/none.md` read as
  referenced. (fixed — shares the same helper, which drops `none`)
- r8: (verifier) `cmd_graph` normalised the plan side only, so a node
  whose OWN key is path form drew `q_docs_research_foo_md` while a
  plan's edge pointed at `q_foo` — two nodes for one question.
  (fixed — the node's own key goes through the same stem)
- r9: (verifier) `gr_docs` does not exclude `VISION.md` while
  `lint_nodes` and `queue_files` do, so cleanup would count a
  consumer's `docs/research/VISION.md` as a document lint never sees.
  Pre-existing filter split, newly visible. (fixed here for the new
  section only — cleanup's research walk excludes VISION; widening
  `gr_docs` itself touches every caller and is not this plan's scope)
- r10: (verifier) a document committed at a path that once held a
  deleted node reds DECAYED forever, and neither remedy fits.
  (wontfix — same class as r2, same residual; stated in the README)

## Blockers

None.

## Where to look

- `joharness.sh:lint_graph` — plans pass collects referenced stems; the
  research pass decides node vs document vs decayed.
- `joharness.sh:cmd_graph` — plans pass moved ahead of the research pass
  so the same referenced set exists there.
- `.agents/harness/queue-context.sh` — rrows loop applies the node test;
  skipped documents must not count as "could not be read".
- `.agents/harness/selftest/ci-graph-lint.sh` — the fixture cases,
  including the gx-shaped legacy-document one.
