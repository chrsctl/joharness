---
workstream: num-knob-digits
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: num-knob-digits
issue: 260
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-17
next: Review the diff, then retire the plan and the workstream file and open the pull request
---

## Goal

`docs/plans/num-knob-digits.md`, issue #260. `num_knob` filters its value to
digits only and hands the result to bash arithmetic. `08` and `09` pass the
filter and then die on the octal literal rule; `010` passes and is silently
read as eight. Every knob goes through this one reader, including
`JOHARNESS_MAX_MANAGERS`, which is the cap, which is the human's money.

The failure is quieter than a crash and worse. Measured 2026-09-17:
`JOHARNESS_CHURN_THRESHOLD=08 ... dispatch` exits 0 and prints its whole
output, because `set -e` is not in force and the arithmetic dies inside a
command substitution — so the knob is left EMPTY and the line reads `one
file rewritten + times`.

## Decisions

- Mutations go into a COPY, or through `./joharness.sh mutate`, never the
  working tree. The last item's r18 was mine and nearly shipped a mutated
  file: a `git add -A` while an injection was applied staged it, and the
  restore fixed the tree and not the index.

## Rejected

- `docs/plans/orchestrated-run.md`, which the queue ranks first. Its one
  remaining deliverable needs run 3 to have stopped; re-counted
  2026-09-17T04:19Z, three managers `SESSION_STATUS_RUNNING` with
  `updated_at` inside the minute. Its other precondition is the human's.
- The edge branch naming pull request #10. Re-read from GitHub this session:
  `state: closed`, `merged: false`, closed 2026-08-21.

## Review

- r3: (verifier) `expect "nothing reaches stderr" "" "$(...)"` is an
  assertion that cannot fail. `expect` is `grep -qF -- "$2"` and an EMPTY
  needle matches every string, so it passed over any stderr at all —
  including the `value too great for base` line it was written to forbid.
  Shown by `grep -qF -- "" <<<"value too great for base"`, which exits 0,
  and by the mutation: the case is NOT among the five that redded. This is
  the could-never-fail shape I have caught four times this session, written
  into my own test. (fixed — the haystack is now a marker when stderr is
  empty and the error text itself when it is not, so an empty needle is not
  available to be passed. Proof the repair took: the same mutation now reds
  SEVEN cases, up from five, and the two new names are exactly this one and
  r4's.)
- r4: (verifier) `expect "... read as decimal" "8+ = a warning on the work
  line"` does not distinguish 8 from 08: the unfixed line reads `; 08+ = a
  warning`, and the needle is a substring of it. Verified against the
  unfixed string directly; also absent from the mutation's red list. Its
  neighbour caught the regression, so the suite was right by accident and
  this case was named for a behaviour it did not pin. (fixed — anchored on
  the `); ` before it, which the unfixed line does not carry; it is in the
  mutation's red list now, which it was not before.)
- r5: (verifier) the ceiling does not bound what `num_knob` RETURNS, only
  what the environment or the conf supplies, and my comment claimed the
  stronger thing. Reachable: `JOHARNESS_CHURN_LIMIT` defaults to twice the
  threshold, so `JOHARNESS_CHURN_THRESHOLD=999999999` returns a ten-digit
  limit — `one file rewritten 1999999998+ times`, run 2026-09-17. Nowhere
  near the wrap and deliberate, but a comment the code contradicts is worse
  than no comment. (fixed — the comment says what the ceiling does and does
  not do, and a case pins the composed path so it is a decision rather than
  a gap somebody rediscovers.)
- r6: (verifier) the plan's SHIPS bullet asked for a consumer-side check by
  name and nothing on the branch named one. (fixed — in a consumer, under
  orchestrated mode, `JOHARNESS_MAX_MANAGERS=010 ./joharness.sh dispatch`
  prints `cap : 10 manager(s)` and a slots line counting against 10. The
  selftest tree is canonical-only and ships nowhere, so this is a check
  somebody runs there; it is in the pull request body as well as here.)
- r7: (verifier) the plan asked for the mutation counts reported with the
  command and the date, and they were in the commit message only, not in
  this file. (fixed — `./joharness.sh mutate joharness.sh 6193 '  :'` reds 5
  cases before the r3/r4 repairs and 7 after, `... 6210 '  :'` reds 1,
  disjoint, all run 2026-09-17. The verifier
  re-ran both independently and got the same sets.)
- r1: (session, method) the mutations went through `./joharness.sh mutate`,
  which puts the line back itself and proves the file is otherwise
  untouched. That is the last item's r18 applied rather than restated: there
  it was a hand-rolled injection into the working tree, and a `git add -A`
  while one was applied staged the mutated file. The repo already had the
  tool; I had not looked. (no change needed — recorded because the lesson is
  "use the tool", not "be careful", and the next session reads this.)
- r2: (session) the stderr helper was first written `2>&1 >/dev/null`, which
  does what I meant and is the spelling shellcheck reads as the classic
  mistake (SC2069) — and `ci` fails on warning level, so it would have gone
  red at the edge. (fixed — `{ ...; } 2>&1`, with the reason on the line so
  nobody 'simplifies' it back.)

## Blockers

None.

## Where to look

- `joharness.sh:num_knob` — the one reader, five lines.
- `joharness.sh:cmd_dispatch` — the caller that reproduces it fastest, and
  the command that PRINTS every knob it read.
