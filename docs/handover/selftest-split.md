---
workstream: selftest-split
status: in-progress
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: selftest-split
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Split topics 4-40 into .agents/harness/selftest/, keeping 1-3 in the runner.
---

## Goal

The queue serializes on one file. Split the selftest's topics into files a
plan can scope by name, so plans that touch different topics stop blocking
each other. A move, not a rewrite: same assertions, same order, same count.

## Decisions

- **The plan's premise numbers are stale, and the case got stronger, not
  weaker.** Recounted on `cf38699`, 2026-08-29: 3 of 5 scope-declaring plans
  name `selftest.sh` (the plan says 13 of 20 — five plans merged this
  session), but the file is **6,266 lines and 40 topics** against the plan's
  3,423 and 27. This session alone added ~450 lines to it across three
  plans. The payoff today is two plans (`cleanup-audit`, `finding-id-lint`)
  moving into wave 1; `moment-feedback-hooks` overlaps on `.agents/harness`
  and stays blocked whatever this does.
- **The in-flight trap, measured rather than assumed.** The plan says run
  this when no branch touching the file is live. One is:
  `origin/claude/backpass-usage-review-sbew6t`, 15 hours old — **26
  insertions in 4 hunks**, and the plan it claims (`unsupervised-boundary`)
  is already retired from `main`. Bounded and re-appliable, not "the merge
  conflicts are the whole diff". Proceeding, and the pull request says where
  its hunks went.
- **Topics 1-3 stay in the runner, and that is the layer rule's doing, not
  laziness.** `grep -w k8s` finds 8 lines: two in the preamble (the
  carve-out constant and the comment explaining it) and six in the k8s topic.
  The rule permits exactly ONE file under `.agents/harness/` to name a layer,
  and a second carve-out is "a red run, not a judgement call" (AGENTS.md Part
  2). Splitting them puts the layer's name in two files. So the file that
  enforces the rule and the file that benefits from it stay the same file —
  `selftest.sh` — and topic 2 sits between them, where moving it alone would
  mean interleaving a `source` between two inline topics for nothing.

## Rejected

- (nothing yet)

## Review

(no round yet)

## Blockers

None.

## Where to look

- `.agents/harness/selftest.sh:LAYER_CARVE_OUT_FILE` — why topics 1-3 stay.
- `.agents/scripts/sync-to-consumer.sh:CANONICAL_ONLY_DIRS` — the one line
  that stops every topic file shipping to every consumer.
- `joharness.sh:cmd_ci` — the literal path the runner must keep satisfying.
