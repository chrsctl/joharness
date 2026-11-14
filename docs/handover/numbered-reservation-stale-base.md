---
workstream: numbered-reservation-stale-base
status: in-progress
branch: claude/research-numbered-reservation-stale-base
pr: none
plan: numbered-reservation-stale-base
issue: none
session: https://claude.ai/code/session_01J1YMK52NzNeLazs985U5MY
agent: opus
updated: 2026-11-14
next: Settle the research question from the consumer's recorded findings, graduate to plans.md § Numbered artefacts
---

## Goal

Settle `docs/research/numbered-reservation-stale-base.md`: does reserving a
number in the plan's own pull request stop two branches taking one number,
when nothing measures the reservation merged first? Graduate to
`.agents/docs/plans.md`, delete the research file.

## Decisions

- Settled YES: the rule moves the race, does not remove it. Evidence:
  consumer findings re-read in a blobless clone of chrsctl/gx (commits
  14d9f4d2c, 2f6778a61, badaa2e0d, 402e4b972; PR #1686, #1678 merge times);
  plus a scratch git fixture: two plan branches off one base append the next
  free block, catch-up merge conflicts; inserting at different lines merges
  clean with the block twice.
- Wording change, not a harness check: the harness names no registry format;
  the repository's own `local-check` registry check is what catches it
  (gx's `tools/criteria/index.py` already fails on overlap).
- `upstream` not routing clerk edges is another item: PR body + lead, not here.

## Review

- r1: pending verifier (no change)

## Blockers

None.

## Where to look

- `.agents/docs/plans.md` § Numbered artefacts — the rule under question.
