---
workstream: rescope-re-offered-after-merge
status: in-progress
branch: manage/rescope-re-offered-after-merge
pr: none
plan: rescope-re-offered-after-merge
issue: 300
session: https://claude.ai/code/session_015ufRMGse26o7Pqj5wxDqmt
agent: opus
updated: 2026-10-10
next: verify, verifier review, retire, PR, merge
---

## Goal

Settle `docs/research/rescope-re-offered-after-merge.md` (issue #300): a
merged surveyor's "holds are genuine" conclusion stops suppressing the
OVERLAP-BOUND spawn instruction once its branch merges or the holder set
shrinks. Graduate the answer into `joharness.sh` and delete the node.

## Decisions

- The mechanism already landed: PR #359 (plan
  rescope-settled-by-merged-superset) closed #300 with
  `dispatch_rescope_merged` + `dispatch_rescope_covers`, pinned by the
  `a MERGED done rescope settles a covered key` fixtures in
  `.agents/harness/selftest/dispatch.sh`. Node was stale. Settled against
  that code, not rebuilt.
- All three settle criteria checked: (1) source = retired workstream file in
  history, counted read; (2) new holder = not covered = surveyor fires
  (fixture `key: b+d`); (3) judgement, re-earned by a plan file change, a
  higher-tier override is the human's.
- Graduation = the WHY in the comment beside the merged scan, incl. #359's
  r1 limit, which lived only in a retired workstream file.

## Rejected

- Keying settle on the held plan (issue option 1): blind to the merged
  surveyor, and suppresses a new collision's first surveyor forever.
- Re-implementing anything: code already answers; a second copy rots.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_rescope_branches` — walk skips merged refs.
- `joharness.sh:cmd_dispatch` rescope block — key, `rescope_settled`.
