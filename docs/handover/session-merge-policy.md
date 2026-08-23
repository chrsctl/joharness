---
workstream: session-merge-policy
status: in-progress
branch: claude/delete-merged-remote-branch-61qy2f
pr: 35
plan: none
session: https://claude.ai/code/session_01MhevorBe88x3x2wiVMFGJb
agent: sonnet
updated: 2026-08-23
next: PR; merge it under its own rule once GitHub checks are green
---

## Goal

Human flipped the last autonomy lever (2026-08-23): sessions merge their own
green PRs — no more waiting on the human's merge click. Loop step 7 already
said "PR, merge to `main`" but practice routed every merge through the
human; write the conditions down so a session knows exactly when the click
is its own to make, and which merge method keeps the rest of the machine
working.

## Decisions

- Merge conditions, all required: GitHub checks green on the PR head, edge
  review recorded per step 5, no unresolved human review thread, merges
  clean. Anything less stays open.
- Own PR only. A PR authored by someone else is never merged by a session,
  green or not — the author decides (steward posture unchanged).
- Merge-commit method only, stated where the merge happens: squash or
  rebase merging breaks the merged-branch ancestry filter
  (docs/product/README.md Branch flow) — the claims view would read every
  squash-merged branch as in-flight forever.
- Ratification date recorded in step 7, repo convention for
  looks-arbitrary-later decisions. Human veto = revert; nothing else
  changes in Decide alone.

## Rejected

- Requiring human approval on the PR before self-merge — that IS the merge
  click with extra steps; the lever exists to remove it. Review-at-edge
  (step 5) is the quality gate, CI the correctness gate.
- Auto-merge (GitHub's enable_pr_auto_merge) instead of an explicit merge
  call — needs branch protection rules to arm, and hides the merge decision
  in repo settings instead of the protocol.

## Review

- r1: merge-gate condition list presented as exhaustive but omitted
  `./joharness.sh verify` — the one check GitHub CI is documented as unable
  to run; a steward session could self-merge a provisioning-breaking change
  on green checks alone. Condition added in both files: verify green when
  the diff touches any shell script (fixed)
- r2: protocol edits sat uncommitted while the workstream file's `next` and
  `## Review` were stale against them — same-commit rule; this update lands
  with the edits (fixed)
- r3: product README Finish bullet stated the merge-commit-only rationale
  twice four lines apart; new sentence now points at the existing filter
  note instead of restating it (fixed)
- r4: verify gate self-contradictory — "any shell script" glossed with a
  directory list; one literal reading reopened the r1 hole (non-`.sh`
  provisioning inputs under `env/`). Now: any non-`*.md` file under the
  four paths (fixed)
- r5: no up-to-date-with-main condition — checks do not re-run when the
  base advances, so stale-green self-merge was possible (this branch was
  itself behind after PR #27 merged mid-flight, every listed condition
  green). "0 behind fresh-fetched origin/main" added; subsumes "merges
  clean" (fixed)
- r6: "OWN" undecidable for steward sessions — every session PR shares one
  GitHub author. Defined in step 7: opened by this session, or handed to
  it by the human to drive (fixed)
- r7: condition list duplicated into the steward skill and already
  diverging in the same PR; skill now points at step 7, one copy (fixed)
- r8: self-merge authority syncs to every consumer repo with the harness —
  silent scope propagation. Documented in Branch flow (consumer overrides
  in its own Part 2) and flagged to the human in the PR (fixed, flagged)
- r9: workstream rides the already-merged designated branch name again —
  platform constraint pins the name, same as PR #34's r1; open PR blocks
  UI deletion meanwhile (wontfix, constrained)

## Blockers

None.

## Where to look

- `harness/AGENTS.md` Loop step 7, `.claude/skills/steward/SKILL.md` "At
  merge", `docs/product/README.md` Branch flow "Finish".
