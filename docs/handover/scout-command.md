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
next: Retire with the requirement, open the PR, merge on green
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
  file (r25 keeps that true for two branches on one commit); a selftest case pins it. `joharness.sh` touched beyond the plan's
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
- r12: (verifier, pass 2) r1 still open: the twin check re-read refs it never fetched, so two scouts that both pushed before either re-read each saw only itself. (fixed — the twin check fetches every branch first: `git fetch --prune origin '+refs/heads/*:refs/remotes/origin/*'`)
- r13: (verifier, pass 2) r1 still open: "the branch that sorts first keeps going" let a later scout win after the earlier had already gone on — a coin flip per pair. (fixed — the rule every scout can apply alone: ANY scout row besides your own = retire. One that goes on saw only itself after its push, so any later one's re-read sees it; both may retire, none goes on — closed. A scout that finishes before a twin re-reads: closed by r20)
- r14: (verifier, pass 2) §4 says spawn the verifier, Never says spawn anything. (fixed — Never forbids spawning a SESSION; the review subagent is the one thing it starts)
- r15: (verifier, pass 2) the per-branch row key printed a scout file that reached main once per unmerged branch — 4 rows for 3 plan branches. (fixed — a non-base row whose file is byte-identical to the base's copy is skipped; the base's own row still counts, so nothing hides; the r42 shape stays in flight; selftest case)
- r16: (verifier, pass 2) the TWINS case pins the row key, not the twin check — both pushes come from one clone. (no change — the fetch and the any-other-row rule are the role's instructions, which no selftest executes; recorded so nobody reads the case as more)
- r17: (verifier, pass 3) the identical-to-base skip read ANY failed `rev-parse` as identical — it stops at its first unresolvable argument and prints one line — so a path git grep quotes (non-ASCII) or a ref pruned mid-read hid a live scout: fail open. (fixed — skip only when BOTH sides resolve with `--verify` and match; grep runs with `core.quotePath=false`; the non-ASCII case fails against 903c638's code — it pins the two fixes TOGETHER, each alone keeps the row; the pruned-ref race `--verify` also covers is reasoned, not reproduced here)
- r18: (verifier, pass 3) the walk's header still said nothing is skipped as inherited. (fixed)
- r19: (verifier, pass 3) a failed fetch left stale refs, and two twins both failing would both go on. (fixed — fetch exits non-zero = retire)
- r20: (verifier, pass 3) step 3 left zero rows, `UNREADABLE` or `off` unhandled. (fixed — anything but exactly your own row, with the clock still due, = retire. The clock check also closes r13's accepted gap: a twin that finished first has dated the window, so the re-read's clock reads not due)
- r21: (verifier, pass 3) both twins deferring burns a window, and the not-due line then speaks of a proposal that never existed. (no change — the closed failure's stated price; the window is the human's knob)
- r22: (verifier, pass 4) the walk read refs by NAME three times; a concurrent fetch moving `origin/main` between the grep and the blob compare made a branch's copy read as "inherited" from a base row the listing never saw — a live scout hidden, reproduced with a git wrapper. (fixed — one snapshot by commit id: the base's id first, the unmerged refs measured against that id, every later read names commits; an unreadable base is the `unreadable` in-flight row. a selftest case interleaves the race with a git wrapper — r26)
- r23: (verifier, pass 4) two same-day scouts on ONE branch name share one file and both read the row as theirs. (fixed — §1: a rejected claim push = stop and report, never pull-and-push; the branch must be the scout's own. How sessions name branches is outside this checkout — UNVERIFIED that two can collide)
- r24: (verifier, pass 5) the same race one level up: `scout_due`'s clock reads refs by name before the walk's snapshot, so a retire landing between them reads due once. (wontfix — needs a concurrent fetch in the same clone mid-dispatch; a scout spawned on it fetches and re-reads in its twin check, sees the not-due clock, and retires — closed; written in the code)
- r25: (verifier, pass 5) two refs on one commit collapsed to one row named for whichever sorted first — a stacked branch borrowed the scout's name. (fixed — every name kept, one row per branch again; selftest case)
- r26: (verifier, pass 5) no test pinned r22. (fixed — a git wrapper moves `origin/main` onto a commit carrying the identical file after the N-th call, N = 1..20; the scout must read in flight at every N; fails on 903c638's walk)
- r27: (verifier, pass 5) "the old 16 cases" was a number with no command. (fixed — dropped)
- r28: (verifier, pass 5) "or any error means another session" misreports a network failure. (fixed — any failure stops; non-fast-forward is the one that means another session)

## Blockers

None.
