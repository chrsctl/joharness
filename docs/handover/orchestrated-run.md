---
workstream: orchestrated-run
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: orchestrated-run
issue: none
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-16
next: Re-review the committed tree, then retire this file and open the pull request
---

## Goal

`docs/plans/orchestrated-run.md` is the queue's only free item. Its run
cannot start today — three preconditions are the human's and none holds.
One Scope bullet of it does not wait on any of them and is ten days
overdue: annotate the requirement's last bullet with the run's result and
what the run did not show. Run 1 was recorded on 2026-09-06 (`9a6f7b2`)
and `docs/product/orchestrated-mode.md` has never heard of it.

## Decisions

- Item picked by `/drain` on 2026-09-16. Edge work it names, the branch
  behind pull request #10, is deadwood: that pull request is CLOSED
  unmerged since 2026-08-21 and its session is absent from
  `list_sessions`, so it is a human's triage, not this session's work, and
  step 7 forbids merging a pull request this session did not open. No open
  GitHub issue. `curate` reports NOTHING TO CURATE.
- This session runs opus against a plan wanting sonnet. Escalation, not a
  downgrade, and not chosen for the work: the human switched the model
  mid-session. Review depth stays the plan's own tier — `/code-review` at
  high on the full diff plus the verifier at sonnet.
- No same-session plan file. The queue item IS a plan; the diff repairs
  that plan's own stale claims, which `.agents/docs/plans/README.md`
  routes as "fix plan in place on `main` via small PR", and writing a plan
  to repair a plan is ceremony the protocol does not ask for.
- The requirement file is NOT deleted. Its last bullet does not read true
  after run 1 — the run ended on a human turn, the queue did not drain,
  and `reconciles` was never counted at all.

## Rejected

- Starting a run. Two of this session's three reasons were wrong and the
  review caught both (r2, r3); what survives is enough. No recurring
  Routine exists for this account (`list_triggers` recurring +
  include_completed, EMPTY, 2026-09-16), so nothing would outlive one
  orchestrator. The four knobs in `joharness.conf` are every one commented
  out, so the cap a run would spend against is unconfirmed, and the cap is
  money. And a run IS in flight in the consumer since 2026-09-11 — starting
  a second fleet against a queue an existing one is working is not a
  measurement, it is a collision the human did not ask for.

## Review

- r1: (verifier) the build was still uncommitted when review ran, so the verifier diffed origin/main...HEAD and saw only the claim commit — it graded a branch with no deliverable on it. (fixed — build and findings commit together, and a re-review runs on the committed tree)
- r2: (code-review) "No heartbeat exists" rested on a wrong count: a FIFTH Routine was enabled at the minute that sentence was written. Re-tested with the filter that actually answers the question, `list_triggers` recurring + include_completed = EMPTY. The enabled one was an orchestrator's own ONE-SHOT pass check-in, which dies with its session. (fixed — the claim now names the recurring test and the false positive, so the next reader does not re-litigate it)
- r3: (code-review) "a fleet fired today gets ZERO managers and measures a queue of nothing" is refuted by a run in flight: `get_session` on session_01KKR8BgAx8M7LhScqXQbFSn, "orchestrator: chrsctl/gx", created 2026-09-11, updated 15:57Z on 2026-09-16, parent of managers RUNNING now. (fixed — the state block says a later run is in flight and uncounted, which is the plan's next work)
- r4: (code-review) the block counted joharness's own `docs/plans` while run 1 — its own cited precedent — ran against the consumer's queue. The plan never said which queue a run measures. (fixed — that is now the state block's first bullet)
- r5: (code-review, verifier) "the second Scope bullet is discharged for run 1" contradicted this same diff's "reconciles counted nowhere"; Scope bullet 2 names reconciles. (fixed — discharged EXCEPT reconciles, in both files)
- r6: (code-review) "under the cap" was listed as a clause run 1 fails, while the text's own explanation says the run stayed under it and says nothing about it. The clause that genuinely fails is numbers-counted. (fixed — the three clauses are now no-human-turn, every-free-plan, counted-not-written; the cap gets its own paragraph)
- r7: (code-review) both run-1 defects were credited to the second bullet's machinery; `orchestrator-respawn-liveness` repairs the third bullet's nudge, kill and respawn table. (fixed — both bullets named)
- r8: (code-review) "its seven verdicts prose there now" is false: `.agents/docs/product/README.md` carries the 2 rejections as prose and names 7 adopt-candidates by count, the node recoverable from joharness history alone. (fixed — restated from the README's own words)
- r9: (code-review) Scope bullet 3 is performed by this diff and was recorded nowhere, so the next session would annotate the requirement again. (fixed — the state block records it discharged by this pull request)
- r10: (verifier) the plan's `## Acceptance` was left untouched while the new state block declared bullet 2 already true — a contradiction inside one file. (fixed — bullet 2 now carries the pointer; the bar is unchanged, since a later run still adds its own row)
- r11: (verifier) "about 30" hedged a figure `.agents/docs/orchestrated.md` states exactly twice as 30. (fixed)
- r12: (code-review) stray double blank line before `## Scope`. (fixed)
- r13: (session) the first annotation restated what `.agents/docs/product/README.md` already records about run 1 — that counting it discharged the beta label and that its row counts no reconciles. Second copy, rots against the first. (fixed — the annotation points at that page instead)

## Blockers

None for this diff. The plan itself stays blocked on the three
preconditions above, which is what its repaired state block now says.

## Where to look

- `.agents/docs/orchestrated.md` Runs — run 1's row and its workings, the
  source for the requirement annotation.
- `docs/product/orchestrated-mode.md` — the human's words; the annotation
  goes under the last bullet and rewrites none of them.
