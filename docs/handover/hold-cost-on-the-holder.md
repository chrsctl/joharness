---
workstream: hold-cost-on-the-holder
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: hold-cost-on-the-holder
issue: 254
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-16
next: Build the per-holder count, add the selftest case, review, retire, open the pull request
---

## Goal

Issue #254: a branch's file claims hold other plans out of the queue, and
`dispatch` shows that only as HOLD lines under the OTHER items — never as a
cost on the row causing it. A reader sees a row that says "holds no slot"
and reasonably concludes the branch is free.

## Decisions

- Research before code found the issue's central example is already
  handled, and the fix predates the run it describes. A BLOCKED holder
  releases its holds: `joharness.sh` counts such a plan FREE with
  "that branch is BLOCKED on a human: spawn, reconcile expected at step 7"
  (`hold_live`, landed `4ee99c5` and `674849b`, both 2026-09-06; the run in
  the issue is 2026-09-10 to 2026-09-16). So the four plans cannot have been
  held by the blocked branch on this harness — either the consumer ran an
  older copy, or a live branch held them too. Reported on the issue rather
  than silently building for a state the code already handles.
- What IS unattributed, and is the issue's own second example, is a LIVE
  holder: one branch claiming a broad path put nine plans on HOLD and
  nothing on its row said so. That is what this branch builds.
- Presentation only, over `holdmap`, which already carries held-stem to
  holder. No new read, no new knob, no change to what counts as free.

## Rejected

- The blocked-versus-gone conflict (#254's second proposal). It decides
  whether a session may respawn a branch a human parked, which is product
  direction, and the issue explicitly does not claim respawning is right.
- A time bound on an unowned block (#254's third). It needs a threshold,
  and every threshold in this harness is the human's.

## Review

- r4: (verifier) the count was keyed on the BRANCH, not the claim, so a branch carrying two workstream files printed the same combined total on both of its rows and a reader summing them got double. Reproduced against a built fixture, not argued. The function's own `blocked_claims` one screen up already keys `<stem>@<branch>` for exactly this reason. (fixed — matched on the claim's stem as a prefix; the two-claim fixture is named in the plan as unasserted rather than claimed)
- r5: (verifier) the awk cut the branch out of the line at the first `)`, so a branch name containing one silently produced no annotation at all — this defect's own symptom, a holder reading as free, reintroduced. Reproduced with `mgr-weird)branch`. (fixed — prefix and exact-suffix comparison, no truncation. The truncating idiom is pre-existing two screens down; this code does not copy it)
- r6: (verifier) the blocked-row refute was VACUOUS and the plan's Acceptance claimed it would fail without the carve-out. Proven false by mutation: removing the gate left 1992 passed, 0 failed, because nothing in that fixture overlapped the blocked branch, so the count was 0 either way. A falsifiable claim about my own coverage, and it was false. (fixed — a plan that genuinely overlaps the blocked branch now exists in the fixture, and removing the gate reds the refute, verified this session)
- r7: (verifier) r2's verdict read `(recorded, ...)`, which `fb_marker` does not recognise — deliberately, per its own comment — so `ci` already reported the finding as unmarked and would have redded at the edge. (fixed — reworded to a verdict the gate knows)
- r1: (session) the plan named a NEW selftest topic file. The existing `dispatch.sh` topic already builds the fixture the cases need — one branch holding another plan, then a second — so a new file would have rebuilt that fixture to assert against it. (fixed — cases added to the existing topic, `scope:` corrected)
- r2: (session) two of the four assertions are `refute`s, which pass when the feature is DELETED. Proven rather than assumed: reverting the change reds exactly the two `expect`s and neither `refute`. The refutes still earn their place — one guards the count moving off one-plan, the other guards a future version computing the count before the blocked release — but they are regression guards, not deletion guards, and this repo has recorded that confusion three times (`PR239 r21`, `PR242 r1`, `PR242 r2`). (wontfix — the two expects ARE the deletion guard, proven by reverting, and a refute that cannot detect deletion is still the right guard against the count moving. Recorded so nobody reads four assertions as four guards)
- r3: (session) one acceptance bullet is UNMET and now says so: a holder holding one plan through two declared paths. The fixture has no such holder, and building one widens the diff past a presentation change. The dedupe is in the awk and unasserted. (fixed in the plan's text, which no longer claims it)

## Blockers

None.

## Where to look

- `joharness.sh:7284` — `holdmap`, `<held stem>\t<holder> on <path> (claimed on <branch>)`.
- `joharness.sh:7360` — the in-flight row's flag, where the count belongs.
