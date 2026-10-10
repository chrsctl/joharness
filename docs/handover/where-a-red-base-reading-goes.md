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
next: Run ci, retire this file, open PR, merge when finish green
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

- r1: (verifier) point 4 compared against merge base; `pull_request` run checks out head merged into base tip, so base break after branching reads as yours (fixed: step 2 names merged-with commit)
- r1: (verifier) point 4 compared earlier CI run with re-run now, contradicting own environment half (fixed: step 3, same machine same hour)
- r1: (verifier) point 4 said checks; one check can be whole suite (#305 case) and hide one more failing test (fixed: step 1, tests not checks)
- r1: (verifier) same message on both does not exclude second break masked by base failure (fixed: step 4, re-run once base green)
- r1: (verifier) "every merge reconciles it" overstated node's "may touch"; cost bullet left uncounted silently (fixed: may touch, says not counted)
- r1: (verifier) POINTER why-text lives in .agents/docs/orchestrated.md:1553, not manage.md (fixed: cited)
- r1: (verifier) written number had commit, no date (fixed: 2026-10-10 added; `grep -c "gh api\|gh pr\|api.github" joharness.sh` printed 0 at 045f2d7d)
- r1: (verifier) "compare message" too compressed; forecast-not-substitute stated three times (fixed: steps written plain, Why drops repeat)
- r1: (verifier) workstream file stale, `plan:` names no plan (no change needed: verifier read uncommitted tree; Decisions/Rejected were filled at 5ec19b5f; research file is claimed through `plan:` by stem per TEMPLATE.md)

## Blockers

None.

## Where to look

- `.agents/docs/consumer-repos.md` — graduation target.
