---
plan: anchor-symbol-drift
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: joharness.sh, .agents/harness/selftest/ci-graph-lint.sh, .agents/docs/plans/README.md
---

## Goal

google/elephant-goldfish-model ships a drift report: it flags specs that name
code which no longer matches. This harness has the same exposure in a
smaller form. Plans, research and requirements anchor into code as
`path:symbol`, and rule docs point at functions the same way
(`joharness.sh:block_reason_ok`). `lint_anchors` checks only the path, so a
renamed or deleted symbol stays green and a literal reader goes looking for
code that is gone. Warn when the symbol half of a `path:symbol` reference is
no longer in the file it names, and warn on a line-number anchor, which the
plans README already forbids in prose.

## Scope

- `joharness.sh` — `lint_anchors`: for each `## Where to look` entry whose
  path exists and that carries a `:` after the path, take the text after the
  first `:` up to the closing backtick as the symbol. Then:
  - symbol all digits (optionally `N-M`): `lint_warn "<file>: anchor
    '<path>:<symbol>' is a line number — anchor a symbol"`.
  - else `grep -qF -- "<symbol>" "<path>"` fails: `lint_warn "<file>:
    anchor '<path>:<symbol>' — symbol not in file; verify, fix in place"`.
  Path missing keeps today's warning only (no second warning). Entries
  `section_paths` skips (URLs, `=` knobs, bare words) stay skipped. Add a
  new helper beside `anchor_paths` that returns path and symbol; leave
  `section_paths` and `curate_section_paths` unchanged: curate reads them.
- `joharness.sh` — new `lint_doc_refs`, called once per `ci` lint run where
  `lint_anchors`' callers run: every backticked `<path>:<symbol>` in
  `.agents/harness/AGENTS.md`, `AGENTS.md`, `.agents/docs/**/*.md`,
  `.claude/commands/*.md`, `.claude/agents/*.md` whose `<path>` exists from
  the repo root gets the same symbol check and the same warning wording with
  `ref` in place of `anchor`. A path that does not exist from the root is
  skipped silently (prose names files relative to other dirs, e.g.
  `queue-context.sh:stem`). Files absent in a consumer are skipped.
- `.agents/harness/selftest/ci-graph-lint.sh` — next to the `stale anchor
  warns` case: a fixture plan anchoring an existing fixture file with a
  symbol absent from it (expect the `symbol not in file` warning), with a
  symbol present (refute it), and with `:12` (expect `is a line number`).
  One fixture doc under the scratch harness's `.agents/docs/` with a stale
  `path:symbol` ref (expect the `ref` warning).
- `.agents/docs/plans/README.md` — `## Shape`, `Where to look` bullet:
  replace the sentence saying `lint_anchors` checks the path only and a stale
  line number stays green forever with the rule now in force: path and
  symbol both checked, line numbers warned.

## Assumptions

- A1: `lint_anchors` checks paths only — evidence: `joharness.sh:lint_anchors`
  reads `anchor_paths`, which is `section_paths` keeping the text before the
  first `:` — confidence: high.
- A2: No stale symbol exists today, so the change adds no warning to a clean
  `ci` — evidence: a one-off script over `docs/plans`, `docs/research`,
  `.agents/docs`, `.claude/commands`, `.claude/agents` and
  `.agents/harness/AGENTS.md` (every backticked `path.(sh|md|py|json|yml):symbol`,
  `grep -qF` of the symbol in the path), run 2026-10-25 on origin/main
  62f52210: 61 unique refs, 0 stale, 2 with a path not found from the root
  (`queue-context.sh:stem`, template placeholder `path/to/file.py:symbol`).
  Re-take it at build time with the new lint itself — confidence: medium.
- A3: Warnings never red `ci` — evidence: `joharness.sh:lint_warn` sets
  `LINT_WARNED` only — confidence: high.

## Out of scope

- Making a stale symbol red. Warn, as the path check does; a rename lands
  first and its anchors are fixed in place after.
- Rewriting existing anchors or refs: A2 says none are stale. If the new lint
  warns at build time, fix that ref in place in this PR and say so.
- Checking symbols in non-backticked prose, code comments, or line numbers in
  `.agents/docs` prose.
- Any change to `curate` or `section_paths` callers other than `lint_anchors`.

## Acceptance

- `./joharness.sh ci` — `ci: pass`, and its graph lint prints no `symbol not
  in file` and no `is a line number` warning on the tree.
- `./joharness.sh verify` — `0 failed`, and the selftest `graph lint` step
  prints PASS for each new case.
- New cases fail without the change: `git stash` the `joharness.sh` hunk
  only, run `./joharness.sh verify`, see the new expect cases FAIL; restore.
  Record that run in the workstream file `## Review`.
- Plan `ci` calls SHIPS: name in the PR body that a consumer runs
  `./joharness.sh ci`, which carries the lint at its next sync.

## Where to look

- `joharness.sh:lint_anchors` — the path-only check to extend.
- `joharness.sh:section_paths` — how `## Where to look` entries are parsed.
- `joharness.sh:lint_warn` — the warning call.
- `.agents/harness/selftest/ci-graph-lint.sh:stale anchor warns` — the
  existing fixture and cases.
- `.agents/docs/plans/README.md:Symbol, never line number` — the sentence to
  rewrite.

## Traps

- `ci` runs in consumers too: the lint must skip files a consumer lacks and
  never red on a consumer's own docs.
- Shell style in `joharness.sh`: no new forks per line where a builtin read
  does it (see `lint_unknown_types`); `ci` time is watched by
  `docs/research/selftest-runtime.md`.
- Caveman style and `.agents/docs/glossary.md` spellings in the README edit.
- NEVER skip, disable or quarantine a test to get green.
