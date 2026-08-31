---
workstream: endurance-mode-flip
status: done
branch: claude/endurance-setup
pr: 173
plan: docs/plans/unsupervised-endurance.md
issue: 165
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Retire this file, merge AFTER PR 174, then spawn the fleet.
---

## Goal

Flip the committed mode for the endurance run. One file, `joharness.conf`.

## Authorisation

"Implement unsupervised endurance", 2026-08-31, after "Flip the mode" earlier
the same day and after issue #165 put the cost in front of the requester.
Reverted when the run ends, which the plan's Acceptance requires.

## Decisions

- **Committed, not the session-local marker.** The marker lives in the git
  directory, so it does not survive a clone and a spawned session would come
  up supervised and measure nothing. PR 163 used the marker because it
  measured one session; a fleet needs this file.
- **`joharness.conf` ALONE, and that is the whole point of the split.**
  `joharness.sh` and `.agents/harness/` are protocol text
  (`joharness.sh:protocol_paths`). A branch that both flips the mode and
  edits protocol text is an unsupervised session editing the protocol that
  governs it — forbidden, and the handover guard catches it. The recursion
  fix this run needs went in supervised first (PR 174).
- **Merges AFTER PR 174.** Landing the flip first re-enables the recursion
  that burned a runner for 42 minutes.

## Review

Round 1, opus, self.

- r1: **the handover guard fired on this branch too**, for the narrow and
  correct reason: `joharness.conf` is not documentation, so the branch needs
  a record. I had moved the record to the fix branch when I split them and
  left this one bare. That is twice today the guard caught a real omission of
  mine, and both times the fix was to write the record rather than to argue
  with it. (fixed — this file)
- r2: the split itself came from the guard's OTHER catch: the fix and the
  flip on one branch made an unsupervised session edit protocol text. The
  content was never wrong, the order was. (recorded — the reasoning lives in
  PR 174's record, which is where the protocol change is)
- r3: verifier round owed and NOT run — standing instruction, twenty-eighth
  consecutive edge. (wontfix on this branch — issue #168)

## Blockers

PR 174 must merge first.
