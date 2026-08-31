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
deleted and the fleet winds down. A loop whose "done" cannot be stated does
not converge — it produces plausible work forever, and under full-loop
autonomy that work merges without anyone reading it.

## Satisfied when

- `joharness.conf` carries a mode, default supervised, and a session can
  see which mode it is in from session-start output alone.
- Supervised behaviour is byte-identical to today's at every point the
  mode is read. A supervised session cannot tell the feature shipped.
- An unsupervised session that finds the queue empty writes new plan files
  and opens a pull request for them, rather than stopping to ask.
  **Measured 2026-08-31** (`edge-generates-work`, PR 163): with every plan
  claimed or blocked — `Edge reached: no free plan` — `drain` deferred to the
  source sweep instead of stopping, the sweep named two sources, and the
  session wrote `docs/plans/selftest-mode-marker-leak.md` from one of them
  and opened this pull request for it. The plan is not filler: it reproduces
  a real red (`mode unsupervised` → 1105 passed, 1 failed; `mode default` →
  1106, 0) and its fix direction was verified before filing.

  What that run did NOT show. **Self-measurement**: the session that
  generated the work is the one measuring it, and it knew the bullet — an
  independent session would be better evidence. **One cycle**, not that it
  keeps generating. **The second source produced no plan**: the unmarked
  finding is the verifier gap, whose disposition is a human's, so it was
  recorded rather than turned into a plan nobody could take — a source that
  cannot become work is worth knowing about. And the flip used the
  **session-local marker**, not `joharness.conf`, so "the repo is set to
  unsupervised" was never literally true; what was true is that the session
  read unsupervised, which is what the bullet is about.
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
- No unsupervised session writes a requirement. The goal is the human's to
  set, and a fleet that writes its own finish line has none.
  **Partly measured, 2026-08-30** (`fanout-live-run`): two sessions spawned per
  wave-1 plan both ran the full Loop and merged their own pull requests
  unattended, 53 minutes end to end, no collision and one reconcile. What that
  run did NOT show is the "for hours" or the empty-queue trigger: the fleet was
  bounded to one plan each and stopped when the work ran out, and the repo mode
  was not flipped. Endurance and work-generation remain unmeasured.
- The mode has a reachable end: the source sweep goes dry. Every detector
  zero on two consecutive sweeps, queue empty, no open pull request. There
  an unsupervised session stops and says so — the one place the mode asks.
  **Reachable is now literal**: `./joharness.sh sources` states all four
  parts with a verdict (PR 160), and the detector that could never be zero is
  bounded by a baseline (PR 161). The two parts this harness cannot count —
  no `gh` on the runner, and a previous run is not a thing git holds — are
  `--open-prs <n>` and `--prev-dry`, and their ABSENCE reads `CANNOT TELL`,
  never `STOP`.
  Empty QUEUE still triggers work WHILE A GOAL IS OPEN; empty SWEEP stops
  it, and so does a satisfied goal. Ratified 2026-08-25 by the requester,
  amending this file's earlier reading that the mode had no stopping point
  at all. The goal bound above is the second of those two stops and was
  directed the same day; it reached `main` on 2026-08-31 (PR 169).
- No unsupervised session commits a change to protocol text — the paths
  `joharness.sh:protocol_paths` names, whatever they are at the time. Stated
  as one tree, this line is what a session reads to conclude everything else
  is fair game; that reading is #114.

## Constraints

- Protocol text governing a session is off limits to that session while it
  runs unattended, wherever that text lives. A session may not rewrite the
  rules it is being judged by; that edit is supervised work, always. The
  rule is the role, not the path — `joharness.sh:protocol_paths` carries its
  current mechanical expression — read it there rather than here, because a
  list restated in prose is a second copy and this one was wrong within an
  hour of being written. The session-start banner and
  `.agents/harness/handover-guard.sh` both read that one list, and `selftest.sh` fails when a tree shipping agent-instruction
  text is missing from it. Stated as a path alone this cost issue #114:
  `.claude/agents/verifier.md` became mandatory Loop step 5 protocol outside
  the one named prefix, and nothing detected an edit to the independent
  reader the merge gate leans on. Sandbox configuration (`.agents/env/`) is
  not protocol text and stays outside — a layer does not govern behavior.
  The list covers its own machinery: the entrypoint that holds it, and the
  settings file wiring the hook that reads it. A boundary excluding either is
  switched off from inside, and the old hardcoded one was self-protecting
  only by accident of where it lived.
- The exception to "not invent work" is written as an exception, gated on
  the mode, at the rule itself. A rule that quietly stops meaning what it
  says is worse than no rule.
- Unsupervised merging uses the step 7 conditions unchanged — green
  checks, zero behind main, review recorded, no open human thread. The
  mode removes the human, never the gate.
- Every source an unsupervised session may draw work from carries a
  detector command that prints a count. No detector, not a source. An
  uncountable source never reaches zero, so a mode that draws on one can
  never terminate. Measured 2026-08-25 against the closed list in
  `unsupervised-edge-work`, three of its five sources had a command that
  returns a number and two did not — "a documented rule with no test" and
  "drift between an instruction file and the code". Those two are judgment
  calls, and a literal reader always finds one more.
- A finding that unsupervised-generated work itself introduced is not a
  source finding. Without this the mode manufactures its own backlog and
  the sweep never dries.

  **The mechanism is a BASELINE, not the dedupe this bullet first
  prescribed.** Ratified 2026-08-31 by the requester, who delegated the
  decision after the research below. Dedupe against citing plans cannot work:
  a finding lives in a `## Review` section of a workstream file that step 7
  deletes, so it survives only inside a merged commit that nothing can edit,
  and **62 of the 155 unmarked findings carry no `rN:` id** — no citation
  could ever name them. The count was therefore monotonically non-decreasing
  and could never be zero, so the sweep could never be dry and the fleet
  could never stop. That is this file's own "an uncountable source never
  reaches zero" reached from the countable side. Working:
  `docs/research/unmarked-detector-unreachable.md`, answered in PR 161.

  The source is now measured from `joharness.sh:FB_SINCE`, a literal commit
  in a reviewed diff rather than state a session can write. Findings merged
  at or before it are history, not the mode's backlog — which is this
  bullet's own scope. A repo that has no such commit, a synced consumer among
  them, counts ALL of its history and says so: never blind, and never zero.
- Autonomy is bounded by a goal, not by a counter. Unsupervised mode is live
  only while at least one requirement is open; the requirement's `Satisfied
  when` is the finish line, and delete-on-satisfied is the terminus. This is
  the stopping condition, added 2026-08-25 at the requester's direction, and
  it replaces "an empty queue is a trigger for work, not a stopping point"
  from the first draft.

  **Provenance, and why it took six days.** The wording above is
  `origin/claude/unsupervised-goal`'s, PORTED rather than merged: that branch
  is 515 behind and still spells the boundary "under `.agents/harness/`",
  which `main` replaced with the role-based `protocol_paths` list (issue
  #114, PR #118). Merging it would have regressed the boundary work. Its
  session archived before it opened a pull request, and no session re-filed
  it because a requirement is the human's — the branch's own reasoning.
  Adopted 2026-08-31 on the requester's delegation ("make decisions"),
  issue #166.

- Deliberately NOT constrained, decided 2026-08-24 by the requester after
  being offered each one: no cap on work per run, no halt when main is
  red, no ban on sessions spawning sessions. A decomposing session must
  not add these back on its own judgment — propose them to the human
  instead.
