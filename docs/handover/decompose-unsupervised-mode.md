---
workstream: decompose-unsupervised-mode
status: done
branch: claude/current-state-review-oxfb7f
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_011LSGxqQsZyuMYSqxa3jVT5
agent: opus
updated: 2026-09-02
next: Nothing — the plans are filed; the queue takes it from here
---

## Goal

`docs/product/unsupervised-mode.md` has no open plan serving it, so the queue
ranks it above everything: planning outranks executing, and a requirement
nobody has decomposed is the top of the queue. Check every `Satisfied when`
bullet against the tree, and file plans for what is actually left — no more.

Decomposition is the work — step 2 says so, and it is what an unplanned
requirement at the top of the queue asks for. (It is not the exception step 2
names for planless work; that one is a copy or sync task.)

## Decisions

- **Checked, not assumed.** Every bullet was read against the code that would
  make it true, not against the annotation beside it. That is what turned up
  the misplaced annotation.
- **The accounting, by name rather than by count.** Thirteen bullets. Ten are
  done and have an artifact behind them. One — an unsupervised session at the
  empty queue writes plans — is measured once with three caveats its own
  annotation records, and the endurance run answers all three. **Two are
  open**, and each gets a plan:
  - *Started once, the fleet keeps going for hours* — never measured; three
    runs, three different walls. `unsupervised-endurance`.
  - *A plan recorded with no goal open does NOT restart the fleet* — the
    second clause of its bullet, and nothing implements it.
    `goal-reached-outranks-a-recorded-plan`.
- **The second one was found by the verifier and reproduced before it was
  believed.** The first draft of this decomposition counted that bullet done
  because its first clause is implemented and linted. A bullet with two
  clauses needs both checked.

## Rejected

- **A plan for the `advances:` gap.** `lint_plan_advances` skips any plan
  whose `requirement:` is `none`, so a plan generated while a goal is open
  can name no bullet and still lint green — which looks like a hole in the
  bullet that requires one. It is not a defect: recording is always allowed
  and a recorded plan legitimately serves no requirement, so the check would
  have to tell recording from generating, which is a fact about the
  session's state and not about the file. The code already says this in the
  comment above the function. Left alone.
- **A plan for delete-on-satisfied.** The terminus is written where sessions
  read it (`.agents/docs/product/README.md`: satisfied = the last plan's
  pull request deletes the requirement file) and the machinery downstream of
  it is tested — `drain` prints GOAL REACHED on zero open requirements, with
  cases. What is missing is an exercise of it, and that arrives when this
  requirement is finished rather than as work of its own.

## Review

Depth is opus-adversarial, plus a verifier that did not write the diff. The
verifier confirmed the annotation was moved byte-for-byte verbatim and that
both `advances:` fragments match a real bullet line, then found twelve
defects. It also refuted the first draft's headline claim, which is the
finding of the round.

- r1 (verifier): **a bullet counted done is broken, and "eleven of thirteen"
  was wrong.** `cmd_drain` returns on the first free plan, and the goal check
  sits after that early return, so it is reached only when the queue is
  already empty — and a recorded plan is a free plan. Reproduced here
  independently before acting on it, on a scratch clone with no
  `docs/product/` and one plan carrying `requirement: none`:
  `JOHARNESS_MODE=unsupervised ./joharness.sh drain` answers
  `next: docs/plans/recorded-note.md`; delete that plan from the same tree
  and it answers `GOAL REACHED`. So the recorded note is the only thing
  keeping the fleet alive, which is the circularity the bullet closes.
  (fixed — filed as `goal-reached-outranks-a-recorded-plan`, and the
  accounting in this file is now by name rather than by count)
- r2 (verifier): **the endurance plan's central premise was false after its
  own merge.** It said `docs/plans/` holding this plan alone means a fleet
  reaches the generate-work edge. One free plan is not the edge: the fleet
  claims the endurance plan itself, reads BEFORE YOU START, and stops to ask
  — which that plan's own Scope calls a finding. (fixed — the plan now says
  the driving session claims it by pushing a workstream file before spawning
  anything, and the drain output that proves the point is quoted with the
  command and the date)
- r3 (verifier): "A2 used `authority` unprompted" is false — its prompt told
  it to run it. What was unprompted was A2 writing the verdict into its
  workstream file. The word had been moved onto the wrong verb, which
  upgrades the evidence for the mechanism. (fixed)
- r4 (verifier): "the second attempt's Acceptance required reverting the
  mode" names an Acceptance that does not exist — attempt two ran on a direct
  human instruction with no plan file. The claim traces to a comment in
  `joharness.conf` that was already wrong. (fixed — recorded as a precedent
  the plan is now setting, not an inherited rule)
- r5 (verifier): the rewrite dropped the one trap naming the confound the
  requirement itself records twice — report the goal's SIZE beside the
  wall-clock, or the number reads as endurance when it is queue depth — and
  dropped "do not count a fleet that kept going because a human answered
  something". (fixed — both restored, the first as Scope because it is a
  thing to record rather than a thing to avoid)
- r6 (verifier): `scope:` named `docs/product` while the Acceptance requires
  `joharness.conf` twice. (fixed)
- r7 (verifier): **the cost argument put to the human was unsound for this
  run.** Issue #165 was answered with "the goal bounds it", but the bullet
  this run measures is one of the two open bullets, so the goal cannot be
  reached while the run is what would reach it. The only reachable stop is a
  dry sweep. (fixed — the plan says so in its own words and tells the run to
  put the sweep output to the human instead of the goal-bound estimate)
- r8 (verifier): the note explaining the annotation move said the bullet it
  left had no evidence. It has a gate and four cases
  (`joharness.sh:lint_requirement_writes`,
  `.agents/harness/selftest/review.sh`). (fixed)
- r9 (verifier): this file said "done and tested" of a bullet the new plan
  simultaneously described as carrying three open caveats, and never named
  which two it counted open — so the count could not be checked against
  anything. (fixed — the accounting is by name now)
- r10 (verifier): four internal pointers a literal reader follows wrongly —
  a "format to match" pointing at a table without those columns, a "third
  row" that is the first row, "for a day" where the requirement says "same
  day", and a measured claim carrying a date and no command. (fixed)
- r11 (verifier): this file claimed decomposition is "the one kind of work
  that starts without a plan", while step 2 says the copy-or-sync task is
  the one. (fixed)
- r12 (verifier): the in-flight edge was never dispositioned. Step 2 puts it
  above the queue and this file did not say it had been looked at.
  (fixed — dispositioned in Blockers below and flagged on issue #167)

## Blockers

None for the decomposition. The plans it files are gated differently:
`goal-reached-outranks-a-recorded-plan` is ordinary sonnet work anyone can
take; `unsupervised-endurance` is gated on a human twice, because spawning
sessions spends money and the heartbeat that would keep a fleet alive across
generations is an operator action.

**The in-flight edge, dispositioned.** The hook leads with
`origin/claude/pr-review-cloud-setup-operator-l3lgge` at review, stale 12
days. There is nothing to finish: the pull request it names (#6) has been
closed unmerged since 2026-08-21, the branch is 270 behind `main`, and its
session is archived. Its workstream blob is byte-identical to
`origin/claude/multi-agent-orchestration-pr-jyli0w`'s — the same dead
session pushed both — and that sibling is already listed on issue #167 as
salvaged and safe to delete. Flagged there rather than finished, because
deleting a branch is a human's hand.

## Where to look

- `docs/product/unsupervised-mode.md` — `## Satisfied when`, thirteen
  bullets.
- `.agents/docs/unsupervised.md` — the heartbeat, and why the fleet is short
  without one.
