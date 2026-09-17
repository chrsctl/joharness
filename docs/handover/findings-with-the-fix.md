---
workstream: findings-with-the-fix
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: findings-with-the-fix
issue: none
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-17
next: Retire this file and open the pull request; flag the 2-of-535 judgement to the human
---

## Goal

`docs/plans/findings-with-the-fix.md`. Loop step 5 requires a review finding
to be recorded BEFORE its fix and in the SAME commit; nothing checks either
half. The plan conceded the first half is unverifiable from git and proposed
a lint for the second, with one condition on trusting it: a backtest over the
window `feedback` walks, and its own words for what the number decides —
"whether the rule is widely broken (so the check is right and the repo has a
habit to fix) or the check is wrong."

Ran the backtest first, before writing the lint. **The check is wrong.** The
plan is withdrawn on its own decision procedure, the measurement graduates to
`.agents/docs/handover/README.md`, and no code is written.

## Decisions

- Taken at opus, above the plan's `sonnet`. Escalation is allowed; the plan's
  own Traps name the opus condition for exactly this — a gate that cannot
  separate its false positives from the violation is wrong-but-plausible.
- Backtest BEFORE the build, not after. The plan listed it under Acceptance,
  which reads as "build, then measure". Its own sentence says the number
  decides whether the check is right at all, and a check written first is a
  check its author then wants to be right.
- The measurement graduates rather than dying with this branch. A plan for
  this exists because the gap is real and obvious; without a durable record
  the next session proposes it again and re-derives the same 37.
- The plan file is DELETED, not marked blocked. Its question is answered —
  do not build this — and an answered plan left in the queue is work the
  next session picks up and repeats.

## Rejected

- Reusing `joharness.sh:fb_fix_map` as the plan's Where-to-look suggests.
  It already answers "which non-handover paths did this finding's commit
  touch", but it excludes `docs/plans/` and `docs/product/` as well, because
  its job is attributing findings to CODE. For this question a plan-file edit
  IS fix content. Measured on the edge merged as pull request #262:
  `fb_fix_map` over its range returns ZERO pairs, so a lint built on it
  verbatim would have called all eight of that branch's findings recorded
  alone, every one of them wrongly.
- A stricter form keyed on each id's FIRST adding commit, to rule out
  re-adds. Built and run: same 37. The bullets those commits add are
  genuinely new to git — an earlier version of the same finding lacked the
  `r<N>:` id, so `^+- r<N>:` first appears when the id was added.
- `docs/plans/orchestrated-run.md`, which the queue ranks first. Two of its
  preconditions are the human's by its own words, and its one remaining
  deliverable — the Runs row saying what stopped run 3 — needs run 3 to have
  stopped. Re-counted 2026-09-17T01:21Z via `list_sessions` for this
  account: two manager sessions `SESSION_STATUS_RUNNING`, `updated_at` inside
  the last minute.
- The edge branch naming pull request #10. Re-read from GitHub rather than
  inherited: `state: closed`, `merged: false`, closed 2026-08-21. The hook
  says closed and open are the same bytes in git and to check — checked.

## Review

- r1: (session, premise) the plan's premise needs testing before its code,
  and the plan's own Acceptance says the backtest decides. Ran it first.
  **The first run of it was wrong** — see r3, r4 — so the numbers here are
  the corrected ones, counted 2026-09-17 over the newest 50 merged edges of
  `origin/main` (the window `JOHARNESS_FEEDBACK_EDGES` names), keyed on
  (workstream file, id): 535 findings, of which **39 were first added by a
  commit touching nothing outside `docs/handover/`**, from eight commits.
  Narrowed to the ones that already carried a `fixed` verdict when the
  bullet was added — the rest are a review with nothing yet to fix — leaves
  **6, from four commits**. Reading those six: two are the real shape
  (`1cf7214`, whose `## Review` was empty before it and whose fixes are in
  its parent `94cb031`), and four are not (a verifier confirming an
  already-committed tree, a correction to another finding's evidence, and
  two bullets being reformatted into the keyable form `lint_finding_ids`
  asks for). So the rule IS broken, and rarely: 2 of 535. The best
  narrowing found flags 6 to reach those 2.
  (fixed — the plan is still withdrawn, on corrected grounds: a report-only
  stage naming six branches to catch two, where four of the six obeyed
  another rule, is the condition this repo's doctrine says makes a stage
  stop being read. The numbers, the narrowing and the one genuine commit
  all graduate to `.agents/docs/handover/README.md`, so the call is
  re-openable on evidence rather than re-derived. Flagged to the human as a
  judgement, not a measurement verdict.)
- r2: (session, method) the strongest form of the check was built and run
  before concluding, not argued away. Restricting to each id's FIRST adding
  commit changes nothing on its own; what it missed was a different axis
  entirely, the key (r3). (no change needed — the method was right and
  insufficient, and r3 is where the insufficiency is recorded.)
- r3: (verifier) the count was keyed on the id ALONE, so an edge carrying
  TWO workstream files collapsed them: `r1` in the second file was read as
  already seen and never examined. The edge merged as pull request #237
  carries `docs/handover/curator-role.md` and
  `docs/handover/rescope-held-plans.md`, and that is exactly where the
  masked finding sat. Reproduced: `git log --format='' --name-only
  <base>..<tip> | grep '^docs/handover/'` on that edge lists both.
  `fb_fix_map` has the same single-key shape and gets away with it because a
  branch normally carries one workstream file — which is why copying its key
  looked safe. (fixed — keyed on (file, id); the corrected walk gives 535
  findings and 39 flagged from eight commits, against the 532 and 37 from
  seven the first run reported.)
- r4: (verifier) and the eighth commit that key was hiding is the one that
  falsifies the conclusion. `1cf7214` adds r1 and r2 to
  `docs/handover/curator-role.md` whose `## Review` was EMPTY before it
  (`git show 1cf7214^:docs/handover/curator-role.md`), with `(fixed before
  commit: ...)` verdicts, one commit after `94cb031` carried the code those
  findings describe. That is a finding written up afterwards, describing the
  fix rather than the problem — the exact shape the rule exists to stop, and
  the thing the graduated text said there were ZERO of. (fixed — the claim
  is gone; the text now says 2 of 535 and names this commit, because a
  measured rarity is worth more than a false absolute and the next reader
  can check it.)
- r5: (verifier) the 532 the text carried did not reconcile with the 534
  `./joharness.sh feedback` prints, and nothing said why. It was not a
  reconciliation problem; it was r3's undercount. The corrected 535 and
  `feedback`'s 534 still differ, legitimately — one counts ids introduced by
  a commit, the other bullets in the merged file, and 9 of those bullets
  carry no id at all. (fixed — the graduated text says what its number
  counts, so it is not read as contradicting the tool.)
- r6: (verifier) `ci` already reported r2 of this file as a finding with no
  verdict, and the `next:` line said to retire next. Retiring drops an
  unmarked finding permanently, which is the situation `a10a6e3` on this
  repo's own history had to be written to repair. (fixed — r2 carries `no
  change needed` above, in the commit that adds this line.)
- r7: (verifier) deleting a plan on a negative backtest is not the letter of
  either deletion path `.agents/docs/plans/README.md` names — the
  implementing pull request deleting it with the code, or a stale plan gone
  obsolete — and the Decisions section asserted it without citing either.
  (wontfix — the deletion stands and the reasoning is now stated rather than
  assumed: this plan's own Acceptance made the backtest the condition for
  trusting the check, so acting on the backtest is executing the plan, not
  overriding it, and an answered plan left in the queue is work the next
  session repeats. Recorded so a curator reading the Lifecycle clauses
  literally finds the argument rather than a gap.)

## Blockers

None.

## Where to look

- `.agents/docs/handover/README.md`, Reviewing — where the measurement
  landed, and the rule it is about.
- `joharness.sh:fb_fix_map` — the mechanism the plan pointed at, and the
  path exclusion that makes it the wrong reader for this question.
- `joharness.sh:fb_edges` — how an edge is enumerated: `--first-parent
  --merges`, second parent, `merge-base m^1 tip`. A backtest that enumerates
  merges any other way walks in-branch reconciles and counts the same
  findings several times; the first run of this one did exactly that and
  reported 86 of 602.
