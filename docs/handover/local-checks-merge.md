---
workstream: local-checks-merge
status: in-progress
branch: claude/skip-github-actions-wait-jdd3bn
pr: none
plan: local-checks-merge
issue: none
session: https://claude.ai/code/session_018BqX6Ux5hvSAm5AQ725mDe
agent: opus
updated: 2026-09-10
next: Run ci and verify, then step 5 review with the verifier subagent.
---

## Goal

Requester: "Add skip waiting for GitHub actions/just run locally." Step 7
merges on GitHub checks green, so every session pushes and then waits on
Actions. Opt-out wanted: run the same checks here, merge without the wait.

## Decisions

- Knob `JOHARNESS_CHECKS=github|local` in `joharness.conf`, env override for
  one command. Same fail-closed shape as `JOHARNESS_REVIEW`: only the named
  value switches it, anything else warns and stays on the default.
- `local` does not merely permit skipping the wait — `./joharness.sh finish`
  RUNS `ci`, and `verify` when the diff touches harness code. Step 7 already
  names `finish` as the guard that fires while the fix is still a commit, so
  the command that answers "mergeable now" is the one that must have run the
  checks. Nothing else can: a session's own earlier `ci` proves an earlier
  tree.
- Refusals come before the run: uncommitted tracked changes, or HEAD not
  equal to the pushed remote tip, mean the local green would be about a tree
  that is not what merges. Same doctrine as `decide_ref` — a command that
  acts on an answer refuses when it has no answer.
- Default stays `github`, and under it `finish` keeps its current runtime and
  output plus one line naming who the gate is. A repo that does not opt in
  pays nothing, in seconds or context.
- Announced at session start when `local`, like the review gate. A session
  that learns at step 7 has already waited on Actions once.
- Behind the base branch is a red under `local` only. Under `github` a pull
  request run tests a MERGE of head and base, so the tip is not the whole
  story there and step 7's own 0-behind rule already covers it; under `local`
  nothing ever sees that merge, so the tip is the entire evidence.
- The suites run LAST and only when the rest of `finish` is green. A head
  still carrying its own workstream file is not the head that merges, so a
  run there would spend minutes on a question whose answer cannot change the
  verdict. The skip is printed, never silent.

## Rejected

- Caching "ci passed at sha X" so `finish` can skip a re-run. Every measure
  in this harness counts from git at read time and stores nothing; a stored
  verdict is a written number that goes stale in the one case that matters.
- A separate `./joharness.sh checks` subcommand. Two commands to run before a
  merge is one command too many, and step 7 already names `finish`.
- Having `finish` read GitHub (API or `gh`) to decide whether the wait is
  worth it. The ask is to not need GitHub; a gate needing a token is a gate
  a consumer without one cannot run.

## Review

Pending — step 5 not reached.

## Blockers

None.

## Where to look

- `joharness.sh:cmd_finish` — the gate being extended.
- `joharness.sh:review_on` — knob shape copied.
- `.agents/harness/selftest/ci-churn.sh` — fixture pattern for the new topic.
