---
plan: finish-gate-enforced
urgency: urgent
agent: sonnet
effort: high
needs: none
requirement: none
scope: joharness.sh, .agents/harness/selftest.sh, .agents/harness/AGENTS.md
---

## Goal

`./joharness.sh finish` is a correct gate nobody has to run, and step 7
keeps not happening. Measured on `main` 2026-08-25:

    docs/handover/joharness-minify-optimize.md
      added 2026-08-24 (e0300ca), merges to main since: 22

Twenty-two merges passed over a finished workstream file that every
session-start hook announces and every later session reads as a live
claim. The gate already knows: run against the branch that merged as PR
63 it prints

    workstream files this merge would ADD to origin/main
      none — this branch retires what it claimed
    1 already on origin/main — not this merge, not this session

So Detect works, Record works, and Generalize already happened — the Loop
step 7 wording was strengthened after a consumer measured 23 stale files.
It recurred anyway, because `cmd_ci` never calls `cmd_finish`. That is
stage 4 of `.agents/docs/feedback.md` missing, and recurrence is the
score that document keeps.

## Scope

- `joharness.sh` — `cmd_ci` runs the finish gate at the EDGE only, the
  same condition `JOHARNESS_REVIEW=on` already uses (pull request open, or
  workstream status review/done). Mid-build it stays quiet: a branch that
  has not finished has no ritual to have skipped.
- The gate fails `ci` on workstream files this merge would ADD. It must
  NOT fail on files already on the base branch — those are another
  session's, `cleanup` names them, and failing there makes every branch
  red for somebody else's omission, which is how a gate teaches sessions
  to route around it.
- `.agents/harness/selftest.sh` — a branch adding its own workstream file
  at the edge fails; the same branch after the ritual passes; a branch
  that merely inherited a stale file passes; a mid-build branch passes
  with its file still present.
- `.agents/harness/AGENTS.md` — step 7 says the gate is enforced, not
  merely available.

## Out of scope

- **Deleting other sessions' stale files.** `cleanup --apply` exists and
  the attribution is deliberate. This plan stops NEW ones.
- **Guessing whether a plan file is done.** `cmd_finish` already refuses
  to, and says why: "a gate that guesses at one is a gate the next session
  learns to ignore."
- **Making `finish` mandatory mid-build.** A gate that fires before there
  is anything to gate is noise, and noise is what got ignored here.

## Acceptance

Counted, not written.

- A fixture branch with an open pull request and its own workstream file
  present: `ci` FAILS and names the file. Paste it.
- The same branch after deleting the file: `ci: pass`.
- A fixture branch carrying only an INHERITED stale file: `ci: pass`, and
  the run still names it as cleanup's business.
- A mid-build branch (no pull request, status in-progress) with its file
  present: `ci: pass`, output byte-identical to before this change.
- `./joharness.sh ci` — `ci: pass`. `./joharness.sh verify` — 7 passed,
  0 failed (this diff touches `joharness.sh` and `.agents/harness/`).
- Prove each new selftest goes red.

## Where to look

- `joharness.sh:cmd_finish` — the gate, already correct.
- `joharness.sh:cmd_ci` — where `JOHARNESS_REVIEW=on` gates at the edge;
  copy that edge condition rather than inventing a second one.
- `.agents/docs/feedback.md` — the four stages, and why only stage 4
  changes an outcome.

## Traps

- A gate that fails for another session's omission gets routed around.
  Own files only.
- `ci` runs in CI, where the base ref may be shallow. `decide_ref` already
  refuses rather than guessing; keep that path.
