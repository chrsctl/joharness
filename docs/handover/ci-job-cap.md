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
next: Retire this file and the plan, open the pull request, merge.
---

## Goal

Requester asked for a job cap after watching this session wait on CI. The
waiting turned out to be a stale API rather than a slow job, and the cap was
kept anyway on its own merits: nothing bounds a hung job below six hours.

## Decisions

- **15 minutes for `lint`.** The twelve consecutive completed runs 471 to 482
  spanned 2m04s to 2m41s, counted from the Actions API as
  `updated_at - run_started_at`, counted 2026-09-04. The runs themselves
  straddle two days — 471 and 472 finished late on 2026-09-03, and 471 is the
  2m04s floor — so a re-count filtered to one date reproduces neither end. Fifteen is 5.6x the
  slowest of those, which leaves room for a cold runner and an image pull
  while still turning a hang into a red inside a coffee break.
- **60 minutes for `windows`, and it is NOT a measurement.** That job is
  `if: false` and has no runs to count. The number is a bound chosen to be
  strictly better than 360 while staying clear of the first re-enabled run;
  review r3 is why it is not 30.
- **The cap is not the fix for what prompted it.** CI had finished in 2m16s
  and 2m32s while the checks API reported it running for roughly eighteen
  minutes each time. The cap guards a genuinely hung job; it would not have
  saved a minute of this session.

## Rejected

- **Capping `ci-verify-layers.sh`'s image pulls per attempt.** Its retry only
  fires on a non-zero exit, so a reachable-but-throttled registry is not
  retried and not bounded, and could spend most of the job's budget while
  genuinely progressing. Real (review r6), pre-existing, and a different
  change: bounding a pull needs its own evidence about what a slow pull looks
  like here, and guessing at one inside a plan about job caps would be the
  written number this plan spends its Traps section avoiding.

## Review

Sonnet depth: `/code-review` (high) on the full diff plus the harness verifier
reading it cold. Six findings on a twenty-line change, which is the argument
for reviewing small diffs at the same depth as large ones.

- r1: (verifier) **The change itself was never committed.** The branch carried
  the plan and this file; `.github/workflows/ci.yml` was an uncommitted
  working-tree edit, so as pushed the branch added no cap at all. Caught by
  starting from `git diff origin/main...HEAD` rather than from the tree.
  (fixed: the workflow lands in the same commit as this record)
- r2: (verifier) **A job killed by `timeout-minutes` counts as cancelled**, so
  the layer-verdict step guarded by `if: ${{ !cancelled() }}` is skipped
  exactly in the hang the cap exists to catch — and the comment above that
  step explains at length why it chose `!cancelled()` over `always()` without
  knowing a cap would exist. (fixed: the comment now names the interaction and
  says the trade is the same one it already made, not an exception to it. The
  condition is unchanged: a job killed for hanging is one nobody reads a
  verdict from, and what to read is which step it died in)
- r3: (code-review) **30 minutes for Windows could kill the run it exists to
  let somebody measure.** That job calls `selftest.sh` directly with no
  inert-diff skip, on a platform several times slower at spawning processes,
  and a cancelled first run produces no duration at all. (fixed: 60, with the
  reasoning in the comment)
- r4: (code-review, verifier) **The `lint` comment presented a measurement
  without saying whose.** This file is seeded verbatim into every consumer and
  never synced, so a repo that took it inherited canonical's numbers, and a
  legitimate run killed at 15 minutes there reads exactly like a hang.
  (fixed: the comment says the runs are this repo's and tells a consumer to
  re-count and raise it)
- r5: (code-review) **"Twelve consecutive completed runs on 2026-09-04" was
  false for two of them.** Runs 471 and 472 finished late on 2026-09-03, and
  471 is the 2m04s floor, so a re-count filtered to the stated date reproduces
  neither end of the range. (fixed here and left correct in the workflow
  comment, which already said the counting date rather than the runs' date)
- r6: (code-review) The plan's Acceptance pointed at a measurement "below"
  that was only in this file, which step 7 deletes before the pull request
  opens. (fixed: the range is written into the plan itself)

Both readers independently re-counted the run range and agreed on 2m04s to
2m41s; the verifier could not reach the Actions API from its sandbox and said
so rather than confirming it, which is the right answer to give.

## Blockers

None.

## Where to look

- `.github/workflows/ci.yml` — both jobs.
