---
workstream: research-nodes-red-a-clean-consumer
status: in-progress
branch: claude/document-routing-metadata-ib6nfc
pr: none
plan: research-nodes-red-a-clean-consumer
issue: none
session: https://claude.ai/code/session_01Tf1txC8UWbDudKu12aPUfA
agent: opus
updated: 2026-09-02
next: Spawn the verifier on the full diff, record findings under Review, then set status review
---

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

(One bullet per finding, `- r<N>:` form, before its fix and committed
with it.)

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
