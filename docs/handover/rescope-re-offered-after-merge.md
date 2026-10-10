---
workstream: rescope-re-offered-after-merge
status: review
branch: manage/rescope-re-offered-after-merge
pr: none
plan: rescope-re-offered-after-merge
issue: 300
session: https://claude.ai/code/session_015ufRMGse26o7Pqj5wxDqmt
agent: opus
updated: 2026-10-10
next: retire workstream file, open PR, merge
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
  (pinned by the fixture this branch adds, see r1 — the old `key: b+d`
  fixture passed on the changed-since test alone); (3) judgement, re-earned by a plan file change, a
  higher-tier override is the human's.
- Graduation = the WHY in the comment beside the merged scan, incl. #359's
  r1 limit, which lived only in a retired workstream file.

## Rejected

- Keying settle on the held plan (issue option 1): blind to the merged
  surveyor, and suppresses a new collision's first surveyor forever.
- Report-and-respawn for criterion 3 (the node's own suggestion): a
  respawn costs money every pass, a wrong suppression only a wait; the
  `settled by merged rescope` line is the report a human acts on.
- Re-implementing anything: code already answers; a second copy rots.

## Review

- r1: (verifier) criterion 2's cited fixture pins nothing: with the `dispatch_rescope_covers` line in the merged scan commented out, the `key: b+d` case stays green because d.md landed after the record (repro.sh nocover late). (fixed: fixture `a fresh record that never saw holder d does not settle b+d`; revert check 2026-10-10, cover line commented, `bash .agents/harness/selftest.sh` → 2448 passed, 2 failed, both the new cases; restored → `./joharness.sh ci` 2448 passed, 0 failed, `ci: pass`. Touches the selftest, outside a research diff's two files — it pins the graduated claim, kept)
- r2: (verifier) comment's re-earn bullet omits that an UNMERGED done rescope settles on cover alone (#359 r5). (fixed: named as a known limit beside r1)
- r3: (verifier) bullets contradicted: plan-keyed "held for good" vs accepted "waits for holders". (fixed: the cost is a declaration no surveyor ever repairs, not a permanent hold)
- r4: (verifier) criterion 3 decided by assertion; node's report-line alternative not argued away. (fixed: comment argues suppress-and-say, names the settled line as the report)
- r5: (verifier) "verifier r1 of the fix" resolves to nothing in tree. (fixed: names PR #359 and its plan stem)
- r6: (verifier) a-requirement-no-plan-can-serve.md and plan-on-an-unmerged-branch.md still mention this node in prose. (wontfix: not research edges, nothing dangles; nodes this branch does not own — named in the PR body)
- r7: (verifier) Where to look omits the two functions the decision rests on. (fixed)
- r8: (session) `./joharness.sh verify` 2026-10-10: 2 passed, 4 failed — docker could not pull alpine:3, registry 429 Too Many Requests; diff touches joharness.sh comments only. (no change: see PR for the retry)

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_rescope_branches` — walk skips merged refs.
- `joharness.sh:cmd_dispatch` rescope block — key, `rescope_settled`.
- `joharness.sh:dispatch_rescope_merged`, `dispatch_rescope_covers` — the
  merged record and the cover test the answer rests on.
