---
plan: flag-abandoned-in-flight
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: .agents/harness/handover-context.sh, shared:.agents/harness/selftest.sh
---

## Goal

The in-flight block reports branches that no session will ever finish as though
they were live work. Measured on `origin/main` 2026-08-30: one entry carries
`pr: 10` for a pull request that is closed, was last pushed 9 days ago, and sits
660 commits behind `main`; three more have been silent 6 days or longer. Every
session start of a long run has read them and skipped them by hand.

`.agents/docs/product/README.md` already names this: "Abandoned UNMERGED
branches are the deadwood the filter cannot hide: they read as in-flight until a
human triages."

The rank added in #129 orders by closeness to merging. It has no notion of a
branch that has stopped moving, so an abandoned edge entry can still lead the
block — which is exactly what happened for most of this run.

## Scope

- `.agents/harness/handover-context.sh` — mark an entry STALE from git facts
  alone: last push older than a threshold AND far enough behind the base branch
  that a reconcile is certain. Print the marker on the entry and demote it below
  live work of the same rank, so an abandoned edge stops leading.
- `.agents/harness/selftest/` — a topic, registered in `SELFTEST_TOPICS`.

## Out of scope

- Deciding a branch is dead from its SESSION status. The hook reads refs and
  nothing else, in every consumer; one that needed a control plane would fail
  closed where it matters most. Liveness stays `/who`'s answer.
- Deleting or closing anything. Branch deletion is human-only
  (`.agents/docs/product/README.md`, Branch flow) and a session never
  `git push --delete`.
- Hiding a stale entry. Hidden deadwood is how it becomes permanent; it is
  demoted and marked, never dropped.

## Acceptance

- A fixture branch pushed long ago and far behind prints the stale marker; a
  fresh one does not.
- A stale entry at the edge does NOT lead the block when live work exists at the
  same rank; with nothing else in flight it still prints.
- Thresholds are env-overridable and their defaults carry the measurement that
  chose them.
- Each new case red when its behaviour is reverted.
- `./joharness.sh ci` — `ci: pass`; `./joharness.sh perf session-start` under budget.

## Where to look

- `.agents/harness/handover-context.sh:rank_of` — the rank to extend.
- `.agents/harness/selftest/handover-context-rank.sh` — fixture style, and the
  cases that already pin the ordering this must not break.
- `.agents/docs/handover/README.md`, In-flight order — the table to update.

## Traps

- The rank table in the docs and the code must not disagree; update both.
- Never infer liveness from push time — the hook says so in its own output.
