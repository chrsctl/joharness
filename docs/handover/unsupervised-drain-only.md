---
workstream: unsupervised-drain-only
status: in-progress
branch: claude/unsupervised-slim-down-nqfie4
pr: none
plan: unsupervised-drain-only
issue: none
session: https://claude.ai/code/session_017oZ8o5q2YRzjFT1eTnx4Cs
agent: opus
updated: 2026-09-03
next: Retire this file and the plan, open the pull request, merge under step 7.
---

## Goal

Direct ask 2026-09-03: "Answer questions and solve". The questions are the
two the review of PR 198 left for the human; the solve is the queue's one
plan, `docs/plans/unsupervised-drain-only.md`, corrected in place three
times and never built. Building it now ends the staling.

## Decisions

- Q1 answered — the switch stays. After this plan the mode is: exit
  instead of ask at the edge, the spawn line, the requirement-writes gate,
  the protocol-text guard, the banner. Thin, but ONE distinction — is a
  human present — and every piece is something a heartbeat-fired session
  needs and an attended one must not have. The requirement's Goal says so
  in this plan's rewrite; a mode that cannot state its one difference is
  the one to delete, and this one can.
- Q2 answered — the marking stays scope-based. The "incentive to
  under-declare" buys nothing: `handover-guard.sh` blocks the stop on the
  diff, so a plan that hides its protocol path is not made
  unattended-safe, it is made to waste a session (attempt two). Honest
  declaration costs a plan the fleet could never finish. One sentence to
  that effect goes in `.agents/docs/plans/README.md`'s `scope` paragraph,
  which this plan already edits; scope widened by one sentence, recorded
  here.
- Implemented whole, not sliced. Slicing was the answer to a plan that
  waits in the queue while `main` moves; a plan being built now does not
  wait. Sliced, each piece would carry its own review round and its own
  reconcile against the others.
- Tier: the plan says opus; this session is above it. Escalation is
  allowed, downgrade never. Review depth stays the opus recipe.
- Deviations from the plan as written, each a place the plan's own split
  (PR 198) or its literal reading would have produced a wrong tree:
  - `queue-context-edge.sh`: the plan says three lines of `eq_same` go —
    the trap assertion, the strip, the GOAL REACHED refute. Only the refute
    goes. The `trap` STAYS (decision 3 keeps it), so the assertion and the
    strip that read it stay too; the plan's edge bullet was written before
    the split and never re-read after it. The two divergence cases ("stops
    short of the tail", "keeps its tail") stay for the same reason: the
    hook's unsupervised edge arm they pin is kept.
  - `drain.sh`: the plan lists twelve GOAL REACHED cases by name; the file
    held six more under "a plan recorded with no goal open" and "the stop
    must still name work", all pinning the goal bound. Deleted by the
    plan's rule (every case pinning GOAL REACHED), not by its list.
  - The supervised DRAINED block's second line is CHANGED, against the
    plan's "unchanged": it read "It does NOT invent work; that is
    unsupervised mode" — after this change no mode invents work, so the
    sentence became a lie in the most-read status line. Now "neither does
    unsupervised — that mode exits here instead of asking". The first line
    and the "It does NOT invent work" pin are byte-identical.
  - The unsupervised exit line carries the GitHub-issues pointer the old
    stops carried. A hook cannot read GitHub; dropping the pointer at a
    stop is how a session concludes there is nothing to do over an open
    issue — the defect `drain_goal_reached`'s own comment recorded.
  - Fixture kept: the `mkdir -p docs/plans` after the emptied queue. The
    plan's stretch deletion would have taken it with the goal cases, and
    every later `cat >` into `docs/plans` fails silently without it.
- Session merges its own pull request (step 7). The plan is ratified —
  PR 197 put it in the queue and the human merged that — so the earlier
  "product direction, human merges" reasoning no longer applies to the
  implementation of it.

## Rejected

- Slicing into three pull requests, one per decision. See Decisions.
- Deleting the mode outright (Q1 the other way). Not asked for, and the
  one-distinction argument above holds.

## Review

Measured on the branch, 2026-09-03, `wc -l joharness.sh` 5251 (from 5770),
`cat .agents/harness/selftest/*.sh | wc -l` 9512 over 44 files (from 9872
over 45). Suite: `JOHARNESS_SELFTEST=always ./joharness.sh ci` 1221
passed, 0 failed, both modes; `./joharness.sh verify` 6 passed, 0 failed.
Step 5 revert, reproducible: `git checkout origin/main -- joharness.sh`
then `bash .agents/harness/selftest.sh` gives 1202 passed, 19 failed — the
DRAINED exit cases, the spawn-line cases, the banner case — and
`git checkout HEAD -- joharness.sh` restores it (2026-09-03). An earlier
draft of this line said ten, from a filtered grep of a `git stash` that a
clean tree cannot re-run; r5 below.

Round 1, verifier at opus, 17 findings:

- r1: (verifier) the hook's EXIT trap — deliberately the last line every
  unsupervised session reads — still said "take, fan out, generate, or
  stop"; the acceptance grep matched `generate work`, not `generate`.
  (fixed: "take, fan out, or exit", and the two comments echoing it; the
  plan's "queue-context.sh: NOTHING" protected the marking, not a stale
  word)
- r2: (verifier) `lint_finding_markers`'s live `ci` text pointed a session
  at `./joharness.sh sources` and at a Constraints bullet this diff
  deleted; its comment was reworded, its printf was not. (fixed)
- r3: (verifier) `drain_goals`' five-line docstring survived the function
  and read as `drain_free_others`'s — the cut started at the function
  line. (fixed)
- r4: (verifier) two comments in `cmd_drain` still stated the goal bound
  and the trigger. (fixed)
- r5: (verifier) "the suite reds ten cases" was wrong — 19 — and the
  `git stash` command beside it stashes nothing on a clean tree. (fixed:
  re-taken with `git checkout origin/main -- joharness.sh`, 19 counted)
- r6: (verifier) the `drain` row in `.agents/docs/unsupervised.md` said
  the modes differ by one line; with marked plans present they differ by
  the NOT YOURS block and the edge-first line too. (fixed: row names all
  of them)
- r7: (verifier) AGENTS.md's `/drain` sentence answered "queue still holds
  work after the merge?" with "takes ONE item" — licensing the second item
  decision 2 forbids. (fixed: the next item is the next session's)
- r8: (verifier) the `drain` perf budget's stated reason — a drain loop
  reads it between items — is no longer true. (fixed: it is the first
  thing every heartbeat-fired session reads)
- r9: (verifier) two supervised cases went beyond the plan's one
  authorised deletion, and with them the only `requirement: none` fixture
  — the hook's `none` arm had no pin. (fixed: a case in both modes, the
  plan serving no requirement is next like any other)
- r10: (verifier) seven comments in kept tests still named `sources`, the
  goal bound or the goal stop. (fixed, each)
- r11: (verifier) "Hooks report; `drain` orders." survived though the plan
  said delete it with the two-stops section. (wontfix — the sentence is
  still true: `drain` orders the spawn line and the exit; the plan bundled
  it with text that stopped being true)
- r12: (verifier) selftest line count 9513; the command gives 9512.
  (fixed)
- r13: (verifier) supervised `ci` output changed — the `== plan
  provenance` stage is gone — which the plan authorised but its own Trap
  ("every deletion sits inside an unsupervised arm") denied. (no change
  needed to the code; recorded here as the second supervised-visible
  change, beside the DRAINED line)
- r14: (verifier) `perf_shape` still wrote `advances:` into its fixture
  plans, a field nothing reads. (fixed)
- r15: (verifier) `drain_free_others` reported an unrecognised tier as
  `sonnet`. (fixed: echoes the declared value; the row loop already
  defaults an absent one)
- r16: (verifier) `drain.md`'s stall numbers sat under a claim they no
  longer support. (fixed: they argue for the heartbeat, not a second item)
- r17: (verifier) two lines over the wrap width. (fixed)

## Blockers

None.

## Where to look

- `docs/plans/unsupervised-drain-only.md` — the spec, decision by decision.
  Its own Traps: every symbol is a hypothesis, `grep -n` before deleting.
