---
workstream: ci-job-cap
status: in-progress
branch: claude/drain-session-access-r80jpt
pr: none
plan: ci-job-cap
issue: none
session: https://claude.ai/code/session_01HkdcTFBBEsYFS3MKbxjZ3R
agent: sonnet
updated: 2026-09-04
next: Add timeout-minutes to both jobs with the measurement beside the lint one.
---

## Goal

Requester asked for a job cap after watching this session wait on CI. The
waiting turned out to be a stale API rather than a slow job, and the cap was
kept anyway on its own merits: nothing bounds a hung job below six hours.

## Decisions

- **15 minutes for `lint`.** Twelve consecutive completed runs on 2026-09-04
  spanned 2m04s to 2m41s, counted from the Actions API as
  `updated_at - run_started_at` over runs 471 to 482. Fifteen is 5.6x the
  slowest of those, which leaves room for a cold runner and an image pull
  while still turning a hang into a red inside a coffee break.
- **30 minutes for `windows`, and it is NOT a measurement.** That job is
  `if: false` and has no runs to count. The number is a bound chosen to be
  strictly better than 360, and the comment says so rather than implying a
  count nobody can reproduce.
- **The cap is not the fix for what prompted it.** CI had finished in 2m16s
  and 2m32s while the checks API reported it running for roughly eighteen
  minutes each time. The cap guards a genuinely hung job; it would not have
  saved a minute of this session.

## Rejected

- (to fill as the build finds them)

## Review

(to fill at step 5)

## Blockers

None.

## Where to look

- `.github/workflows/ci.yml` — both jobs.
