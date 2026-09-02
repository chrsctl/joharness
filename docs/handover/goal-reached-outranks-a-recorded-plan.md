---
workstream: goal-reached-outranks-a-recorded-plan
status: in-progress
branch: claude/current-state-review-oxfb7f
pr: none
plan: goal-reached-outranks-a-recorded-plan
issue: none
session: https://claude.ai/code/session_011LSGxqQsZyuMYSqxa3jVT5
agent: opus
updated: 2026-09-02
next: Move the goal check ahead of the free-plan branch in cmd_drain, then say the same in the queue hook
---

## Goal

A plan recorded with no goal open must not restart the fleet, or recording
becomes a way to manufacture a goal. Nothing implements that half of the
bullet: `cmd_drain` returns on the first free plan and the goal check sits
after that early return, so a recorded note is handed out and is the only
thing keeping an unattended fleet alive.

Plan tier is sonnet; this session is opus, which the protocol allows as an
escalation.

## Decisions

- **The goal is checked before the queue, and counted once.** In `cmd_drain`
  the check moves above the free-plan branch and its result is reused by the
  block below, which used to call `drain_goals` a second time. Two calls are
  two answers to one question and a reader trusts the second.
- **One printer for the stop.** `drain_goal_reached` is called from one place
  now, but the wording is load-bearing — a session acts on WHICH stop fired —
  and the message grew a paragraph that only makes sense when the queue is
  not empty. A function keeps the two facts in one place.
- **The hook gets the same check, at both of its terminal paths.** `drain`
  reads the hook, so a hook that still ordered a fleet would make the two
  readers disagree about one tree.
- **Recorded plans stay LISTED, in both modes.** What stops is the ORDERING:
  the fan-out order and the tail that points a session at the top free plan.
  A stop that hid the note would report an empty queue over a queue that is
  not, which is the same defect from the other side.
- **The hook's no-plans edge arm is narrowed, not deleted.** Probed
  2026-09-02: with no plans, a requirement is always unserved, so `unplanned`
  is non-empty and that branch takes it; with no requirement the new check
  stops first. The arm is unreachable today and is still the correct answer
  for the state it names, so it stays with the probe recorded beside it.
- **The fixtures that broke were asserting the pre-bound rule.** Sixteen
  cases carried no requirement at all and expected the generate-work edge.
  That is exactly the state PR 170 corrected `drain`'s cases out of when the
  goal bound landed; the hook was never brought under it. Re-aimed: the
  no-plans-no-goal state now asserts the stop, and the edge assertions moved
  to the path where a goal is open and nothing is free.

## Rejected

- **Hiding or de-ranking the recorded plan.** Recording is always allowed and
  the note is for a human. Taking it out of the listing to keep the fleet
  from seeing it trades one silent failure for another.
- **Fixing `drain` alone.** It reads the queue hook's output; leaving the
  hook ordering a fan-out while `drain` says stop is the two-readers drift
  this command's own comment forbids.
- **Deleting the unreachable edge arm.** It is right for the state it names,
  and a later change to where the goal check sits would want it back.

## Review

Depth is opus-adversarial, plus a verifier that did not write the diff. It
measured the two headline properties clean — supervised output byte-identical
across 40 comparisons (8 queue shapes x 3 mode spellings x 2 readers), and an
unreadable base ref still deferring rather than reading as "no goal" — then
found that the new early return and the new `exit 0` each stranded a block
that used to fire.

`./joharness.sh mutate`, run in a single-ref clone where the suite is green,
one run each:

| line replaced | cases redded |
| --- | --- |
| `drain_goal_reached "$next"` in `cmd_drain` | 7 |
| `qc_goal_reached` at the hook's free-plan path | 3 |
| `qc_goal_reached` at the hook's no-plans path | 5 |

- r1 (verifier): **the stop printed over a queue holding work and named
  nothing.** In a tree whose only plans are marked SUPERVISED ONLY, `next` is
  empty because `drain_plan` filters the marker, so the "queue is NOT empty"
  paragraph stayed quiet — and the goal check now returns above the NOT YOURS
  block, which therefore never ran. The hook listed that work while `drain`
  said nothing about it: two readers, one tree, different answers, which is
  the plan's own Trap and the thing `drain_goal_reached`'s comment claims to
  prevent. A regression this change introduced. (fixed — the marked list is
  read before the stop can fire and passed into the printer, and the block
  below reuses it rather than reading twice)
- r2 (verifier): **the open-issues pointer vanished from every unsupervised
  no-goal path.** Step 2 ranks GitHub issues above everything, a hook cannot
  read them, and both terminal paths lost the line that says so.
  `qc_edge_unsupervised` carries a comment recording that this exact omission
  shipped once before. (fixed — both stops carry it, and the drain one says
  it cannot read them either)
- r3 (verifier): **"anything listed above is a note for a human" was false of
  session-start output.** `handover-context.sh` prints the in-flight block
  ABOVE this one, so a session with its own pull request at review was told
  that pull request was a note for a human — and the hook's `exit 0` also
  dropped "finishing outranks starting". (fixed — the sentence is scoped to
  the QUEUE, and the stop now ranks edge work above itself explicitly)
- r4 (verifier): `refute ... "UNSUPERVISED:"` was vacuous — one free plan
  with no `scope:` reaches neither branch that prints such a line, so it
  passes against the defect. Third instance of this shape in this file;
  PR187 r2 was the second. (fixed — replaced by assertions on what the stop
  must keep. The recurrence is worth graduating and is noted below)
- r5 (verifier): the no-plans `qc_edge_unsupervised` call was dead, its
  `(no plans)` label unassertable from anywhere, and the comment defending it
  argued both sides in three lines. (fixed — deleted, with the probe
  recorded, and a case that reds if the label ever returns)
- r6 (verifier): the stop called an open research question "a plan recorded
  with no goal open", and dropped the settle-a-question entrypoint that state
  used to carry. (fixed — both stops are neutral about what kind of node the
  queue holds)
- r7 (verifier): a pre-existing fixture bug this change leans on. The
  TEMPLATE case wrote into `docs/product` after a plain `git rm` had taken
  the last file there, so the write landed nowhere and the case passed
  because the directory was empty, not because a TEMPLATE was excluded — and
  the `git rm` after it aborted on the missing pathspec, leaving the serving
  plan in place. Present on `origin/main` too. (fixed — both go through
  `fixture_rm`)
- r8 (verifier): the two readers worded the same stop differently, so a grep
  for one sentence found one of them. (fixed — both open "no open requirement
  in docs/product")
- r9 (verifier): the Acceptance names `mutate` and nothing recorded running
  it. (fixed — the table above)
- r10: my own, found by running it. The needle
  "recording would be a way to manufacture a goal" wraps across two `printf`
  calls, and `expect` is `grep -F`, so it could never match. PR170 r5 is the
  same trap in the same family. (fixed — the needle is what fits on one line)

**Worth graduating** (`.agents/docs/feedback.md`): three findings in this
file are one rule — an assertion aimed at a line the hook only prints in a
state the fixture is not in. `refute "1 free plans"`, `refute
"UNSUPERVISED:"`, and the wrapped-needle case are all it. Nobody has written
that rule down; not this branch's scope, and recorded here so the next one
can.

## Blockers

None.

## Where to look

- `joharness.sh:cmd_drain` — the early return on `next`.
- `joharness.sh:drain_goals` — counts open requirements, non-zero on an
  unreadable ref.
- `.agents/harness/queue-context.sh` — the second reader, which must agree.
