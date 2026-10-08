---
workstream: bash-guard-reads-prose-as-a-loop
status: in-progress
branch: claude/bash-guard-reads-prose-as-a-loop
pr: none
plan: guard-pairs-done-by-depth
issue: none
session: https://claude.ai/code/session_01JXryjCKHhwkN7Xrv1qXz55
agent: opus
updated: 2026-10-08
next: Graduate the node's reasoning into the guard header, verifier pass, ci + verify, retire node + plan + this file, pull request closing #271 and #314.
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

- r4: (session, supervised resume 2026-10-08) the design above, built.
  The recorded `open_re` rejected `for ((i=0;…`: its trailing word boundary
  applied to `((` too, and the next character is alphanumeric. (fixed — the
  boundary now applies to the word alternatives only, case "a nested for
  (( )) is an opener".)
- r5: (session) a newline turned into a SPACE took command position away
  from the line after it, so a nested `for` on its own line was a word, its
  `done` closed the outer loop, and the sleep after it was never seen —
  allowed. (fixed — a newline becomes ` ;`, which keeps every existing
  regex's reading and restores command position; case "a nested for on its
  own line is still an opener".)
- r6: (session) measured on a scratch copy, payloads fed on stdin from a
  file: old guard 8 wrong of 21, new 0 wrong of 28. With the old guard
  restored the topic reds 9 new cases (2222 passed, 9 failed); with the new
  one `ci: pass`, 2231 passed, 0 failed (before the last seven cases). (fixed)
- r7: (session) `./joharness.sh mutate` on the LIVE hook was refused by the
  harness classifier as `[Self-Modification]` after one line had run — the
  tool rewrites the file that gates the session's own Bash calls. Not
  retried, not worked around. The mutation proof was taken instead on a
  scratch copy against a 28-payload table: 21 mutations over every new
  line, all pinned, three that first read UNPINNED each given a case
  (`for the record`, the prose-keyword `timeout` prefix, and `kwname`,
  pinned by the topic's message assertion). (fixed in substance; the
  official tool's own run stands at 1 of 9 lines.)
- r8: (session, about the tool, not this diff) `cmd_mutate` writes the
  replacement through `sed`, which drops a backslash — mutating line 101 to
  `\\n` landed `\n`, a literal `n`, and redded unrelated cases. And it reads
  stdin, so a `while read` driver loses its remaining lines to the first
  call. (open — `joharness.sh` is protocol text; a finding for its owner.)
- r9: (session) when a quoted `while`/`until` unbalances a real loop, the
  walk heals by judging the quoted keyword as its own loop — and the deny
  then names THAT keyword: "this `while` loop" for a command whose real wait
  is an `until`. The decision is right; the name is the stand-in's. (wontfix
  — rare shape, deny still correct, and naming the outer keyword would need
  state the walk deliberately does not carry.)

## Blockers

**Lifted 2026-10-08** for the edit itself: a supervised session, at the
human's instruction, installed the design and ran the topic, `ci` and the
payload table against the live hook without refusal. What stayed refused is
`mutate` on the live hook (r7). The record below is the earlier block.

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
