---
workstream: janitor-apply-skips-a-deleted-branch
status: in-progress
branch: claude/janitor-apply-skips-a-deleted-branch
pr: none
plan: janitor-apply-skips-a-deleted-branch
issue: 397
session: https://claude.ai/code/session_01VK36eqjgoWdgS5dZHGEedK
agent: opus
updated: 2026-10-10
next: Open the pull request, retire plan and workstream file, merge
---

## Goal

`janitor --apply` must never re-create a branch deleted on origin (#397):
ask origin (`ls-remote`), not the local ref.

## Decisions

- `ls-remote` runs after the local-ref check, so the default-refspec case
  keeps its `skip … no such branch` path (plan: must not regress).
- `ls-remote` exit 2 = gone (rc 0, nothing pushed); any other non-zero =
  origin unreachable: skip with rc 1, never push on an unanswered question.
- Mutation, 2026-10-10: `janitor_apply` ls-remote + lease removed, `bash
  .agents/harness/selftest.sh` gave 2385 passed, 3 failed (the narrow-refspec
  cases); restored, 2388 passed, 0 failed.

## Rejected

- None yet.

## Review

- r1: (verifier) the --force-with-lease push had no test; dropping it stayed green. (fixed — git-wrapper fixture deletes the branch at push; `FAILED`, origin stays without it)
- r2: (verifier) the unreachable-origin `*)` arm was untested. (fixed — fixture points origin.url at nothing; skip, rc 1, claim untouched)
- r3: (verifier) `gone` left the stale local ref, so every dispatch re-listed the branch under a narrow refspec. (fixed — `update-ref -d refs/remotes/origin/<b>` on gone, local only; selftest refutes the re-listing)
- r4: (verifier) ls-remote asks the fetch URL, push writes the push URL; a split pushurl can give a false gone or FAILED. (wontfix: never a re-creation, the lease guards the push; a split-URL origin is not a shape this harness provisions)
- r5: (verifier) the refspec restore wrote multi-valued config as one value. (fixed — unset-all, then one --add per line)
- r6: mutation, 2026-10-10: lease, update-ref and the `*)` arm removed in one run of `bash .agents/harness/selftest.sh` gave 2389 passed, 6 failed, exactly the new r1–r3 cases; restored, 2395 passed, 0 failed. (no change)

## Blockers

None.

## Where to look

- `joharness.sh:janitor_apply` — the push that re-created the branch.
