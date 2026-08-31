---
workstream: unsupervised-stop-condition
status: done
branch: claude/unsupervised-stop-condition
pr: none
plan: docs/plans/unsupervised-stop-condition.md
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Retire this file and the plan, open the pull request, merge.
---

## Goal

`sources` counted one of the stop condition's four parts. Make it state all
four, each with its own verdict, and never let an uncountable part read as
satisfied.

## Decisions

- **Two parts are the caller's, because this command cannot count them.**
  There is no `gh` on the runner and nothing in the harness reaches GitHub,
  and git cannot tell an open pull request from a closed one — the same bytes,
  which is what PR 151 corrected in the handover hook. And "two consecutive
  sweeps" is a fact about a previous run, which a harness that counts from git
  at read time and stores nothing does not hold. So `--open-prs <n>` and
  `--prev-dry`, supplied by the session that ran the previous sweep and can
  reach GitHub.
- **Their absence is CANNOT TELL, never STOP.** A verdict that read
  unreachable as satisfied would let a fleet stop on a fact nobody checked.
- **They are flags rather than something derived, so STOP stays REACHABLE.**
  A part that can never be satisfied makes the verdict unreachable — the same
  defect as `docs/research/unmarked-detector-unreachable.md` found in the
  unmarked detector the same day, wearing the opposite sign. Building the
  second one hours after documenting the first would have been the worse
  mistake.
- **DO NOT STOP outranks CANNOT TELL.** A known-false part settles it, and
  "cannot tell" over a non-empty queue would send a session looking for flags
  it does not need.
- **A missing queue hook is CANNOT COUNT, not an empty queue.** See r2.
- **`sources` still exits 0 in every case.** It counts and does not act; the
  banner says so and the existing cases pin it.

## Rejected

- **A state file for the previous sweep.** It would be the first stored state
  in the codebase, and the caller already knows — it ran the previous sweep.
- **Deriving open pull requests from git.** Unmerged branch plus a `pr:`
  field is exactly the inference PR 151 removed from the hook, and PR 10 is
  the standing counter-example: closed nine days, indistinguishable in git.

## Review

Round 1, opus, self, with `mutate` on every branch.

- r1: **the fixture had no `queue-context.sh` in it**, so `drain_hook`
  returned silence and "an empty queue counts as empty" passed because
  nothing was read. Found when the opposite case — a plan IS in the queue —
  failed against a hook that had never run. (fixed — the real hook is copied
  into the fixture, and a `refute` now pins that the yes is a read queue and
  not a missing one)
- r2: that vacuous case was also a real defect in the code. `drain_hook`
  exits 0 with no output for an absent or non-executable hook, and reading
  that as "empty" reports the strongest fact there is — nothing left to do —
  from no evidence at all. Absent is not empty, the same way unreachable is
  not zero. (fixed — CANNOT COUNT, and `swwork`, which genuinely lacks the
  hook, pins it; mutating the guard to `if true` reds both cases)
- r3: the fixture also had **no origin**, and the queue hook reads
  `origin/main` rather than the worktree — so the planted plan was invisible
  whatever the code did. (fixed — a bare origin and a push, and the case now
  distinguishes)
- r4: `swwork` cannot reach the STOP path at all: it carries a merged edge
  with an unmarked finding, and a finding lives inside a merged commit that
  nothing can edit. My own research from the same day, biting my own fixture.
  (fixed — the STOP cases build their own repo, and a case asserts that
  fixture really is dry, or everything below it would be unreachable rather
  than passing)
- r5: my first mutation of `queue_empty=1` was `queue_empty=1; :`, which
  changes nothing. The tool said NOTHING REDDED and was right about the
  mutation, not about the cases. A test that fails to red is a hypothesis
  about the test AND the mutation — the same lesson PR 153 recorded, made
  twice now. (fixed — `queue_empty=0` reds five cases)
- r6: verifier round owed and NOT run — standing instruction, seventeenth
  consecutive edge.

## Verification

- `mutate joharness.sh 3519` (STOP verdict) → reds 2
- `mutate joharness.sh 3486` (`queue_empty=0`) → reds 5
- `mutate joharness.sh 3480` (`if true`, the hook guard) → reds 2
- `ci: pass`; `verify` 6 passed, 0 failed; selftest **1080 passed, 0 failed**

## Blockers

None.
