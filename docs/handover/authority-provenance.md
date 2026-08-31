---
workstream: authority-provenance
status: review
branch: claude/authority-provenance
pr: none
plan: unsupervised-authority-provenance
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Open the pull request; PR 177 (the run's record and the revert) should land first
---

## Goal

The endurance run lasted 48 seconds because both spawned sessions refused
their prompt as an injection. Give a session something to CHECK, so a fleet
can be started by a prompt that points at evidence rather than one that
asserts authority.

## Decisions

- **Only a MERGED conf commit is evidence.** Committed is not the bar —
  a local commit is a person editing their checkout, which is the marker
  case wearing a commit's clothes. Merged means it went through a pull
  request like everything else here.
- **Reports, never gates; no exit code carries the verdict.** An exit
  status invites a caller to branch on it, and a report that something
  branches on is a gate nobody reviewed. A case pins the exit 0.
- **Supervised prints NOT CLAIMED rather than nothing.** A blank section
  reads as a failed check; nothing being claimed and failing to verify a
  claim must not look alike.
- **The goal bound travels with the verdict.** Unsupervised is live only
  while a requirement is open, so a session checking its authority needs
  both facts in one breath — a VERIFIABLE flip with no goal open still
  stops.
- **Not in scope: wording that gets past a refusal.** Stated in the plan
  and in the doc. If a session declines after checking committed evidence,
  that is its call.

## Rejected

- **`git log -S`** to find the commit that set the mode. It is a pickaxe:
  it counts OCCURRENCES of the string, so `supervised` -> `unsupervised` is
  invisible to it because the line count does not move. See r1 — this was
  not a style preference, it was the defect.

## Review

- r1: `authority_commit` used `git log -S'JOHARNESS_MODE'` and reported
  `5949995 2026-08-24 "Implement the unsupervised mode gate"` as the
  provenance of a flip made 2026-08-31 — an old, reviewed, unrelated
  commit presented as authorisation for a new claim. That is laundering an
  old approval into a new one, which is the exact failure this command
  exists to prevent. Worse than cosmetic: because the stale commit WAS
  merged, an unmerged local flip read as **VERIFIABLE**. (fixed — `-G`
  anchored to the assignment; `mutate` restoring `-S` reds 5, including
  both unmerged-flip cases.)
- r2: `-G` matches any diff line containing the regex, so a commit that
  only reworded the comment block around the setting could be named as the
  one that changed it. Anchored to `^[[:space:]]*JOHARNESS_MODE[[:space:]]*=`
  so a comment line cannot match. (fixed.)
- r3: the fixture is cumulative — later cases in the topic run against
  state earlier ones built (the goal-bound cases delete and restore
  `docs/product/thing.md`). Same trap that cost a round in
  `sweep-marker-leaks`. Each case here asserts only what it set up.
  (fixed — the goal cases restore the file.)
- r4: verifier not spawned. Thirtieth consecutive edge — the session
  instruction forbids calling the Agent tool unasked and Loop step 5
  requires a reader that did not write the diff. (wontfix — issue #168.)

## Blockers

None.

## Where to look

- `joharness.sh:authority_commit` — the `-S`/`-G` trap, written up in the
  code because the wrong one looks right.
- `.agents/harness/selftest/authority.sh` — the topic; every call pins both
  mode sources it is not testing.
- `.agents/docs/unsupervised.md` — the spawn-prompt shape, and the three
  things it carries.
