---
workstream: orchestrated-beta-exit
status: in-progress
branch: claude/remove-beta-flags-p31tgj
pr: none
plan: orchestrated-beta-exit
issue: none
session: https://claude.ai/code/session_01D2wRwGfjpFu5MfRsHh6jt7
agent: opus
updated: 2026-09-11
next: Strip the 24 label sites, rewrite licences A and B to one claim, run ci + verify
---

## Goal

Requester, 2026-09-11: "There are still (beta) flags; remove". Direct human
ask against `docs/plans/orchestrated-beta-exit.md`, which is why this runs
ahead of its `needs: orchestrated-run` edge — the edge buys a number, and
the plan's real gate was always the human's answer below, not the DAG.

## Decisions

- **The gate, answered.** The plan's first Acceptance bullet is a hard stop:
  put licences A, B and C to the human as written and get one answer. Asked
  2026-09-11 with all three quoted and each one's truth value counted;
  answered "We want to remove the beta". B is the only one of the three that
  reads true today, so **B governs**: beta meant *until a run is counted*,
  and run 1 is counted (`.agents/docs/orchestrated.md`, Runs — 2026-09-06,
  5h37m, 10 managers, 0 kills, 8 merged). Recorded in the diff with its date,
  per the plan.
- **A is rewritten, not deleted.** A said "beta until a run shows which
  empties a queue faster" — comparative, and `unsupervised.md` Runs holds no
  peer-fleet drain to compare against, so as written it could never be
  discharged. It becomes a statement of what is still unmeasured, which is
  true and stays true. Deleting it would drop a real gap.
- **A and B now say the same thing**, one sentence each: what discharged the
  label (run 1) and when (2026-09-06). A mode whose docs define its beta three
  ways is the defect under the whole plan; stripping labels without collapsing
  the definitions would leave it.
- **C stays false and stays out of scope.** The requirement's last
  `Satisfied when` — drain the stocked queue, no human turn — is owned by
  `docs/plans/orchestrated-run.md`. Run 1 failed it in its own words ("the
  queue did not drain", 30 plans waiting). Out of beta is a claim about
  evidence; the requirement's own bullet is a separate, still-open claim.
- **Not the default anywhere.** Not the conf value, not `run_mode`'s
  fail-closed fallback, not the consumer bootstrap. Separate decision, asked
  2026-09-10, still unanswered.

## Rejected

- Stripping on my own reading of B. The plan says the session does NOT pick
  whichever licence it likes — it is product direction (`Decide alone`), and
  the three disagree. Asked instead.

## Review

- r1: `.agents/docs/orchestrated.md` asserted the comparison "never was what
  the label waited for". False against this file's own prior text — licence A
  tied the label to exactly that comparison. The strip would have had the repo
  rewrite its own history to make the discharge read cleaner, which is the
  failure the plan's Traps name. (fixed: the file now records that it carried a
  second condition, that it could never be discharged, and that the comparison
  stays open and is not a label.)
- r2: the two discharge sentences were not one claim — "discharged the beta
  label on 2026-09-11" against "…, 2026-09-11". The plan asks for one claim in
  one spelling across both files, and a second spelling is the exact defect it
  exists to close. (fixed: both now read "counting it is what discharged the
  beta label, 2026-09-11", differing only in how each points at the Runs table;
  checked by normalising whitespace and comparing.)
- r3: `.agents/docs/orchestrated.md` authority paragraph said "nothing about
  this mode's standing softens it" — "standing" is a noun for the label this
  repo does not use anywhere else. (fixed: "nothing about this mode softens
  it".)

## Blockers

None.

## Where to look

- `docs/plans/orchestrated-beta-exit.md` — the three licences, scope, traps.
- `.agents/docs/orchestrated.md:Runs` — run 1's counted numbers, licence B's
  discharge.
- `.agents/harness/selftest/orchestrated.sh` — asserts the session-start
  banner literally. Same commit as the banner or the suite reds.
