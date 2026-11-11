---
workstream: starved-resumes-unasked
status: in-progress
branch: manager/starved-resumes-unasked
pr: none
plan: starved-resumes-unasked
issue: none
session: https://claude.ai/code/session_01J1YMK73dTDFMFdY1DpQZNt
agent: opus
updated: 2026-11-11
next: ci + verify on the r12 fix, then finish, PR, merge
---

## Goal

A STARVED head is green and drafted; the base just moves faster than
`finish`. Today it blocks `conflict: base outran finish`, asks a human, and
dispatch never respawns it. Resume it without a human up to a bound counted
from git (`JOHARNESS_STARVED_RESUMES`), ask only at the bound.

## Decisions

- A1: confirmed — dispatch's blocked `*)` branch sends every non-defect,
  non-awaited-PR block to `BLOCKED: the human's` (joharness.sh cmd_dispatch).
- A2: confirmed — starved-counts-green-runs merged in #760; its `next:` text
  is in manager-reference.md § Starved.
- A3: confirmed — `JOHARNESS_RESPAWN_LIMIT|2|dispatch` is per run; the new
  knob is a dispatch row of the knob table, documented in orchestrated.md.
- k = this block's number, the current one included; offered while
  k <= max, so the knob is the number of resumes ("blocks", plural, in the
  Goal). A count is commits writing a frontmatter `next:` opening
  `conflict: base outran finish`; the manager's grep and dispatch's awk read
  the same history.
- The resume row reuses `PARKED #<n> RESUME` (n = `drafted:`), the mark the
  orchestrator's table already routes; no `drafted:` = the human's block.
- Under the bound, base unmoved: a parked wait (scope held, no slot), not
  the human's.

## Review

- r1: (plan-checker) Acceptance counts the new cases under `verify`, which runs only the layer smoke test; the selftest runs under `ci` (fixed)
- r2: (plan-checker) a dispatch knob needs an orchestrated.md table row (knobs-declared) and the selftest unset list; neither in scope (fixed)
- r3: (plan-checker) no orchestrator rule acts on a row without `PARKED #<n> RESUME`; § Resume not in scope (fixed)
- r4: (plan-checker) k read from next: or from git, and how the manager gets k, unsaid (fixed)
- r5: (plan-checker) k including or excluding the current block unsaid (fixed)
- r6: (plan-checker) new next: form would double the `conflict: base outran finish` prefix (fixed)
- r7: (plan-checker) § Starved, not § Question, holds the exact next: rule (fixed)
- r8: (plan-checker) consumer acceptance names "offered", a string dispatch never prints (fixed)
- r9: (plan-checker) fails-on-origin/main item names no command or output (fixed)
- r10: (plan-checker) unmoved-base and past-bound cases have no Acceptance item (fixed)
- r11: (plan-checker) RECHECK already resumes on a moved base, and consumer-repos.md already carries the line (no change: RECHECK is defect-keyed and bounded by hours, STARVED by a count; the consumer-repos line is reworded off the plan stem)- r12: (verifier) a resume-form block with no `drafted:` or past the bound reads `BLOCKED: the human's` with no question posted and nothing saying so (fixed: dispatch flags `STARVED UNASKED`, § Starved sends a failed draft to the asked form; case added)
- r13: (verifier) the fails-on-base / passes-on-branch runs are not recorded (fixed: selftest with origin/main's joharness.sh and the branch's tests, 2026-11-11: `4317 passed, 4 failed` — the four offered/wait cases; branch `ci: pass`, verify docker `6 passed, 0 failed`)
- r14: (verifier) the branch changed the plan's bound from k < max to k <= max and its Acceptance (no change: disclosed in r1/r5 and Decisions; the knob names the number of resumes)
- r15: (verifier) base_moved_since compares the base's committer time with the block's author time; an amended block can read moved early (wontfix: the early resume is still counted against the bound, and dispatch_block_ts is shared with every park reader)

## Blockers

None.

## Where to look

- `joharness.sh:block_reason_ok`, `joharness.sh:dispatch_block_ts` — the block read.
- `.agents/harness/selftest/dispatch-park.sh` — `core path: waiting on` cases to mirror.
