---
workstream: selftest-env-isolation
status: review
branch: claude/start-loop-b148yi
pr: none
plan: none
session: https://claude.ai/code/session_018e9SZFRciB3FXwrwUzLQJs
agent: opus
updated: 2026-08-25
next: Delete this file as the last commit before the pull request opens, then merge per Loop step 7
---

## Goal

This session claimed `docs/plans/finish-gate-enforced.md` and built it. So did
another session, in the same hour, and theirs merged first as PR69. Main's
implementation is better where the two differ, so it was taken wholesale and
this branch keeps only what the race turned up that main does not have:

- `.agents/harness/selftest.sh` writes into the REAL repository when
  `CLAUDE_PROJECT_DIR` is set, which every real session sets.
- The defect class both implementations tripped over has now cost five merged
  edges and still has no rule. Seeded as `docs/plans/tree-vs-diff-rule.md`.

## Decisions

- **The duplicate was dropped, not merged.** Main's gate reaches the same
  own-files-only conclusion and resolves the edge-vs-review tension better than
  mine did: it bites at two strengths, reporting at the edge and failing only
  at `status: done`, because the review gate needs the workstream file present
  until then. My version failed at the edge and I had recorded that tension as
  a finding I was choosing to live with. Theirs is the right answer; `git
  checkout origin/main --` on all three overlapping files, so this branch's
  diff against main contains no second implementation of anything.
- **The leak is fixed here rather than filed.** It is three lines, it is in a
  file the abandoned work already had open, and a suite that silently edits the
  tree it is testing invalidates every acceptance number anyone reads off it —
  including PR69's.
- **`JOHARNESS_MODE` and `JOHARNESS_MODE_FILE` unset alongside it.** Same
  class, same block, and the mode cases are exactly the ones that failed.

## Rejected

- **Pushing the duplicate anyway as "a second opinion".** Two implementations
  of one gate is the defect the gate exists to prevent, one level up.
- **Filing the leak as a plan.** It would sit in the queue behind sixteen
  others while every `ci` run under a session's environment kept flipping
  `.git/joharness-mode` to `unsupervised`.
- **Asserting the fix by grepping the `unset` line.** That tests the text, not
  the property. The case asserts `CLAUDE_PROJECT_DIR` is actually empty inside
  the running suite, which is the thing that has to be true.

## Review

Opus tier, adversarial. The abandoned implementation's own review (11 findings)
died with it; these are against what this branch actually ships.

- r1: correctness — found while proving mid-build `ci` output unchanged, not by
  reading. The suite never unset `CLAUDE_PROJECT_DIR`, and joharness.sh
  resolves `ROOT` from it, so any case invoking the entrypoint without a
  per-call value answered about the real repository. Counted on `origin/main`
  at f2dfb94: bare shell 448 passed / 0 failed; with `CLAUDE_PROJECT_DIR`
  exported, 439 passed / 7 failed **and** `unsupervised` written into the real
  `.git/joharness-mode`, which flips that checkout's autonomy mode for every
  later session. (fixed: unset it plus the two mode knobs. After: 449 / 0
  identical in both environments, no marker written.)
- r2: the failure is invisible where the suite is written and read — a bare
  shell — and visible only under the environment sessions actually run in.
  That asymmetry is why it survived, so the fix needed a case that fails
  loudly, not a comment. (fixed: `step "suite isolation"`; proven red by
  dropping the name from the `unset` list — 8 failed, the isolation case plus
  the same 7.)
- r3: scope — `JOHARNESS_CANONICAL` and `JOHARNESS_FEEDBACK_EDGES` are also
  unlisted knobs that could steer fixtures. Not added: neither failed a case
  under this run, and widening an `unset` list on suspicion is how it grows
  past the point anyone reads it. The invariant case will catch the one that
  matters if it ever does. (no change needed.)
- r4: this branch's diff against `main` was checked file by file after the
  reconciliation — `joharness.sh`, `.agents/harness/AGENTS.md` and
  `.agents/harness/selftest.sh` are byte-identical to `origin/main` except the
  two salvage edits. No fragment of the abandoned gate ships. (verified, no
  change needed.)

## Blockers

None.

## Where to look

- `.agents/harness/selftest.sh` — the `unset` block at the top. Every case that
  calls the entrypoint without its own `CLAUDE_PROJECT_DIR` depends on it, and
  nothing else in the suite says so.
- `docs/plans/tree-vs-diff-rule.md` — the five edges, and why the rule is worth
  writing once instead of rediscovering per session.
