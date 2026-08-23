---
plan: agents-docs-move
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: .agents/, docs/, scripts/, joharness.sh, .claude/commands/
---

## Goal

Finish what the `.agents/` move (PR #37) started: in a consumer repo,
`docs/` still mixes harness-owned protocol files (`docs/plans/README.md`,
syncs from canonical, never edit in place) with the child's own live work
(`docs/plans/<plan>.md`) in the same directories, and the sync tools sit
in a generic `scripts/`. After this plan, the ownership rule in a child is
one sentence: `.agents/` + `.claude/` + root instruction files +
`joharness.sh` = harness; `docs/` = 100% the child's own. The sync ships
zero files into a consumer's `docs/` or `scripts/`.

## Scope

- `docs/caveman.md`, `docs/graph.md`, `docs/agent-selection.md`,
  `docs/consumer-repos.md` — move to `.agents/docs/`.
- `docs/handover/README.md` + `TEMPLATE.md`, `docs/plans/README.md` +
  `TEMPLATE.md`, `docs/product/README.md` + `TEMPLATE.md` — move to
  `.agents/docs/handover/` | `plans/` | `product/` (mirrored layout, so
  each protocol doc keeps sitting "next to" the work dir it governs).
- `scripts/sync-to-consumer.sh`, `scripts/bootstrap-consumer.sh` — move
  to `.agents/scripts/`.
- `scripts/sync-to-consumer.sh` itself: drop the ten moved docs from
  `FILES`, add `.agents/docs` and `.agents/scripts` to `DIRS` (fully
  harness-owned trees ship whole — shrinks `FILES` to root-pinned files).
  Extend the legacy-layout warning to the old doc/script paths, same
  blob-vouched warn-until-removed pattern, remedy naming only what exists.
- `scripts/bootstrap-consumer.sh`: whole-clone purge currently keeps
  `README.md`/`TEMPLATE.md` in `docs/plans|product|handover` — after the
  move those dirs hold only live work, purge every `*.md` there. Its
  `SYNC_ENGINE` path and structural checks re-point.
- `.agents/harness/handover-guard.sh`, `handover-context.sh`,
  `queue-context.sh`, `joharness.sh`, `.claude/commands/handover.md`,
  `plan.md`, `who.md`, `.claude/skills/steward/SKILL.md`, root
  `AGENTS.md`, `CLAUDE.md`, `README.md`, `.agents/harness/README.md`
  (ownership table), `.agents/harness/AGENTS.md` — re-point every
  reference (~47 in scripts/wiring, plus docs prose).
- `.agents/harness/selftest.sh` — fixtures mirror the new layout; extend
  the legacy-warning tests to a moved doc and a moved script; keep the
  pre-move fixture history trick from PR #37 so blob-vouching stays
  testable.
- `.agents/docs/consumer-repos.md` — extend the Migration section: second
  wave of `git rm` for the old doc/script paths.

## Out of scope

- Moving `joharness.sh`, `AGENTS.md`, `CLAUDE.md`, `.claude/`,
  `.gitattributes` — tool conventions pin them to root; decided at PR #37
  and again here.
- Deleting anything from consumers by the sync engine. Removals still do
  not travel; the warning pattern is the mechanism, a removal feature is
  a different plan with a different blast radius.
- Pointer/stub files left at the old paths. Two live spellings is the
  coupling the move removes.
- Renaming the work dirs `docs/handover|plans|product/` themselves — they
  stay, they are the child's own work surface the hooks read.

## Acceptance

- `./joharness.sh ci` — `ci: pass`, selftest `0 failed`, count GREATER
  than 247 (new legacy cases add; trust the counted number).
- `./joharness.sh verify` — `7 passed, 0 failed`.
- `git ls-files docs scripts | grep -v -E '^docs/(handover|plans|product)/[^/]+\.md$'`
  prints ONLY joharness's own live plan/handover/product files — no
  README, no TEMPLATE, no scripts (i.e. canonical's `docs/` and `scripts/`
  hold nothing harness-owned; `scripts/` gone entirely).
- Bootstrap a scratch consumer with
  `.agents/scripts/bootstrap-consumer.sh <tmp>`: its `docs/` contains only
  the three empty work dirs, its own `ci` is green, and
  `grep -r joharness <tmp>/docs` finds nothing harness-owned.
- Sync a scratch consumer carrying the OLD doc paths: warning names them,
  blob-vouched; a consumer-own file at an old path stays silent.
- Repo-wide relative-link audit: 0 broken (every moved doc's links, and
  every link INTO the moved docs).

## Where to look

- PR #37's diff — this plan is its second verse, same mechanics: fixture
  history for blob-vouching, legacy-warning gate on the new tree standing,
  discriminating test needles.
- `scripts/sync-to-consumer.sh:FILES`/`DIRS` and `is_legacy_layer` — the
  pattern to extend, not re-invent.
- `.agents/harness/selftest.sh` — "canonical v0, pre-.agents layout"
  fixture commit; add the doc/script files to it.
- `.claude/commands/handover.md`, `plan.md` — the TEMPLATE.md paths agents
  copy from; a stale path here breaks every future session's claim step.

## Traps

- NEVER let `.agents/harness/` name a specific environment while
  re-pointing (Part 2 cross-layer rule).
- Hooks print paths into every session's context — a wrong path there
  misleads every future session, worse than a broken doc link. Re-point
  hook OUTPUT strings, not only the files hooks read.
- `FILES`/`DIRS` and both selftest fixture stub loops move together, or
  the sync exits 3 MISSING (PR #36/#37 both hit this).
- Sync must never ship into `docs/` after this plan — a leftover `FILES`
  entry under `docs/` recreates the mixing this plan exists to end.
- NEVER skip/disable a test to get green; counted numbers only.
