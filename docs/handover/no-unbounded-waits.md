---
workstream: no-unbounded-waits
status: done
branch: claude/drain-67lt1l
pr: none
plan: no-unbounded-waits
issue: none
session: https://claude.ai/code/session_015XtCMDkJC9wPu9htijCRbw
agent: sonnet
updated: 2026-09-05
next: Nothing — plan complete, retired in this branch's last commit before the PR.
---

## Goal

Requester, 2026-09-05: "maybe infinite loops should not exist". Two commands
in one session could not finish and both were caught after the fact — one by
a human reading the background-tasks panel at 1h 17m, one by the stop guard
at 18m. Add the stage that refuses the command before it runs.

## Decisions

- Took `no-unbounded-waits` over the queue's first item `orchestrated-run`.
  That plan's own "BEFORE YOU START" hands three calls to the human (the cap
  and three other knobs in `joharness.conf`, creating the heartbeat Routine,
  stocking the queue) and records that no heartbeat exists and the queue is
  not stocked. Money and product direction = ask, do not decide
  (`.agents/harness/AGENTS.md`, Decide alone). So it is not actionable this
  session; this one is. Both sit in wave 1 with disjoint `scope:`.
- Plan tier is `sonnet`; this session runs `opus`. Escalation, allowed.
- The check matches the WHOLE loop shape — `while`/`until` AND `do` AND
  `sleep` AND `done` — not the word `until`. Command-position matching was
  the first draft and could not see a loop inside `bash -c '...'`, which is
  where the acceptance's own bounded spelling puts it. Requiring the full
  shape is also what keeps `grep -n 'until.*sleep' file` out of the net: a
  pattern has no `do` and no `done`.
- Counter-bound detection reads the whole matched LOOP, not the condition
  alone. A superset, so it errs toward allow, which is the direction a gate
  has to err in to survive. `<` and `>` are deliberately not read as
  comparisons: `>/dev/null` sits in the condition of the first incident
  command, and reading a redirect as a bound would allow the exact command
  this hook exists for.
- Two changes to `perf` the row needed, both small and both load-bearing:
  - `perf_count` fed `</dev/null`, so a hook that exits early on empty
    stdin measured its fail-open path and would have reported `ok` forever.
    Rows gained a fifth field, the stdin payload, written to a file (an
    empty payload writes an empty file — identical to the old /dev/null, so
    the "never the loop's own stdin" guarantee is unchanged).
  - The floor (15) is now capped at the row's own budget. `bash-guard` is
    budgeted at 0 — no git/awk/sed/grep/sort/wc on a path that runs before
    every Bash call — and a fixed floor reds a row whose correct count is
    zero. Counted 2026-09-05, `JOHARNESS_PERF=always ./joharness.sh perf`:
    `bash-guard 0`, every other row unmoved (feedback 212, review 261,
    graph 103, session-start 322, queue-context 126, queue-orchestrated
    126, drain 323, handover-guard 21).
- `perf.sh` asserted `refute "  0 "` on the whole table to mean "a NOT FOUND
  row never prints a clean count". A row budgeted at 0 supplies that string
  from its BUDGET column, so the case redded for a reason unrelated to
  counts. Found by `ci`, not by review. Now reads the counted column of
  every NOT FOUND row and requires `?`.
- Guard is pure bash: `read -d ''` for stdin, `[[ =~ ]]` for every test. No
  forks, which is what a budget of 0 means and what makes the row a gate.

## Rejected

- Matching the loop keyword only in COMMAND position (start of command, or
  after `;` `&&` `||` `|` `(` `{`). Rejected: it cannot see
  `timeout 60 bash -c 'until ! pgrep -f xyz; do sleep 3; done'`, where the
  loop sits behind a quote — and acceptance requires that one DENIED.
  Widening the preceding-character set to include quotes brought
  `grep 'until.*sleep'` back in. The full-loop shape settles both.
- A bare `[^[:alnum:]_]` boundary before `sleep` and `done`. Rejected:
  `do[[:space:]]` has already consumed the only space in `do sleep 5`, so
  there is no character left for the boundary and the commonest spelling
  never matches. It allowed incident command one — measured, first draft.
  `(.*[^[:alnum:]_])?` between keywords is what works.

## Review

Depth: sonnet — `/code-review` (high) on the full diff, plus
`.claude/agents/verifier.md` at the branch's tier. Both read a diff neither
wrote. Every finding below was reproduced by running the guard, not read off
the page.

- r1: (code-review) `|| exit 0` in the registration turns exit 2 — the only
  DENY channel a PreToolUse hook has — into 0, so the gate blocked nothing.
  The script exited 2, the registered line exited 0, and the whole feature
  was a no-op that passed its own suite. The idiom is right for
  `pretool-feedback.sh` only because that hook never denies. (fixed —
  `if bash -n S; then bash S; else exit 0; fi`: a copy that cannot parse is
  skipped, a deny is not. Five cases pin it, including running the
  registered line itself)
- r2: (code-review) SC2016 on four lines with no disable directive, so
  `./joharness.sh ci` ended `ci: FAIL` at the shellcheck stage — the same
  command GitHub's lint check runs. (fixed — targeted disables; `shellcheck`
  clean on both files)
- r3: (verifier) the shape matched with ONE greedy regex, and ERE is
  leftmost-longest: a command holding two loops matched as a single span
  from the first keyword to the LAST `done`, so a counter in a harmless
  first loop read as bounding a dangerous second.
  `i=0; while [ $i -lt 3 ]; do sleep 1; i=$((i+1)); done; until grep -q x
  /tmp/f; do sleep 20; done` was ALLOWED — and its tail is incident command
  two. (fixed — the guard walks one loop at a time, cutting each out at its
  own `done`; a case pins it)
- r4: (code-review, verifier) `-lt/-le/-gt/-ge` anywhere in the loop counted
  as a bound. `until [ "$(grep -c joharness /tmp/f)" -gt 0 ]; do sleep 20;
  done` — incident command two respelled — was allowed, and so was an
  unbounded loop whose body merely echoed `x -lt 10`. (fixed — a counter
  compares a `$variable`; a test on the world and a word in a log line are
  neither. Two cases)
- r5: (verifier) `timeout` was read anywhere in the command, so
  `while ! timeout 5 curl -sf http://host/health; do sleep 1; done` passed
  though the retry loop is unbounded — the timeout bounds one curl, never
  the loop. (fixed — `timeout` is read only in the text preceding the loop
  keyword, which is where a wrapper sits; a case pins it)
- r6: (code-review) the pgrep self-match check wanted the `f` flag adjacent
  to the command, so `pgrep -l -f` and `pgrep --full` missed it — and with a
  `timeout` present they were then allowed silently, the exact outcome the
  pgrep-first ordering exists to prevent. (fixed — command and flag matched
  separately; two cases)
- r7: (verifier) an unbounded loop whose body only ECHOES the word "sleep"
  was denied: `while ! test -f /tmp/ready; do echo "sleep tight, still
  waiting"; done`. An ordinary log line, and the kind of miss that teaches a
  session to route around a gate. (fixed — `sleep` must carry an argument,
  which a real one always does; a case pins the allow)
- r8: (code-review) no assertion on the registration at all, unlike the
  sibling `pretool-feedback` topic. That gap is why r1 shipped green.
  (fixed — five cases read the PreToolUse block out of `settings.json` and
  run the registered command line against a deny payload, an unparseable
  copy and a missing one)
- r9: (code-review) capping the perf floor at each row's budget also clamped
  an explicitly raised `JOHARNESS_PERF_FLOOR`, so `perf.sh`'s
  `FLOOR=100000` case silently became a test of graph's count staying under
  118. (fixed — the clamp compares against `PERF_FLOOR_DEFAULT`;
  `JOHARNESS_PERF_FLOOR=100000 ./joharness.sh perf graph` is red again,
  2026-09-05)
- r10: (verifier) `perf_rows`' `|` separator has no escape, and the
  constraint was a comment rather than a check: a `|` in any row's payload
  shifts every field right of it, and the payload fragment becomes the
  command that runs. (fixed — a case counts the fields on every row; with a
  `|` injected into the graph row the counts go `5 6`, 2026-09-05)
- r11: (verifier) a Bash call that only WRITES an unbounded loop — a heredoc
  authoring a monitor script — is denied. (wontfix — the guard reads the
  command as text and does not parse shell, and what is being written is an
  unbounded wait either way. The deny now names the path that works: use the
  Write tool for the file. Hit twice during this build and used both times,
  so the affordance is tested by use)
- r12: (code-review) two early `ci` runs on this container showed selftest
  failures that eight later runs and 2700 direct invocations of the guard
  could not reproduce; most consistent with a fork hiccup in the topic's
  helper leaving the previous case's status. (open — not reproduced, not
  attributed to the code. Recorded so a recurrence in CI is read as this and
  not as new)

## Verification

Counted on this branch, 2026-09-05, commands as given:

- `./joharness.sh ci` — `ci: pass`, 1585 passed / 0 failed. The perf table
  reads `bash-guard 0 0 pinned ok`; no other row moved.
- `./joharness.sh verify` — 6 passed, 0 failed (docker layer).
- `./joharness.sh mutate .agents/harness/pretool-bash-guard.sh <line> <text>`,
  baseline green on all three:
  - `164` (the shape gate, `while false; do`) — 14 cases red, among them both
    incident commands and `the REGISTERED line denies, not just the script`.
  - `201` (the timeout bound, `&& :`) — 1 case red,
    `a timeout-bounded wait is allowed`.
  - `202` (the counter bound, `&& :`) — 1 case red,
    `a counter-bounded loop is allowed`.

## Blockers

None.

## Where to look

- `docs/plans/no-unbounded-waits.md` — scope, acceptance, traps.
- `.agents/harness/pretool-feedback.sh` — the existing PreToolUse hook: the
  one-line payload flattening, the anchored key read, the fail-open doctrine.
