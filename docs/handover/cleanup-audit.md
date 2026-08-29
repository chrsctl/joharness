---
workstream: cleanup-audit
status: in-progress
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: cleanup-audit
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Reproduce each of the four against main in a scratch repo, one at a time.
---

## Goal

Four findings the verifier returned against `cleanup` in PR54's replay were
never checked against today's tree. Carry them: reproduce or close each with
evidence, fix the ones that survive, and leave a regression case per fix.

`cleanup --apply` is the subcommand that deletes tracked files, and the one
whose mistake removes a live claim.

## Decisions

- Running at opus against a `sonnet` plan. Escalation is allowed and
  downgrade is not; the reason is that three of the four findings turn on
  what a command does in a state nobody normally builds (detached HEAD, a
  failed `git rm`, an unpushed live claim), and building those states
  correctly is where a wrong reading gets recorded as a verdict.

## Rejected

- (nothing yet)

## Review

(no round yet)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_cleanup` — all four live here or in what it calls.
- `joharness.sh:cl_inflight`, `decide_ref` — the two helpers the already-fixed
  findings landed in. `853f551` paid for `cl_inflight`'s filter; do not widen
  it (plan Traps).
- `.agents/docs/handover/README.md` — the `status:` values finding 1 turns on.
