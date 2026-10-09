---
workstream: scout-command
status: in-progress
branch: claude/scout-command
pr: none
plan: scout-command
issue: none
session: https://claude.ai/code/session_01JXryjCKHhwkN7Xrv1qXz55
agent: opus
updated: 2026-10-09
next: Second verifier pass on r1-r11; then retire with the requirement and PR
---

## Goal

`docs/product/scout-role.md`, bullets three to six: the scout role itself —
the command file a spawned scout follows, the orchestrator's spawn rule,
`/start`'s routing, the Roles row and the bound. Last plan of the
requirement: its pull request deletes `docs/product/scout-role.md`.
Supervised session at the human's ask.

## Decisions

- `start.md` routes nothing to `/scout`: one paragraph says a drain `scout :`
  block is never the session's item (scout-cycle R-f), per the plan as
  updated by scout-cycle r56.
- NOTHING TO PROPOSE still pushes the claim's retire: the retire is what
  dates the next window (scout-cycle reads deletions on unmerged branches).
- One line beyond the plan's scope: `.agents/docs/research/README.md` said
  "Sessions file questions, never requirements" with no exception — a
  literal reader would read the scout as a violation. It now names the
  exception and points at the Bounds paragraph.
- r1's fix needed one change in merged code: `scout_walk` keyed its rows on
  the path, so twin scouts (same day, same path, two branches) read as one
  row and the twin check could never see two. Now one row per branch and
  file; a selftest case pins it. `joharness.sh` touched beyond the plan's
  "no change" — that row key and the r8/r9 text lines only.
- The scout's own rules restated from what scout-cycle reads: the file
  path is the identity; `done` holds until the retire; `abandoned` is the
  janitor's word; automerge from the base branch's conf, never set by the
  scout.

## Rejected

## Review

- r1: (verifier) the `scouted=` ledger guard dies with the run: `scout DUE` prints only under the exit verdict, the run ends at the spawn, and the heartbeat's next orchestrator starts with an empty ledger — it spawns a second scout before the first pushes. (fixed — the cross-run guard moves into the role: after its claim is pushed a scout re-reads `./joharness.sh scout`; two or more in flight, the one whose branch sorts first keeps going, every other retires and exits. orchestrate.md says the ledger guards one run only)
- r2: (verifier) §0.3 let a human-started scout through on the word DRAINED, while drain itself suppresses the scout for edge work, a due curate or janitor. (fixed — the precondition is drain's own `scout     : DUE` line, or dispatch's spawn line)
- r3: (verifier) no review step in the role, and §5 `on` named three of step 7's six conditions. (fixed — §4 Review: verifier at your tier, findings in `## Review` before the retire; §5 `on` = step 7 whole, review recorded and no unresolved human thread included)
- r4: (verifier) the Never list forbade only `protocol-paths` — three paths here — so built work could ride the proposal's pull request and merge under automerge. (fixed — the diff is the proposal file and the scout's own workstream file, nothing else; no code)
- r5: (verifier) a resumed scout read its own file as IN FLIGHT and stopped. (fixed — §0 names the resume case: your own branch's row is yours)
- r6: (verifier) the stamp's leading digit was never stated, so `scout-today.md` would be invisible to the cycle. (fixed — `scout-YYYY-MM-DD`, UTC, a digit after the dash, as janitor.md says)
- r7: (verifier) `.agents/docs/product/README.md` "Human writes." had no scout exception. (fixed — one line pointing at orchestrated.md, Bounds)
- r8: (verifier) four references to `docs/product/scout-role.md` dangle once this PR retires it, one printed by every drain scout block. (fixed — each now points at orchestrated.md, Bounds, or at the retired file through `git log`; `joharness.sh` touched for text only, beyond the plan's "no change" — recorded)
- r9: (verifier) "`./joharness.sh review` — review churn on the queue": it reports this branch only. (fixed — dropped from scout.md and from `cmd_scout`'s list; churn is what `upstream` and `feedback` already carry)
- r10: (verifier) NOTHING TO PROPOSE pointed at the step that opens a pull request. (fixed — retire commit, push, no pull request)
- r11: (verifier) start.md said only an orchestrator spawns a scout, then that a human runs one. (fixed — an orchestrator spawns one, a human may start one; a session never takes one itself)

## Blockers

None.
