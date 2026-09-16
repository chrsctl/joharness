---
workstream: pending-spawns
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: pending-spawns
issue: 255
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-16
next: Retire the workstream file and the plan, open the pull request, merge, comment on #255
---

## Goal

Issue #255. `dispatch` derives its slot count from the git view, so a manager
spawned minutes ago is invisible until it pushes its claim — measured 3 to 12
minutes. Twice in one evening the count read a free slot that was already
owned. Nothing reconciled the two views; the only thing that knew was an
orchestrator keeping its own notes.

## Decisions

- The issue offers three routes and prefers the second. Taking it, plus the
  first, because they are not alternatives: an input nobody is told to
  supply is never supplied. So `dispatch` gains the input, and
  `orchestrate.md` gains the duty to pass it, in one change.
- Route three, reconciling from the control plane inside `dispatch`, is
  rejected for the reason the issue gives: `dispatch` is the git view, and
  pulling session state into it collapses the "two signals, never one"
  separation the health table rests on.
- The input can only LOWER the count. That is the safe direction: a count
  too high spends a manager over the cap, which is the human's money, while
  a count too low costs one pass of one spawn.
- Read from the ENVIRONMENT only, never `joharness.conf`. Every other number
  here is a repo-level setting a conf legitimately carries; this one is a
  fact about one pass, and a stale conf value would silently under-report
  slots for ever with nothing to notice it.
- So it is NOT in `joharness.sh`'s knob list at the top of the file. That
  list opens "Selection lives in joharness.conf", and a non-conf key under
  that sentence invites the conf entry the decision above rules out. The
  slots line names the variable where a reader meets it, and
  `orchestrate.md` carries the duty.
- The plan's claim that `n_slots` reaches every verdict is wrong, found
  while reviewing rather than while writing. See `## Review` r1.
- The plan said the duty goes at the spawn step. Widened to BOTH steps
  while building: step 1 is where dispatch runs and so where the number is
  applied, step 3 is where the `@new` entry that supplies it is written. One
  line each; the fact and its use are two places and a reader arrives at
  either.
- A `@new` entry that step 2 archives or reports is still counted by step 1,
  because step 1 ran first. Said in the command file rather than engineered
  around: the pass runs one slot short and the next pass has it back, which
  is the safe direction, and re-running dispatch to win the slot back would
  read the fleet twice in one pass.

## Rejected

- Keying slot accounting on the workstream file's `session:` line. It names
  whoever last WROTE the file, so after a respawn it advertises a dead
  session until the successor claims — the same window this closes, reopened
  one field over. Recorded in issue #249 and now in the command file.

## Review

- r1: (session) the plan said "every verdict below reads that variable", and
  two do not. `DRAINED — nothing free, nothing in flight: exit` and
  `PAUSED — spawn nothing, exit` both count MANAGERS
  (`n_inflight - n_blocked`), never `n_slots`, so the lowered slot count
  cannot reach them. Input that breaks it: an empty queue, nothing pushed,
  `JOHARNESS_PENDING_SPAWNS=1` — dispatch told the orchestrator to exit over
  a manager it had spawned minutes earlier, item unclaimed, session still
  billing. That is issue #255 in its worst direction, and the change as
  first written missed it. (fixed — both branches now keep the health pass
  going when `pending` is non-zero, counted SEPARATELY from the rows above
  rather than folded into that number, because "N manager(s) in flight" is
  a sentence true of every row it lists and no row lists this one. Four
  assertions on the empty-queue fixture, both exits and both controls.)

- r2: (verifier) the same defect as r1, found independently against the
  pushed head and reproduced the same way: empty queue, nothing in git,
  `JOHARNESS_PENDING_SPAWNS=1` printed `DRAINED — nothing free, nothing in
  flight: exit, the heartbeat re-seeds`, and with `JOHARNESS_MAX_MANAGERS=0`
  the pause's own exit. Two readers, one answer. (fixed with r1 — its four
  assertions were already written when this landed; the mutation that drops
  both guards reds all four, run 2026-09-16.)
- r3: (verifier) `JOHARNESS_PENDING_SPAWNS=18446744073709551613` is digits
  all the way, so the filter passed it, and the subtraction WRAPPED 64-bit
  arithmetic to a positive result: `slots : 7 of 4 free`, `spawn up to 5
  now`, against a cap of 4. The input that can only lower, raising the count
  past the cap — the exact failure this change exists to close, produced by
  the change. (fixed — a `pending_used` clamped to the cap before the
  subtraction sees it, compared by digit count first because a numeric
  compare on the untrusted value is the same arithmetic. The line still
  reports the caller's own number, so a reader sees what was passed.)
- r4: (verifier) `JOHARNESS_PENDING_SPAWNS=08` passed the digit filter and
  bash read it as OCTAL: `value too great for base`, exit 1, dispatch dead
  after the in-flight rows with no slots line and no verdict. The comment
  three lines up claimed a mistyped value "loses the correction instead of
  erroring at the reader"; it was false for every zero-padded count with an
  8 or a 9 in it. (fixed — leading zeros stripped before any arithmetic,
  which also makes `0` the one spelling of none for the guards below.)
- r5: (verifier) reported the `## Review` entry as claiming a fix absent
  from the code. True of the pushed head it read, not of the tree: the fix
  and its record are one commit, which is the rule, and this commit is it.
  (no change — the finding is an artefact of reviewing a head mid-build,
  and it named the real defect underneath, which is r2.)
- r6: (verifier) reported the cases as non-vacuous but confined to one
  fixture — no empty queue, no overflow value, no zero-padded value, so `ci`
  would go green over all three defects. Correct and now closed by r1's four
  empty-queue assertions and r3/r4's five. (fixed — and each set proved by
  mutation, not by argument.)
- r7: (session, method) every fix above was proved by REVERTING it and
  running the suite, never by reading the code. Five mutations, all run
  2026-09-16 with `bash .agents/harness/selftest.sh` against a baseline of
  2015 passed / 0 failed: dropping the subtraction reds 5 assertions, 3 of
  them positive; dropping the digit filter reds 3; dropping both exit guards
  reds 4; dropping the cap clamp reds 2; dropping the leading-zero strip
  reds 2. No two mutations red the same assertion, so each guard is pinned
  by its own case rather than by the set. (no change needed)

## Blockers

None.

## Where to look

- `joharness.sh`, at `n_slots` — the one assignment every verdict below
  reads. (Line numbers move; the variable does not.)
- `.claude/commands/orchestrate.md` step 1 — the dispatch invocation that
  carries the number; step 3's ledger paragraph — where the `@new` entry
  that supplies it is written.
- `.agents/harness/selftest/dispatch.sh` — the cases for this input, on the
  same fixture as the slot assertions above them (cap 4, alpha in flight).
