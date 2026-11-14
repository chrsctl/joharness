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
next: Open the PR, run finish, merge
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

- r1: (verifier) spawn prompt carried an item line and the gx clone path beyond subagents.md's fields (no change: the clone path was the only way to re-take the cited readings; noted)
- r2: (verifier) "building branch whose plan exists adds no registry line" contradicts "a carried plan reserves nothing" (fixed: rule reads "whose plan merged ahead of it"; a carried plan claims in-branch)
- r3: (verifier) only the plan pull request was told to re-pick; an in-branch claimer merging later had no rule (fixed: every branch holding an unmerged registry line re-picks; later merger loses)
- r4: (verifier) "stayed open 7h20m" mislabels reservation-commit-to-catch-up span, measured 7h23m (fixed)
- r5: (verifier) hand-written date in the graduated why (fixed: dropped, commits carry it)
- r6: (verifier) GROUNDED fixture claim had no recorded command (fixed: fixture steps written inline)
- r7: (verifier) handover `plan:` names a research stem with no plan file (no change: TEMPLATE.md says a research file is claimed through `plan:` by its stem)
- r8: (verifier) one 125-character line in plans.md (fixed: rewrapped)

## Blockers

None.

## Where to look

- `.agents/docs/plans.md` § Numbered artefacts — the rule under question.
