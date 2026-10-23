---
plan: broken-windows-gate
urgency: normal
agent: sonnet
effort: xhigh
needs: none
requirement: none
issue: none
scope: shared:joharness.sh, .agents/harness/selftest/broken-windows.sh, shared:.agents/harness/selftest.sh, shared:.agents/docs/handover/README.md
---

## Goal

"NEVER skip, disable or quarantine a test" is prose, and nothing counts
it. GSD Core's broken-windows capability keeps a ledger of stubs, TODOs
and skipped tests, and ship is blocked until it is empty or each entry is
waived with a reason. Make ours a check. `ci` reds a branch whose diff
ADDS a skip marker or a TODO/FIXME to a non-markdown file, unless the
workstream file's `## Review` waives that exact path with a reason.

## Scope

- `joharness.sh`: a lint in the ci plan stage. Over `git diff
  <merge-base>..HEAD`, it looks at added lines only, in files not ending
  `.md`, for:
  - `TODO`, `FIXME`, `XXX` as whole words;
  - `@skip`, `pytest.mark.skip`, `unittest.skip`, `it.skip(`,
    `describe.skip(`, `test.skip(`, `xit(`, `xdescribe(`, `.only(`,
    `t.Skip(`, `#[ignore]`.

  Each hit prints `path:line: marker`. A `## Review` bullet with
  `window <path>` and `(wontfix: <reason>)` waives every hit in that
  path. Unwaived hits red the stage.
- `.agents/harness/selftest/broken-windows.sh` (new topic), registered.
- `.agents/docs/handover/README.md` "Reviewing" or its nearest section: the
  waiver form, one bullet.

## Out of scope

- Markers already on the base branch. Only added lines count.
- Language-aware parsing. A string literal containing a marker is a hit,
  and the waiver is the answer.
- A ledger file. Derived from the diff at read time
  (`.agents/docs/graph.md`).

## Acceptance

- `./joharness.sh ci` — `ci: pass`, and the selftest prints the cases:
  - an added `it.skip(` in a `.js` file is red, naming path and line;
  - the same line in a `.md` file is not;
  - a marker already present on the base is not;
  - a waiver bullet for the path turns red to pass;
  - a waiver for a different path does not.
- The red case FAILS when the lint is stubbed out.

## Where to look

- `joharness.sh:lint_review_bullets` — how `## Review` bullets are read; the waiver reuses it.
- `joharness.sh:lint_ws_in_diff` — the diff-scoped lint pattern and merge-base handling.
- `joharness.sh:fin_own_ws` — finding this branch's own workstream file.

## Traps

- SHIPS: every consumer's ci gets this. A false positive is a fleet-wide
  red, so stay on added lines and non-md files.
- The selftest itself must not add the literal markers, or this branch
  reds itself. Build them from parts, e.g. `"it"".skip("`.
- The harness's own existing text (`joharness.sh`, selftests) contains
  words like XXX in comments. Prove the lint ignores base content: run
  ci on this branch.
