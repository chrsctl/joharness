---
workstream: drain-misses-requirements
status: review
branch: claude/drain-misses-requirements
pr: none
plan: docs/plans/drain-misses-requirements.md
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Retire this file and the plan, open the pull request, merge.
---

## Goal

`drain` reported DRAINED while an unplanned requirement — the top of step 2's
order — was waiting. Found by continuing past my own DRAINED report and
reading the queue hook directly.

## Decisions

- **Requirements first, as rank and not as an extra.** Step 2's words are
  "planning outranks the plan queue". `drain_next` now asks
  `drain_requirement` before `drain_plan`.
- **Split into two functions rather than widening one alternation.** The
  requirement scan is anchored to the hook's SECTION and the plan scan is
  not, so they are not one pattern with an extra branch.
- **The `NOT DRAINED` count is only printed for the case it describes.** It
  comes from the hook's "N free plans" line, which a requirement does not
  have; a plan count beside a requirement says the wrong thing about what is
  next.
- **`DRAINED` names every entrypoint it checked.** The old wording — "no free
  plan, no open question" — was true and read as a claim about the whole
  queue, which is how it hid this.
- **The section anchor is kept and recorded as unpinned.** See r3.

## Rejected

- **Matching any `docs/product/` path in the hook's output.** A requirement
  that already has plans must not be offered, and path-matching cannot tell
  the difference if the hook ever prints one elsewhere.

## Verification

- `./joharness.sh drain` — `NOT DRAINED`, `next:
  docs/product/unsupervised-mode.md`
- selftest **1047 passed, 0 failed, 1 skipped** (up 7 cases here)
- `ci: pass`; `verify` 6 passed, 0 failed
- `./joharness.sh mutate joharness.sh 3960 '  req=""'` reds **5** of the 7 new
  cases — the ones that pin ranking. The other two pin the fall-through,
  which that mutation does not break.

## Review

Round 1, opus, self, with `mutate` doing the work a reading would not have.

- r1: **the mutate check refused to run, and it was right.** Baseline not
  green: `an empty queue under supervised is drained` still asserted the old
  DRAINED wording. I had run the suite and read only the drain topic's TAIL,
  where the new cases are, so I saw seven passes and missed a failure eleven
  lines above them. The tool named it instead of blaming my mutation for it.
  (fixed — the assertion carries the new wording; this is the first time a
  tool built this session caught something the author had already missed)
- r2: I nearly reported "all seven pass" from that same partial read. The
  summary line was there and I did not look at it. (recorded — `grep -E
  "FAIL|passed,"` on the whole run, not a section)
- r3: **the section anchor is pinned by nothing.** `mutate joharness.sh 3945
  '    cat |'` replies NOTHING REDDED. `queue-context.sh` prints a
  `docs/product/` path in exactly one block and skips any requirement a plan
  serves, so no fixture reachable through the public interface can tell
  anchored from unanchored. Kept, because the invariant belongs to another
  file and a future block printing served requirements would otherwise hand
  the same requirement out forever — but recorded in the code as unpinned,
  with the command and the date, rather than left looking covered. (fixed —
  the comment says so)
- r4: the claim was pushed BEFORE the build this time, which the previous
  branch got wrong. (no change needed)
- r5: verifier round owed and NOT run — standing instruction, fourteenth
  consecutive edge.

## Blockers

None.
