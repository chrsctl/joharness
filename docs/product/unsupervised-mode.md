---
requirement: unsupervised-mode
priority: normal
---

## Goal

Joharness should keep working for hours without a human in the loop. Today
every session stops at the queue edge: with no issue, no requirement and no
free plan, `.agents/harness/AGENTS.md` step 2 says ask the human and not
invent work, so the fleet goes idle the moment the backlog drains — which
is exactly when it has capacity to spare. When the repo is set to
unsupervised, an idle session should instead generate its own work
(research the repo, write plans), run the full Loop on it including the
merge, and fan out across the free plans so several run at once. The mode
is a switch: supervised stays the default and stays exactly as it is
today.

## Satisfied when

- `joharness.conf` carries a mode, default supervised, and a session can
  see which mode it is in from session-start output alone.
- Supervised behaviour is byte-identical to today's at every point the
  mode is read. A supervised session cannot tell the feature shipped.
- An unsupervised session that finds the queue empty writes new plan files
  and opens a pull request for them, rather than stopping to ask.
- An unsupervised session runs the full Loop on a free plan, merging its
  own pull request under the step 7 conditions that already govern
  self-merge.
- Two or more free plans produce two or more sessions running at once,
  one per plan, using the wave partition the queue hook already computes.
- Started once, the fleet keeps going for hours with no human turn — an
  empty queue is a trigger for work, not a stopping point.
- No unsupervised session commits a change under `.agents/harness/`.

## Constraints

- `.agents/harness/` is off limits to unsupervised sessions. The harness
  cannot rewrite the protocol that governs it while unattended; that edit
  is supervised work, always.
- The exception to "not invent work" is written as an exception, gated on
  the mode, at the rule itself. A rule that quietly stops meaning what it
  says is worse than no rule.
- Unsupervised merging uses the step 7 conditions unchanged — green
  checks, zero behind main, review recorded, no open human thread. The
  mode removes the human, never the gate.
- Deliberately NOT constrained, decided 2026-08-24 by the requester after
  being offered each one: no cap on work per run, no halt when main is
  red, no ban on sessions spawning sessions. A decomposing session must
  not add these back on its own judgment — propose them to the human
  instead.
