---
workstream: selftest-env-isolation
status: review
branch: claude/start-loop-b148yi
pr: 72
plan: none
session: https://claude.ai/code/session_018e9SZFRciB3FXwrwUzLQJs
agent: opus
updated: 2026-08-25
next: Delete this file as the last commit before merging, then merge PR 72 per Loop step 7
---

## Goal

What is left of this session after losing two races. It claimed
`docs/plans/finish-gate-enforced.md`; PR69 merged the same plan first. It then
salvaged a selftest environment leak found while proving that work; PR71 merged
the same fix first. What ships is only what neither of them has:

- `JOHARNESS_MODE` and `JOHARNESS_MODE_FILE` steer the suite exactly the way
  `CLAUDE_PROJECT_DIR` did. PR71 closed one knob and left these two.
- `docs/plans/tree-vs-diff-rule.md` — five merged edges have each fixed the
  same defect class locally and none wrote the rule down.

## Decisions

- **Both duplicates were dropped, not merged.** In each race the merged version
  is as good or better: PR69's gate bites at two strengths (report at the edge,
  fail at `status: done`) where mine failed at the edge and I had recorded that
  tension as a finding I was choosing to live with; PR71's fix carries a
  structural assertion mine lacked. Both times `git checkout origin/main --`
  on every overlapping file, so this branch's diff contains no second
  implementation of anything.
- **The mode knobs are the same finding, not a new one.** PR71's argument is
  that a session may reasonably type `CLAUDE_PROJECT_DIR=$PWD ./joharness.sh
  ci`. `JOHARNESS_MODE` is documented in `joharness.conf` and in the
  entrypoint's own help, so it has a stronger claim to being typed, not a
  weaker one.
- **Both halves of PR71's guard, copied deliberately.** The runtime assertion
  is vacuous under a caller that exported nothing — every CI run — so the
  structural `grep -qx` is what actually carries it there. Their reasoning,
  their shape.

## Rejected

- **Pushing either duplicate as "a second opinion".** Two implementations of
  one gate is the defect the gate exists to prevent, one level up.
- **Rewriting the unset block as a loop over a knob list.** It would read
  better and lose the per-knob comment that carries the measured numbers,
  which is the only reason anyone believes the line is load-bearing.
- **Adding `JOHARNESS_CANONICAL` and `JOHARNESS_FEEDBACK_EDGES` while here.**
  Neither failed a case when exported. Widening an unset list on suspicion is
  how it grows past the point anyone reads it.

## Review

Opus tier, adversarial. Two earlier review records (11 findings against the
finish gate, 4 against the first salvage) died with the work they covered.
These are against what this branch actually ships.

- r1: correctness — measured on `origin/main` at f140536, with PR71's fix
  already in place: `JOHARNESS_MODE=unsupervised` gives 440 passed / 10
  failed, `JOHARNESS_MODE_FILE=<path>` gives 448 / 2, against 450 / 0 with
  neither set. PR71 closed the class for one knob; these two were left.
  (fixed: same block, same shape. After: 452 / 0 identical across all four
  environments — bare, each knob alone, and all three exported together.)
- r2: a runtime-only assertion would be green in CI whatever the file says,
  because CI exports none of these. (fixed: both halves, matching PR71 —
  the value is empty in this process AND the unset line is still in the file.
  Proven red by deleting the line: both new assertions fail and the 10
  original mode failures come back, 12 total.)
- r3: the marker is the reason this is not cosmetic. A poisoned run wrote
  `unsupervised` into the real `.git/joharness-mode`, which is the autonomy
  switch — that checkout then reads as unsupervised for every later session,
  silently. Verified the fixed suite writes nothing under all three knobs.
  (no change needed.)
- r4: scope — this branch's diff against `main` was checked file by file after
  each of the two reconciliations. `.agents/harness/selftest.sh` differs from
  `origin/main` only by this fix; `joharness.sh` and `.agents/harness/AGENTS.md`
  are byte-identical. (verified, no change needed.)
- r5: losing two races in one session is itself the finding worth keeping. The
  session-start hook showed the plan free and no rival branch; both rivals
  claimed and pushed inside the same hour. Nothing here fixes that — recorded
  because the next session to lose a race should know it is a known shape and
  that the answer is to reconcile down to what is additive, not to argue for
  the duplicate. (no change needed.)

## Blockers

None.

## Where to look

- `.agents/harness/selftest.sh` — the `unset` block at the top, both halves of
  its guard. Every knob that steers a fixture belongs there, and the comments
  carry the counted numbers that say why.
- `docs/plans/tree-vs-diff-rule.md` — the five edges, and why the rule is worth
  writing once instead of rediscovering per session.
