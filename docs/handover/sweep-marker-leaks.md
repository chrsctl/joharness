---
workstream: sweep-marker-leaks
status: review
branch: claude/sweep-marker-root-scope
pr: none
plan: sweep-marker-root-scope
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Open the pull request and merge it — main is red under the sweep until it lands
---

## Goal

PR 174's recursion guard leaks into the selftest's fixtures and reds 52
cases on a `main` whose own `ci` is green. Mine, one merge old, found by
the sweep the guard was built to protect.

## Decisions

- **Scope the marker to `$ROOT`, do not clear it in the runner.** PR 164
  settled that shape for this class ("a test that edits the machine it runs
  on is worse than the flake it removes"), and clearing would leave the
  human case — an exported variable silencing `sources` everywhere —
  broken.
- **Guard on an exact root match, not on non-emptiness.** Non-emptiness
  would still fire for any foreign value; a match is the actual question
  the guard is asking.
- **The new case asserts the detectors RAN, not the verdict.** Earlier
  cases in the topic have already moved the fixture off dry, so a `sweep
  dry` assertion there would pin their state rather than this guard. Cost
  one red round to notice.

## Rejected

- **Asserting `sweep dry` on the foreign-root case.** Failed: `NOT dry` by
  then, because the topic's earlier cases add findings and markers to the
  shared fixture. The fixture is cumulative; a case near the end cannot
  assume the state a case near the start had.

## Review

- r1: `mutate` on the guard line reds 5, but the two setters still write
  `"$ROOT"` — so the mutation reproduces the guard half of the defect and
  not the original 52-case failure, which needed the bare `1` at the
  setter too. The end-to-end proof is therefore `sources` itself, run
  before and after: `52 failing, ci exit 1` -> `0 failing, ci exit 0`.
  (fixed — both numbers counted, on this branch, 2026-08-31.)
- r2: the guard now reads `$ROOT`, a variable set at line 89 from
  `CLAUDE_PROJECT_DIR`. If a caller exported a DIFFERENT
  `CLAUDE_PROJECT_DIR` between the setter and the guard, the roots would
  not match and the recursion would return. Checked: `perf_count` and
  `src_run_checks` both invoke `"${ROOT}/joharness.sh"` without changing
  that variable, so parent and child derive the same root. (fixed —
  nothing to change; the risk is real and the call sites refute it.)
- r3: verifier not spawned. Twenty-ninth consecutive edge — the session
  instruction forbids calling the Agent tool unasked and Loop step 5
  requires a reader that did not write the diff. (wontfix — issue #168.)

## Blockers

None.

## Where to look

- `joharness.sh:3740` — the guard.
- `joharness.sh:961`, `joharness.sh:3637` — the two setters.
- `.agents/harness/selftest/sources.sh` — the fixture root is `$swwork`,
  which is what makes root-scoping close the leak.
