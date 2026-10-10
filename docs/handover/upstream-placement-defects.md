---
workstream: upstream-placement-defects
status: in-progress
branch: claude/upstream-placement-defects
pr: none
plan: upstream-placement-defects
issue: none
session: https://claude.ai/code/session_0158ckFurR1bSxTGn9v4L8g4
agent: sonnet
updated: 2026-10-10
next: Wait for selftest + sweep (scratchpad sweep.out), recount feedback.md tables, run ci, verifier review, retire, PR.
---

## Goal

Plan `upstream-placement-defects`: `upstream` mislabels canonical-owned findings unplaceable.

## Decisions

- Plan Traps say joharness.sh is a protocol path, SUPERVISED ONLY. `./joharness.sh protocol-paths` prints only joharness.conf, .claude/settings.json, .github, and the comment above `protocol_paths` says joharness.sh is deliberately NOT core. `authority` is VERIFIABLE orchestrated. Proceeding unattended; plan text is stale on this.

## Rejected

## Review

- r1: (verifier) upstream_path_note got the raw `./AGENTS.md` and dropped its caution (fixed: stripped before the note)
- r2: (verifier) `.//x` / `././x` rejected, only one `./` stripped (fixed: loop strip, cases added)
- r3: (verifier) ownership read from current index, not the edge range (wontfix: doubtful cases are deliberately IN per the predicate's comment; comment now says so)
- r4: (verifier) common canonical basename in prose (`settings.json`) claimed (wontfix: same; flagged "named in text" for the reporter)
- r5: sweep 2026-10-10, upstream over all merge edges with JOHARNESS_CANONICAL line stripped: harness 1616, prose-nonCanonical 104, unplaceable 423, own 177; selftest 2447 passed 0 failed; old predicate rejects ./joharness.sh and selftest.sh, new accepts, docs/handover/README.md rejected by both (no change)

## Blockers

None.

## Where to look

- `joharness.sh:upstream_harness_path`, `joharness.sh:cmd_upstream`
