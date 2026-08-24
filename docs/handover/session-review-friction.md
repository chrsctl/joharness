---
workstream: session-review-friction
status: in-progress
branch: claude/session-review-harness-friction
pr: none
plan: none
session: https://claude.ai/code/session_01Qk5dbNUvkmSB1dj5ufvhNB
agent: opus
effort: high
updated: 2026-08-24
next: Land the three fixes, run ./joharness.sh ci, open the PR.
---

## Goal

A consumer repo (`chrsctl/gx`) ran one long session — thirteen PRs merged,
CRM phases C4 through C10 — and was then asked to review the *run* for harness
improvements. These are the findings that belong here rather than there, with
the evidence each rests on. `plan: none`: the trigger was a human request, not
a queue item.

The consumer's own findings (`run-all.sh` discarding its failure transcript,
and a criteria index that cannot match a phrase spanning two string literals)
are repo-owned and stay in `chrsctl/gx`.

## Decisions

- (to be filled)

## Rejected

- (to be filled)

## Review

(pending)

## Blockers

None.

## Where to look

- `.agents/harness/handover-context.sh` — the rot check, and the listing that
  grew to 23 lines in one session.
- `joharness.sh` — the lazy-provisioning banner.
- `.agents/docs/plans/README.md` — `scope`, and the file it cannot express.
