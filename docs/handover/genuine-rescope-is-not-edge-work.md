---
workstream: genuine-rescope-is-not-edge-work
status: in-progress
branch: claude/genuine-rescope-is-not-edge-work
pr: none
plan: genuine-rescope-is-not-edge-work
issue: 492
session: https://claude.ai/code/session_012aeEK469hHzaddGFthH93A
agent: opus
updated: 2026-10-14
next: ci, verify, mutation-check r3-r5 tests, then finish
---

## Goal

A surveyor that finds holds GENUINE (status done, pr none, plan none, never
merged) must not read as edge work: no EDGE, no lead, a dispatch row saying
it holds no slot, and the orchestrator drops its ledger entry instead of
nudging it forever (issue #492).

## Decisions

- Finished rescope ranks 6 in the hook, below abandoned (5): nothing to
  finish and nobody to nudge, so it sorts last and the cap hides it first.
  Set by `finished_rescope` after `rank_of`, never from a status word, so a
  file writing some status word cannot buy rank 6.
- `dispatch_rescope_branches` gains `pr` as field 4, written `none` when
  empty (r3: tab IFS collapses empty fields); the `free-` loop reads it into
  `_`. Same normalisation as the hook's `pr_num`.
- Hook fixture is its own repo (`finishedrescopework`), so the existing
  order and cap assertions stay byte-identical.
- README rank table: `abandoned` row said 4, the code prints 5; fixed while
  adding the rank-6 row (r1).

## Rejected

- None yet.

## Review

- r1: README rank table said `abandoned` ranks 4; `rank_of` prints 5. Fixed with the rank-6 row (fixed)
- r2: fix reverted (hook and joharness.sh at origin/main, new tests kept), `.agents/harness/selftest.sh` 2026-10-14: 7 new assertions FAIL, among them `a finished rescope never leads FINISH BEFORE STARTING` (got `FINISH BEFORE STARTING: origin/rs-fin`), `and carries no EDGE line`, `the finished rescope's row says it holds nothing and is never nudged` (row had no such text), `and no edge work section names it` (got `origin/claude/rescope-keeper ... status done and unmerged.`); 8 failed with the timing case below. With the fix: 2838 passed, 1 failed — `80 KB of prose keywords: 5s (<= 4s)`, a timing case, two suites running at once (no change)
- r3: (verifier) tab-separated rescope rows: an empty `session:` or `next:` collapsed under IFS, `pr: 12` shifted into `next` and dispatch printed a PR-carrying rescope as finished while the hook led with it (fixed: `pr` is field 4, never empty, `none` for no pr)
- r4: (verifier) no dispatch case wrote `pr:`; dropping the pr condition stayed green (fixed: `pr: 12` with no `next:` case, refutes the finished row and `next: 12`)
- r5: (verifier) the hook's `rescope-` prefix condition had no test; replacing it with `:` stayed green (fixed: done `free-o` claim fixture, still EDGE)
- r6: (verifier) a changing surveyor that writes `status: done` before its retire commit reads finished in that window (wontfix: the plan defines finished as exactly the four fields; the retire commit deletes the file, so the window is one push wide — flagged in the PR body)
- r7: (verifier) dispatch accepted `workstream: rescope-` with an empty key as finished, the hook did not (fixed: dispatch also needs a key)

## Blockers

None.

## Where to look

- `.agents/harness/handover-context.sh:rank_of` — rank mapping.
- `joharness.sh:cmd_dispatch` — rescope in-flight loop.
