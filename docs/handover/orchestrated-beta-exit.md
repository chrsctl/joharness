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

(pending — step 5)

## Blockers

None.

## Where to look

- `docs/plans/orchestrated-beta-exit.md` — the three licences, scope, traps.
- `.agents/docs/orchestrated.md:Runs` — run 1's counted numbers, licence B's
  discharge.
- `.agents/harness/selftest/orchestrated.sh` — asserts the session-start
  banner literally. Same commit as the banner or the suite reds.
