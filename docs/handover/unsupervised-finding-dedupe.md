---
workstream: unsupervised-finding-dedupe
status: review
branch: claude/unsupervised-finding-dedupe
pr: none
plan: docs/plans/unsupervised-finding-dedupe.md
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Retire this file, open the pull request, merge. The plan stays, blocked.
---

## Goal

Implement the constraint that a finding already addressed by a plan stops
counting as a source. Step 4's research — open the anchors, check the plan's
claims against code — ended it instead: the detector the constraint improves
cannot reach zero, so implementing it would not achieve its own purpose.

## What the research found

Recorded in full in `docs/research/unmarked-detector-unreachable.md`. The
argument, shortest form:

1. `src_unmarked` reads EVERY merged edge — `local FB_LIMIT=0`, with a
   comment saying a sweep deciding whether a fleet may stop must not trade
   completeness for speed.
2. Findings live in `## Review` sections of workstream files that step 7
   deletes, so they survive only inside merged commits. Nothing a session
   commits can change what a past commit says.
3. **62 of the 155 unmarked findings carry no `rN:` id.** `fb_keyable`
   requires `r<digits>:`, so no citation keyed on the finding can ever name
   those 62.
4. So citation dedupe caps at 155 → 62, and `cmd_sources` sets `dry=0` on
   any non-zero unmarked count.
5. So the sweep can never be dry, and the mode can never stop — the failure
   the requirement forbids, reached from a direction its wording does not
   cover ("an UNCOUNTABLE source never reaches zero"; this one is countable
   and unreachable).

## Decisions

- **Filed the question rather than coding around it.** Step 4: "Open
  question that decides the design? Settle it, record, THEN code — never
  mid-code." This one decides whether the code is worth writing at all.
- **The plan is blocked, not deleted.** Its shape is still right for the
  dedupe itself; what it cannot do alone is make the sweep dry. It carries
  `research: unmarked-detector-unreachable` and a BLOCKED section at the top
  saying so in the plan's own words, because a session reading the frontmatter
  edge alone would not know why.
- **The replacement is NOT chosen here.** Three candidates are recorded with
  a recommendation; which one lands decides when an unattended fleet may
  stop, and that is the human's.
- **`unsupervised-stop-condition` is explicitly NOT blocked.** It makes the
  four parts countable, which is right whatever this detector becomes, and it
  already holds the 151 out of scope.

## Rejected

- **Implementing it anyway and noting the shortfall.** 155 → 62 is real work
  that leaves the requirement's central property still false, and a later
  reader would find a merged constraint and reasonably assume it worked.
- **Choosing the baseline myself.** It moves when a fleet is allowed to
  stop.

## Review

Round 1, opus, self.

- r1: **the plan's premise was false, and I wrote the plan.** One merge
  earlier I filed this plan asserting the dedupe was what stood between the
  detector and zero. I had not checked that the detector could reach zero.
  Caught by step 4's research requirement, which is the only reason it was
  caught before the code. (fixed — the question is filed and the plan is
  blocked)
- r2: this is my own salvage plan's Trap one step over. That one says a plan
  for work already done is the expensive mistake; this is a plan for work
  that cannot pay off, and it reads exactly as urgent. (recorded)
- r3: `feedback` reports 154 unmarked; my re-count from the cached history,
  using `fb_marker`'s precedence copied literally, gives 155. A one-finding
  discrepancy I did not chase — it does not move an argument that turns on
  62 ≠ 0, and pretending the numbers matched would have been the cheaper
  lie. (recorded, stated in the research node too)
- r4: the `research:` edge cannot be observed blocking until this merges —
  the queue hook reads `origin/main`. `graph lint` on the branch resolves the
  edge (4 plans, 1 research, sound), which is as far as it can be checked
  here. Same limitation as PR 158's wave line, which did resolve as reasoned.
  (recorded — first reader after the merge should confirm the plan shows
  `blocked by` the question)
- r5: the research node's Verification section is marked WEAK on purpose: no
  second context has re-counted the 62. The verifier subagent Loop step 5
  names was not spawned — standing instruction, sixteenth consecutive edge.
  This is the first edge where that gap touches a number a decision rests on.

## Blockers

The replacement detector is a human decision. Not blocking this merge.
