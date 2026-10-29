---
workstream: research-ceremony-commit-cost
status: in-progress
branch: research-ceremony-commit-cost
pr: none
plan: ceremony-commit-cost
issue: none
session: https://claude.ai/code/session_01J1YMK3JBwa23stSBGPRjmQ
agent: opus
updated: 2026-10-29
next: Spawn the opus verifier on the graduated answer, record its findings, finish
---

## Goal

Settle `docs/research/ceremony-commit-cost.md`: which of the claim,
handover-only and retire commits could ride on a neighbouring commit without
losing claim-by-push, same-commit handover or retire-before-PR. Graduate the
answer to `.agents/docs/handover.md`, delete the research file.

## Decisions

- Answer: all three keep (no fold). Graduated as `.agents/docs/handover.md`
  "Three bookkeeping commits: keep, because"; research file deleted.
- gx counts from `/home/user/gx` (clone, `--shallow-since=2026-10-10`,
  head a322a67da) with a python pass over `git log origin/main
  --since=2026-10-15 --no-merges --name-only`: kind by subject first word,
  parent/child kind and time gaps, parent arity for retires.
- Echo's "CI run per commit" refuted: gx `ci.yml` and this repo's run on
  `pull_request` and `push` to `main` only.
- Merge-retire invisibility measured in a scratch repo: deletion inside a
  merge commit is absent from `git log --all --full-history --diff-filter=D`,
  present with `-m`.

## Review


## Blockers

None.

## Where to look

- `docs/research/ceremony-commit-cost.md` — the question and method.
