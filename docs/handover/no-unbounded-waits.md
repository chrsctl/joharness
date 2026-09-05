---
workstream: no-unbounded-waits
status: in-progress
branch: claude/drain-67lt1l
pr: none
plan: no-unbounded-waits
issue: none
session: https://claude.ai/code/session_015XtCMDkJC9wPu9htijCRbw
agent: sonnet
updated: 2026-09-05
next: Run ci green, then the tier's review, then finish (retire files, PR, merge).
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

## Blockers

None.

## Where to look

- `docs/plans/no-unbounded-waits.md` — scope, acceptance, traps.
- `.agents/harness/pretool-feedback.sh` — the existing PreToolUse hook: the
  one-line payload flattening, the anchored key read, the fail-open doctrine.
