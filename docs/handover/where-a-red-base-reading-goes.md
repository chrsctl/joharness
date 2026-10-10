---
workstream: where-a-red-base-reading-goes
status: in-progress
branch: claude/where-a-red-base-reading-goes-k7q2
pr: none
plan: where-a-red-base-reading-goes
issue: 305
session: https://claude.ai/code/session_0184K9TLbGmKacfrGXdHezXb
agent: opus
updated: 2026-10-10
next: Settle the question, graduate the answer into .agents/docs/consumer-repos.md, delete the research file
---

## Goal

Settle `docs/research/where-a-red-base-reading-goes.md` (issue #305): where a
"base is red, not my diff" reading lives, given the never-inherit and
never-trust-a-written-number rules. Graduate to `.agents/docs/consumer-repos.md`.

## Decisions

- Commit-keyed record = both: keying answers base-moved half of step 7's
  inheritance rule, not environment half (runner, registry), and record
  cannot tell which half made a check red. So forecast only, never substitute.
- Duplicated baseline cost answered without any record: re-run head's
  failing set on merge base, not whole suite. Needs no harness change.
- Ownership stays consumer's (PR349 already wrote point 2); harness ships no file.

## Rejected

- Red-check file on base, in harness: written number + inherited reading +
  registry needing `shared:` and a reconcile per merge.
- Lead channel: 40-char pointer, stem must be queue item, relay-never-act.
- Gate on base check runs: gate over written number, first GitHub read in script.

## Review

## Blockers

None.

## Where to look

- `.agents/docs/consumer-repos.md` — graduation target.
