---
workstream: retro-two-modes-plan
status: in-progress
branch: claude/retro-two-modes-plan
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_017pMbD2M6TccgTkfZh9TDpS
agent: opus
updated: 2026-10-25
next: Write plan retro-audit-and-trace, drop research conduct-concern-to-retro, ci, verifier, PR
---

## Goal

User: merge conduct and retro into one role with two modes. Audit finds
problems in merged work and only counts them; trace takes failures,
including what audit found, and files fixes. Replaces research
conduct-concern-to-retro.

## Decisions

- Plan waits on conduct-recent-sample (rewrites conduct's sampling),
  c1-at-the-gates (copies conduct.md's C1 wording) and research
  conduct-c2-design (graduates into conduct.md); the C2 follow-up plan
  needs this one.

## Rejected

- Building the merge now: it would conflict with conduct-recent-sample.

## Review

- r1: interface signatures not fixed (CLI, twin, title, tokens) (verifier) (fixed: command table; aliases for conduct)
- r2: hand-off order unbuildable: retro_sample re-sorts by hash (verifier) (fixed: separate CONCERN list, one per run, retro_sample untouched)
- r3: session lookup ambiguous for stems retired twice (verifier) (fixed: latest retire on or before the audit row's date)
- r4: two acceptance cases pass on main unchanged (verifier) (fixed: cases rewritten to fail on main)
- r5: untraceable CONCERN never retired (verifier) (fixed: key concern:<date>:<stem> logged in retro-log; session none still traced from artifacts)
- r6: session dedupe drops CONCERNs whose session was logged for a block (verifier) (fixed: CONCERN key, case added)
- r7: retro.md had no wording for a CONCERN (verifier) (fixed: §2 wording, gate named)
- r8: spawn printers and label width missing (verifier) (fixed: status, spawn, held, suppressed lines named; 10-column label)
- r9: suppression between modes undecided (verifier) (fixed: one reviewer a pass, audit first, as today)
- r10: retro-* open-PR glob catches audit PRs (verifier) (fixed: each mode matches only its own branches)
- r11: consumers keep a stale conduct.md; sync never removes (verifier) (fixed: conduct and role conduct stay as aliases)
- r12: stale text outside scope; sibling plans name the deleted research; c1 anchor; bound unnamed (verifier) (fixed: scope widened, siblings edited, needs c1-at-the-gates, bound 6668 moves)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_conduct`, `joharness.sh:cmd_retro`: the two copies.
