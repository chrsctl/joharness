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
next: Retire and open the pull request
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
  head a322a67da), pinned `--since=2026-10-15T00:00:00+00:00`; command and
  classification written into the graduated section: kind by subject first word,
  parent/child kind and time gaps, parent arity for retires.
- Echo's "CI run per commit" refuted: gx `ci.yml` and this repo's run on
  `pull_request` and `push` to `main` only.
- Merge-retire invisibility measured in a scratch repo: deletion inside a
  merge commit is absent from `git log --all --full-history --diff-filter=D`,
  present with `-m`.

## Review

- r1: (verifier) spawn prompt carried the gx clone path beyond the allowed fields (wontfix: the reading lives outside this checkout; without the path the second context could not re-take it, research.md)
- r2: (verifier) baseline count unreproducible — bare --since drifts with time of day, no command in the graduated doc (fixed: pinned head and UTC cutoff, command in handover.md)
- r3: (verifier) "7 to 54 minutes" wrong, gaps run 0.4 to 64.6 (fixed)
- r4: (verifier) within-2-minutes count is 25, not 23, and code commit undefined (fixed: defined, recounted)
- r5: (verifier) 9 of the 25 parents already edited docs/handover, so not all break the same-commit rule (fixed: split 16/9)
- r6: (verifier) findings never written with GROUNDED marks before the node closes (fixed: marks and method in the graduated section)
- r7: (verifier) gx readings not marked as a consumer reading (fixed: house form "not re-taken here")
- r8: (verifier) "stall-contract" undefined (fixed: names manage.md §3 and JOHARNESS_STALL_MINUTES)
- r9: (verifier) reader list incomplete; Where to look names the deleted research file (fixed both)


## Blockers

None.

## Where to look

- `.agents/docs/handover.md` "Three bookkeeping commits" — the answer.
