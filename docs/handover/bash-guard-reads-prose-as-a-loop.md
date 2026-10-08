---
workstream: bash-guard-reads-prose-as-a-loop
status: blocked
branch: claude/bash-guard-reads-prose-as-a-loop
pr: none
plan: bash-guard-reads-prose-as-a-loop
issue: none
session: https://claude.ai/code/session_01X7MYq6kL1CgciaSW4PW2fv
agent: opus
updated: 2026-10-08
next: Human — the design is settled and measured below; apply it in a session that may EXECUTE the guard. The plan's own prescription is refuted, so fix the plan before building from it.
---

## Goal

Settle `docs/research/bash-guard-reads-prose-as-a-loop.md` and graduate the
answer into `.agents/harness/pretool-bash-guard.sh`. Orchestrated manager,
one item.

The item was first recorded blocked on the protocol-path bound. The human
then waived that bound explicitly for this session, so the build was
attempted. It stopped on a DIFFERENT and harder bound — below.

## Decisions

- **The plan's prescribed fix is REFUTED, measured.** `docs/plans/
  guard-pairs-done-by-depth.md` prescribes "walk forward counting `do` up
  and `done` down", and the research node asserts that this single change
  closes both ends of the defect. It does not. Built as a prototype and fed
  19 payloads on stdin as the event delivers them, 2026-10-08: it fixes both
  false negatives (the Goal's payloads 1 and 2) and leaves BOTH prose false
  positives (payloads 3 and 4) denied. 5 wrong readings before, 2 after —
  real progress, and not the plan's Acceptance, which requires "the two
  prose shapes → 0".
- **Why it cannot work, and it is not a tuning problem.** A bare `do` is a
  separator, not a nesting token — one `done` per OPENER, never per `do`. So
  a prose `while` in front of an ordinary `for ...; do ... done` claims that
  `for`'s `do` and its `done`, and no amount of depth counting over `do`
  separates them. Closing the prose end REQUIRES recognising what opens a
  loop.
- **The design that does work, measured 0 wrong of 19.** Count OPENERS up
  and `done`s down; never count bare `do`. `depth` starts at 1 (the keyword
  is its own first opener) and the `done` returning it to 0 is this loop's.
  Two narrowings on the opener pattern are what keep it from re-opening the
  hole that reverted the last attempt (see `## Rejected`):

  ```
  close_re='(^|[^[:alnum:]_])done([^[:alnum:]_]|$)'
  open_re='(^|[;&|(){}'"'"'"`]|[^[:alnum:]_](do|then|else))[[:space:]]*(while|until|for[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]+in|for[[:space:]]*\(\(|select[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]+in)([^[:alnum:]_]|$)'
  ```

  - `for NAME in` / `for ((`, never a bare `for`. A bare `for` in the
    opener set is what broke `"ready for connections"`.
  - COMMAND POSITION — start, or after `; & | ( ) { }`, a quote, or `do` /
    `then` / `else`. A real opener begins a command; the `for` inside
    `"waiting for jobs in queue"` does not. Without this clause that string
    unbalances the count and the real wait around it is ALLOWED (shape H1).

  Three more decisions ride with it, each measured:

  - advance `rest` past the KEYWORD only, never past the `done` — advancing
    past the `done` swallows a nested loop whole, which is payload 2;
  - on an unbalanced count, FAIL OPEN **and carry the walk on** to the next
    keyword — a skip that never restarts the walk was the reverted attempt's
    entire regression;
  - `sleep` tested over the whole `span`, counters over `own` (this loop's
    own depth) only. A `sleep` in a nested `for` is a sleep this loop
    performs every iteration; a counter in that `for` bounds nothing outside
    it. Reading counters over the whole span is the defect the per-loop walk
    exists to prevent.
- **The deny message is owed and was written.** It printed `no timeout` at a
  command carrying `timeout 900`. Fixed by naming the keyword actually
  matched (`start_re`'s own capture) and saying what is missing AROUND THE
  LOOP: no `timeout` wrapping it, no counter in its condition or body.
- **Captures must sit immediately after their own match.** Every
  `[[ =~ ]]` overwrites `BASH_REMATCH`. Reading it later is what made an
  earlier attempt exit 1 — a hook FAILURE this event reads as "allow, and
  log it", i.e. the gate silently absent with its own suite green
  (`feedback` r2 on this file).

## Rejected

- **Pure `do`/`done` depth counting** — the plan's and the node's
  prescription. Measured above: 2 of 19 payloads still wrong, both of them
  the false positives the research node exists for.
- **A bare `for` in the opener set.** Measured by the previous attempt and
  re-confirmed here as shape H1: any string containing `for` unbalances the
  loop around it and the wait is allowed. `"ready for connections"` is a
  real readiness line and this repo selects the docker layer.
- **Falling back to a `while|until`-only count when the count does not
  balance.** Closes H1 but re-denies payload 4, because dropping the `for`
  lets the prose keyword claim the retry loop's `done` again. Traced, not
  built.
- **Reverting to `f9ea7d6`'s single greedy match.** The plan already rejects
  it and the reason holds: it let a counter in a harmless first loop bound a
  dangerous second.

## Review

- r1: the plan's central design claim is false, and the plan is where the
  next session will read it. `./joharness.sh` prototype feed, 19 payloads on
  stdin, 2026-10-08: the prescribed `do`/`done` count leaves payloads 3 and
  4 at exit 2 where Acceptance requires 0. (fixed — filed as #314 with the
  measurement and the design that holds, so it is queue-visible before
  anyone builds from the plan's current text. Correcting the plan file
  itself is product judgement and stays the human's.)
- r2: no `(verifier)` finding on this branch. Step 5's independent reader
  was not spawned because there is no diff to review — the build was
  reverted unverified (see `## Blockers`). `JOHARNESS_REVIEW=off`, so no
  gate fires; recorded because an empty `## Review` is not a clean pass.
  (wontfix — nothing built to review)
- r3: the measurement rig was ephemeral (session scratchpad), so the numbers
  above carry their payload table in prose rather than a committed harness.
  A session applying this design should rebuild the feed as the plan's
  Acceptance already specifies and re-derive every exit code rather than
  trusting these. (open — by design; a written number is not a counted one)

## Blockers

**Blocks: executing the guard is refused as self-modification, and that is
correct.** `.agents/harness/pretool-bash-guard.sh` is the PreToolUse hook on
Bash for this very session. Editing it and then running it — `bash -n` on
it, its selftest topic, `ci`, `verify`, or `mutate` — means executing my own
unverified guardrail, and every subsequent Bash call in the session would be
gated by it. The harness classifier refused with `[Self-Modification]`, so
the edit was reverted and the tree is clean at `95aecf6`.

This is NOT the protocol-path bound the human waived. It is a separate
control, it sits outside this repository, and a session cannot waive it for
itself. Two independent mechanisms land on the same line, which is the
line's whole point: the thing being edited is the thing doing the gating.

**Unblocks:** a session that may execute this file. The design above is
measured and ready to apply; what it still owes is everything that needs
EXECUTION, and none of it was done:

- the existing topic still green (13 `pbg_allowed` / 12 `pbg_denied`, both
  totals may only grow);
- new cases for all four Goal payloads, the `when` control, the two
  readiness shapes, and shape H1;
- each new case failing without the fix (restore the walk, re-run);
- every new line pinned by `./joharness.sh mutate` — `feedback` r3 and r9 on
  this file both record clauses this tool found unpinned AFTER their author
  had run it twice and thought they were done;
- `ci: pass` and `verify` 0 failed.

**Also unblocked by nothing here: the plan needs fixing first** (r1). A
session that builds from its current Goal and Scope builds the refuted
design.

## Where to look

- **#314** — this session's finding as a queue item: the refutation, the
  measured table, and both regexes. Filed because a plan's text is what the
  next session reads, and an unmerged branch is not. `issue:` above is
  deliberately `none`: #314 is filed, NOT claimed, and marking it claimed
  would have the hook report work nobody is doing.
- `docs/plans/guard-pairs-done-by-depth.md` — the fix, `agent: opus`,
  `effort: high`. Its Goal's four payloads are the acceptance; its central
  prescription is wrong (r1).
- `docs/research/bash-guard-reads-prose-as-a-loop.md` — the settled answer,
  the five measured instances, and the narrowing that was built and
  REVERTED. Read `## Findings` whole first.
- `./joharness.sh feedback .agents/harness/pretool-bash-guard.sh` — nine
  prior findings on this file, including the two verifier findings (r6, r7)
  that reverted the last attempt. The design above is built to clear both
  and was measured against the shapes they name.
- `.agents/harness/pretool-bash-guard.sh:start_re` — `for` deliberately
  absent, which is right; the opener set above is a SEPARATE pattern used
  only for depth counting, and nothing new is ever deniable on its own.
- `.agents/harness/selftest/pretool-bash-guard.sh:pbg_denied` — the
  assertion helpers. Payloads there nest under `tool_input`, which the
  key anchor reads; a flat `{"tool_name":...,"command":...}` also works.
