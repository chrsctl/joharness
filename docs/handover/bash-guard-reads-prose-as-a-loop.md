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

- r10: (verifier) REGRESSION — any opener the walk counts with no `done` of
  its own makes the real loop around it fail open, and only a quoted
  `while`/`until` FOLLOWED by its own sleep heals. new/old exit codes:
  `until [ -f /tmp/ready ]; do sleep 5; echo "while waiting"; done` 0/2;
  `... do sleep 5; echo "until"; done` 0/2; `until grep -q x /tmp/f; do
  echo "for x in list"; sleep 5; done` 0/2; a multi-line inline-Python
  `for line in ...:` inside the loop (the ` ;` newline puts it in command
  position) 0/2. (fixed — see r13.)
- r11: (verifier) REGRESSION, fail-open by time — the walk is ~k·m·n:
  every unbalanced prose keyword scans to the end of the command. 8.8 KB of
  `echo wait while now; for ...; done` lines: 18.16 s new, 0.15 s old,
  against the registration's 10 s hook timeout. (fixed — see r13.)
- r12: (verifier) pre-existing, same both ways: a `done` inside the
  condition closes the loop early — `until test -f /tmp/build.done; do
  sleep 5; done` 0/0; `timeout` anywhere earlier counts as wrapping (0/0);
  openers after `!` or `time` are not in command position (0/0); and the
  intended span-wide sleep now denies `while read f; do for x in a; do :;
  done; sleep 1; done < list` 2/0, consistent with the existing
  `while read` + sleep policy. (first and third fixed with r13; the
  `timeout`-anywhere one is out of this plan's scope and left as is.)
- r13: (session) the fix for r10/r11: decide prose by the KEYWORD's own
  position, never by whether its count balances. A keyword not in command
  position is skipped at once (O(n), so r11's shape costs one regex each);
  a keyword in command position whose count does not balance falls back to
  the old first-`done` pairing, so an unbalanced count can never be more
  permissive than `origin/main`. `done` closes only after a separator, and
  `!` / `time` join the command-position set — only when they are
  themselves in command position, so "at the same time while" stays prose.
  (fixed)
- r14: (session) r13's first cut still re-scanned the rest of the command
  per keyword: 7.8 KB of quoted `while`s before ordinary loops took 27.69 s
  (scratch `perf3.py`, 2026-10-08). The walk now tokenises ONCE (every
  opener and `done` with its offset), pairs openers with a stack, and
  records each token's first following `done` in a reverse pass; judging a
  loop is integer lookups. Same input 0.41 s; 15.6 KB 1.31 s; the
  verifier's own inputs at origin/main's speed. No `stack[-1]` (bash 4.3):
  an explicit pointer, for consumers on macOS bash 3.2. (fixed — a timing
  case in the topic, bounded at 4 s.)
- r15: (session) measured on the 23 payloads r10–r14 added, payloads fed
  from files: first build 15 wrong, origin/main 10, now 0; full table now
  0 wrong of 51. Mutation screen on the scratch copy: 25 mutations over
  every rewritten line, all pinned, after three (`quotes` in the position
  set, `close_re`'s `^`, a bare `for`) first read UNPINNED and each got a
  case that makes the fallback give the wrong answer. `ci: pass`, 2254
  passed, 0 failed. (fixed)

- r16: (verifier, round 2 at 43dab32) REGRESSIONS, HEAD/origin-main:
  r13's `close_re` misses a real `done` after `}`, `)`, `fi`, `esac`,
  `]]`, `))` — `until test -f /tmp/r; do { sleep 5; } done` 0/2 — and the
  unpaired loop's fallback then finds no `done` and allows, or reaches the
  next loop's counter (`...{ sleep 5; } done; i=0; while [ $i -lt 3 ]...`
  0/2, G2's shape back). Keyword positions `pos_re` misses: `coproc`,
  `time -p`, `! time`, `if until`, `elif until`, `eval until ...\;`,
  `ssh host until ...\;`, all 0/2. Time: 37–62 KB heredocs 7–30 s against
  origin/main's 2.7–7 s; cause measured — the tokeniser runs two
  `${s%%"$x"*}` cuts per token, quadratic in length. False positives 2/0:
  the same unseen `done` widening a no-sleep span into a later loop; a
  `break 2` counter in a nested loop. (fixed by r17's redesign; `break 2`
  wontfix — rare, and the deliberate `own` rule.)

- r17: (session) the overlay, built from the research step below. Reader
  A = origin/main's walk plus the prose skip; reader B = the depth walk,
  denials only, one `token_re` match per token (one prefix cut, not two),
  up to 8 KB. Measured, payloads from files: 65 payloads 0 wrong; on the
  14 r16 adds, origin/main 3 wrong, 43dab32 14, now 0. The round-2
  verifier's own scripts against it: one 0/2 left, `ssh host until ...`,
  as the research step records; its other two differences are the
  `break 2` wontfix and "things to do while waiting", a prose false
  positive origin/main has and this fixes. Its timing inputs to 62 KB at
  origin/main's speed or better (37 KB heredoc 1.20 s vs 2.85 s). Mutation
  screen, 21 mutations: 20 pinned; the survivor is B's 8 KB gate, which
  changes only time — 0.78 s with it, 1.56 s without, on a 37 KB command A
  allows — so no exit code can pin it. `ci: pass`, 2265 passed, 0 failed.
  (fixed; the gate's pin is open by nature, a timing line with no case.)

- r18: (verifier, round 3 at af5a4a1) the claim "the prose skip passes
  over prose only" is FALSE. A CHAIN of shell words, or a name the syntax
  puts there, read as prose — `else if until`, `if time until`, `if if
  until`, `do if until`, `coproc W until`, `coproc time until`, `function f
  until` — and B's `pos_re` has no `if`/`coproc`/`function`, so both
  readers missed them: 0/2, each EXECUTED and still waiting at 2 s (one
  coproc outlived its `timeout` and was killed by hand). And above 8 KB the
  skip still cut per keyword: 80 KB of "waits while" notes 11.48 s against
  origin/main's 0.06 s. (fixed — `shellword_re` is a chain anchored at
  command position, with `coproc`/`function` taking an optional NAME; the
  skip runs only where B does, ≤ 8 KB, so above it the guard is origin/main
  exactly. Measured: the round-3 payloads 0 wrong, its timing inputs at
  origin/main's cost — 100 KB "mixed" 17.42 s vs 17.11 s, after `judge`
  stopped taking the loop text as arguments, which had cost a fifth. A
  timing case pins the gate: 10.83 s without it, 0.07 s with.)
- r19: (verifier, round 3) the `break 2` wontfix of r16 also has an `exit`
  and arithmetic variant — `while :; do sleep 1; for ((k=0;k<1;k++)); do
  ((c++ > 9)) && exit; done; done` 2/0. Same class, recorded for
  completeness. (wontfix — B's deliberate `own` rule.)
- r20: (session) measured after r18's fix: 76 payloads 0 wrong; on the 11
  r18 adds, af5a4a1 9 wrong, origin/main 2 (both prose false positives),
  now 0. Mutation screen of the new lines, 7 mutations: every mutation of
  `shellword_re` and the gate's comparison pinned; the two survivors are
  the skip's gate and B's gate, which change only time — the first pinned
  by the timing case above, the second as r17 records. `ci: pass`, 2271
  passed, 0 failed. (fixed)

## Research step (review churn, 2026-10-08)

r16's first regression was made BY r13's fix — the churn rule's trigger.
Stop patching; the requirements, the conflicting pair, the resolution.

Requirements: (a) the four Goal payloads and the prose shapes read right;
(b) no real wait origin/main denies is allowed, except where a keyword is
plainly prose; (c) inside the hook's 10 s on anything origin/main reads
inside it; (d) fail open, no forks, bash 3.2.

The conflicting pair is (a)+(b) against the walk being the ONLY reader.
Every round replaced origin/main's positional reading with a structural
one, and a structural reader of shell-as-text has edges — each edge is a
real wait origin/main denied and the new reader does not. Narrowing the
edges (r13) moved them; it cannot remove them.

Resolution: do not replace the old reader — OVERLAY it. Deny if EITHER
denies:
- A = origin/main's walk, unchanged but for one skip: a keyword that is
  plainly prose — right after an ordinary word that is not a shell word
  that can precede a compound command (`do then else elif if time coproc
  eval while until`) — is passed over, the walk advancing past the keyword
  only. That skip is the ONE place the guard is more permissive than
  origin/main, and it is what (a)'s prose shapes need.
- B = the depth walk, only adding denials: nested `for` stealing a
  `done`, a nested `until` swallowed, `.done` sentinels, counters that
  belong to an inner loop. B never allows anything; an unbalanced loop is
  simply not B's to judge, because A already read it. B runs on commands
  up to 8 KB, where its cost was measured well inside the timeout; above
  that, A alone — origin/main's reading and origin/main's cost.

`ssh host until ...` stays 0/2: "host" is an ordinary word, and no text
rule tells it from prose. Recorded, not fixed.

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
