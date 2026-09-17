---
workstream: janitor-role
status: in-progress
branch: claude/worker-idle-detection-l3v9m3
pr: none
plan: janitor-role
issue: none
session: https://claude.ai/code/session_01TsLnukcKvuRKLXcJ34BLhg
agent: opus
updated: 2026-09-17
next: Build docs/plans/janitor-role.md — the status word first, then the reader, then the role
---

## Goal

Requester: a separate role that cleans up and unblocks plans, once every 12
hours. Logic already exists in pieces — the curate cycle's cadence shape,
`./joharness.sh cleanup`, issues #254 and #249 — and none of it releases a
claim held by a session that is gone. Eight branches on this repo carry
claims today, six of them pushed 11 days to 4 weeks ago.

## Decisions

Requester left the three design calls to this session ("decide what's best,
goal is clear"). Taken:

- **Release, do not delete.** The janitor writes `status: abandoned` into the
  claim's OWN workstream file on its own branch and records why under
  `## Blockers`. Deleting the file would destroy the record the whole protocol
  rests on, and a returning session can set it back. Precedent for writing to
  another session's branch: the orchestrator's kill handover
  (`.agents/docs/orchestrated.md`, The kill).
- **A new status word, not a reuse.** `blocked` means a human is owed an
  answer; an abandoned claim is owed nothing. The vocabulary has exactly five
  readers (`joharness.sh:lint_enum`, `queue-context.sh`'s claim filter,
  `cmd_dispatch`, `cmd_analysis`, the handover README), so the word is
  cheap to add and the alternative — overloading `blocked` — is the
  ambiguity #254 measured.
- **Liveness is proven, never inferred.** Push age is not liveness in either
  direction (`.agents/docs/handover/README.md`). The command prints
  candidates and the evidence to check; the SESSION reads the control plane
  and only `ARCHIVED` / not found / a confirmed failure releases anything.
- **An unowned block is a dead claim** (#254's own reasoning: nobody waits on
  that answer, nobody will act on it), but its `## Blockers` text is carried
  into the release note, never discarded.
- **Clock only, 12h.** The curate cycle needed a production trigger because
  plan churn is bursty; here the subject IS elapsed time. A pass with nothing
  to release still lands its retire commit, which is what dates the cycle.

## Rejected

- Adopt-and-finish the abandoned branch. That is a build, not a sweep, and it
  breaks one-item-per-session. Loop step 2 already routes a picking session to
  edge work; the janitor makes the claim visible instead.
- Deleting the branch. `git push --delete` is forbidden to a session
  (AGENTS.md step 7); the janitor lists merged and released branches for the
  human.
- Dead `needs:` / `research:` edges as a sweep target. `ci`'s graph lint
  already reds an edge naming a node that never existed, and a satisfied edge
  clears itself when the file is deleted on merge. Nothing to sweep.

## Review

Nothing yet.

## Blockers

None.

## Where to look

- `.agents/harness/queue-context.sh:claims` — where a claim holds a plan.
- `joharness.sh:dispatch_curate_due` — the cadence shape this copies.
- `joharness.sh:cmd_cleanup` — the leftover sweep, already built.
