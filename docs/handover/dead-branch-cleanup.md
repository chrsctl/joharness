---
workstream: dead-branch-cleanup
status: review
branch: claude/delete-merged-remote-branch-61qy2f
pr: 32
plan: none
agent: sonnet
updated: 2026-08-23
session: https://claude.ai/code/session_01MhevorBe88x3x2wiVMFGJb
next: Merge the PR. Nothing for the human — deletion is optional.
---

## Goal

Finish protocol told the session to delete the merged remote branch; a remote
session cannot (`git push --delete` permission-blocked, no branch-delete tool
in GitHub MCP), and the human ruled it out. Question then raised: is anything
actually dependent on deletion? Answer: no. Make the protocol say so.

## Decisions

- Dead merged branches are cosmetic: the session-start hook filters branches
  merged into the base out of the claims view (`merge-base --is-ancestor`),
  and `/who` takes liveness from the control plane, not branch existence.
  Docs (`harness/AGENTS.md` step 7, `docs/product/README.md` Branch flow)
  now say: ignore deadwood; deleting is optional hygiene, human-only.
- The filter rests on the merge-commit rule. Squash or rebase merges would
  hide ancestry and deadwood would pollute claims again — recorded in Branch
  flow next to the 2026-08-21 incident so the coupling is visible.
- Sessions never `git push --delete` stays a hard rule.

## Rejected

- Session-side `git push --delete` (retry or permission grant) — human
  declined ("No in child repos").
- Hook block naming deadwood with a ready delete command — built, tested,
  then removed: a 7-line nag every session start for something cosmetic the
  human chose to skip. Reverted to the plain merged-branch filter.
- Requiring the "Automatically delete head branches" repo setting — deletion
  is optional, so the setting is mentioned as hygiene, not required. No MCP
  tool can flip it anyway.

## Review

- r1: `.claude/skills/steward/SKILL.md` "At merge" still commanded DELETE the
  remote branch — the exact rule this branch reverses; updated to match
  (fixed)
- r2: Branch flow claimed re-cutting a merged branch name needs
  force-with-lease — false under the merge-commit rule (old tip is ancestor,
  push fast-forwards) and taught force-pushing shared names; sentence dropped
  (fixed)
- r3: this workstream file lacked the `## Review` section the template
  requires; added (fixed)
- r4: `harness/AGENTS.md` step 7 duplicated deletion mechanics from Branch
  flow verbatim; compressed to a reference (fixed)
- r5: Branch flow misattributed the 2026-08-21 incident to pre-filter merged
  deadwood — those three branches were deleted UNMERGED (see the seeded
  plans' comments), a category the ancestry filter never hides; reworded,
  and abandoned-unmerged triage (salvage plans, then delete) now stated
  (fixed)
- r6: "permission-blocked" stated a remote-environment property as universal
  fact in a consumer-synced file; rule now stands on "deletion is the
  human's call" alone (fixed)
- r7: filter's dependency cited the shared-branch no-rebase rule, which does
  not govern GitHub's Squash/Rebase merge buttons; the real invariant (PRs
  merge by merge commit) now named (fixed)

## Blockers

None.

## Where to look

- `harness/handover-context.sh` — the `merge-base --is-ancestor` skip in the
  other-branches loop is what makes deadwood harmless.
