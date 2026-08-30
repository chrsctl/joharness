---
workstream: guard-vacuous-assertions
status: done
branch: claude/guard-vacuous-assertions
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-30
next: Retire this file, open the pull request, merge.
---

## Goal

Build the detector `docs/plans/guard-vacuous-assertions.md` asks for, and
find out it does not work. Negative result, measured, with a successor plan
that goes at the class behaviourally.

## What was built and measured

A vacuity check in `selftest.sh`: `expect` and `refute` append every haystack
to one file, `refute` also appends its needle, and after the last topic every
needle absent from every haystack is reported. 186 refutes in the suite,
measured 2026-08-30:

| Conditions | Flagged | True positives |
| --- | --- | --- |
| needle in no haystack | 64 | 0 |
| + not a literal in any harness source | 64 | 0 |
| + shares a 20-char run with source | 4 | 0 |

The 60 dropped by the third condition are fixture-local strings — branch
names, scratch filenames — that the code is right never to print. The 4 that
survive are correct assertions naming a specific bad state that does not
occur, e.g. `FINISH BEFORE STARTING: origin/bblocked`, which is producible
and rightly absent.

Zero true positives at every setting.

## Decisions

- **Not shipped.** Zero true positives and four false ones is negative value
  in every run, and an opt-in tool with unproven value is dead code. Reverted
  from `selftest.sh`; what ships is the measurement.
- **The plan is retired and its successor says DO NOT REBUILD**, with the
  table. A negative result nobody wrote down gets re-derived by the next
  session that has the same idea, and it is a good idea — it just does not
  work.
- **The successor goes at it behaviourally.** Both known instances were found
  by changing the code and re-running, which is Loop step 5's existing rule.
  The gap is that nothing makes it cheap, and PR 153 showed it is easy to
  aim wrong.

## Rejected

- **Shipping it report-only anyway.** Four lines of noise per run, forever,
  to catch nothing yet.
- **Loosening to 12-character runs to catch more.** That is tuning a
  threshold until the answer is the one wanted, on a suite with no known
  true positive to tune against.

## Review

Round 1, opus, self.

- r1: the plan's Acceptance required catching BOTH known instances. The
  detector cannot reach the 2026-08-28 one at all — those were three
  `expect`s, and this only examines `refute` needles. That should have been
  visible from the plan's own description before any code was written.
  (recorded — the plan was wrong to promise it, and the successor states the
  class is behavioural rather than static)
- r2: it is BACKWARDS on the one case it can reach. It flags
  `EDGE: pull request #none` against the source that assertion was written
  against, and misses it after the message is reworded — going quiet exactly
  when the assertion drifts out of true. Checked both ways. (recorded — this
  is the strongest single argument against the approach and it is in the
  successor)
- r3: `git rm` of the last plan file removed `docs/plans/` itself, and the
  heredoc writing the successor failed with "No such file or directory"
  while `ci` still printed `ci: pass` — the plan simply was not there. The
  fixtures document this exact trap for scratch repos; it bites the real one
  the same way. (fixed — `mkdir -p` before the write, and the plan is in
  `graph lint`'s count: 1 plan)
- r4: verifier round owed and NOT run — standing instruction.

## Blockers

None.
