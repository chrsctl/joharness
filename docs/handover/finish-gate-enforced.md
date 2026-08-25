---
workstream: finish-gate-enforced
status: in-progress
branch: claude/start-loop-b148yi
pr: none
plan: finish-gate-enforced
session: https://claude.ai/code/session_018e9SZFRciB3FXwrwUzLQJs
agent: opus
updated: 2026-08-25
next: Wire the finish gate into cmd_ci at the edge, then write the four selftest fixtures and prove each goes red first
---

## Goal

`docs/plans/finish-gate-enforced.md`, urgent: `./joharness.sh finish` is a
correct gate nobody has to run, so step 7's delete-your-own-workstream-file
ritual keeps not happening — 22 merges passed over one finished file. Stage 4
of `.agents/docs/feedback.md` (Enforce) is what is missing: `cmd_ci` never
calls `cmd_finish`.

## Decisions

- Claimed on the session's designated branch rather than a fresh cut: the
  branch was already 0 ahead / 0 behind `origin/main`, so it is a clean cut
  from main by content.
- The hook named `docs/handover/joharness-minify-optimize.md` as this
  branch's file. It is not: the branch's diff against `origin/main` is empty,
  so the file is INHERITED — PR 54's leftover, and precisely the accretion
  this plan exists to stop. Not touched here (`cleanup`'s business, and the
  hook says it is not this session's chore).

## Rejected

(to fill)

## Review

(to fill — opus tier, adversarial, three lenses)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_finish` — the gate, already correct.
- `joharness.sh:cmd_ci` — the `review_on` edge block to copy the condition from.
