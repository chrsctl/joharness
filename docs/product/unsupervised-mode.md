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

Work it generates has to be work someone wanted. So autonomy is bounded by
a goal rather than by a clock or a counter: it runs toward an open
requirement, every generated plan names the requirement and the bullet it
advances, and when the last bullet reads true the requirement file is
deleted and the fleet winds down. A loop whose "done" cannot be stated
does not converge — it produces plausible work forever, and under full-loop
autonomy that work merges without anyone reading it.

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
- Started once, the fleet keeps going for hours with no human turn, for as
  long as a goal is open.
- The goal is an open requirement in `docs/product/`. An unsupervised
  session at the queue edge with no open requirement stops and asks,
  exactly as a supervised one does, and says the goal is reached rather
  than going quiet.
- Every plan an unsupervised session generates names the requirement it
  serves and the `Satisfied when` bullet it advances. A plan that serves no
  open requirement is not generated.
- When every `Satisfied when` bullet of a requirement reads true, the next
  unsupervised session deletes the requirement file rather than inventing
  more work against it. Reaching the goal is the terminal action, not a
  state to keep working past.
- No unsupervised session commits a change under `.agents/harness/`.
- No unsupervised session writes a requirement. The goal is the human's to
  set, and a fleet that writes its own finish line has none.

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
- Autonomy is bounded by a goal, not by a counter. Unsupervised mode is
  live only while at least one requirement is open; the requirement's
  `Satisfied when` is the finish line, and delete-on-satisfied is the
  terminus. This is the stopping condition, added 2026-08-25 at the
  requester's direction, and it replaces "an empty queue is a trigger for
  work, not a stopping point" from the first draft.
- Deliberately NOT constrained, decided 2026-08-24 by the requester after
  being offered each one: no cap on work per run, no halt when main is
  red, no ban on sessions spawning sessions. These stay declined — the
  goal bound above is what answers the runaway risk they were offered
  for. A decomposing session must not add the three back on its own
  judgment; propose them to the human instead.
