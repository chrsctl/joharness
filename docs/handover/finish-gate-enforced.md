---
workstream: finish-gate-enforced
status: done
branch: claude/finish-gate-enforced
pr: none
plan: finish-gate-enforced
session: https://claude.ai/code/session_019c3kktaEvDBAnDv1K2i65p
agent: sonnet
updated: 2026-08-25
next: Open the pull request and merge it; plan and workstream files go with it.
---

## Goal

`./joharness.sh finish` is a correct gate `cmd_ci` never calls, so step 7
keeps not happening — `docs/handover/joharness-minify-optimize.md` has been
on `main` since 2026-08-24 through 22 merges. Plan:
`docs/plans/finish-gate-enforced.md`.

## Decisions

- **Share `cmd_finish`'s computation, never a second copy.** The gate and
  the command must agree; two implementations of "would this merge add a
  workstream file" is the drift this repo names everywhere else.
- **Edge only, via the existing `review_at_edge`.** The plan says to reuse
  the condition `JOHARNESS_REVIEW=on` already has rather than invent a
  second notion of "the edge".
- **Own files only.** Inherited stale files are reported, never red.
  A gate that fails for another session's omission is one sessions learn
  to route around — the same failure that produced this defect.
- **Always on, not behind a flag.** `JOHARNESS_REVIEW` is off by default
  because whether a review is deep enough is a judgment. Whether a branch
  still carries its own finished workstream file is not a judgment, and
  the defect being fixed is precisely that the check was optional.

## Rejected

- **Failing on inherited files too.** It would red every branch until
  somebody cleans main, which punishes the wrong session and teaches the
  gate is noise.
- **Gating the plan file's deletion.** `cmd_finish` already refuses to,
  and says why: whether a plan is done is a judgment, and a gate that
  guesses at one is a gate the next session learns to ignore.

## Review

Adversarial, separate lenses. Three findings, and the first changed the
design the plan asked for.

- r1: **The plan's own premise was wrong, and building it proved so.**
  The plan said `ci` should FAIL at the edge. Wired that way it broke the
  existing `recorded review keeps ci green`, because the two gates
  contradict: the review gate fires at the edge and needs the workstream
  file PRESENT (it reads `## Review` out of it), while a finish gate at
  the same edge needs it GONE — and step 7 puts the deletion in the pull
  request's FINAL state, so through a pull request's life the file is
  supposed to be there. Redding at the edge would red every pull request
  from open until its last commit, which is the noise this gate exists
  because sessions learned to ignore. (fixed: two strengths — reported at
  the edge, RED once the branch says `done`, which is strictly after
  review and is the session's own word. Proven by reverting to
  edge-red and watching the existing review test AND two of mine go red
  together.)
- r2: **The gate fired on the branch that built it, wrongly.** First cut
  asked `review_at_edge` over EVERY workstream file, so another session's
  inherited `joharness-minify-optimize.md` (status review) put this branch
  at an edge it was not at. (fixed: `fin_strength` reads only
  `fin_adds_at`, this branch's own files.)
- r3: **Two of my own tests passed vacuously and I nearly shipped them.**
  `write_ws inherited.md` failed with "No such file or directory" — git
  tracks no empty directory, and the cases above had left `docs/handover`
  empty — so the fixture was never written and both assertions passed
  against nothing. Found by reverting the rule they cover and watching
  them stay green. (fixed: `mkdir -p` first.) Then the repaired fixture
  failed for a second reason: it committed only to LOCAL main, while the
  gate compares against `origin/<base>`, so the "inherited" file was
  genuinely an add. (fixed: the fixture pushes.)
- r4: `an inherited file does not red the branch` does NOT go red when
  inherited files are miscounted, because at edge strength the gate
  reports either way. Its real failure mode is a gate that reds at the
  edge, which r1's revert already covers. Recorded rather than claimed as
  proven the same way.

Shared computation, never a second copy: `fin_adds_at` answers "would this
merge add a workstream file" for both `finish` and `ci`, so the command a
session runs by hand and the gate that stops the merge cannot drift.

## Blockers

None.

## Where to look

- `joharness.sh:cmd_finish` — the gate, already correct.
- `joharness.sh:cmd_ci` — the `review_on` block, the shape to copy.
- `joharness.sh:review_at_edge` — the edge test to reuse.
