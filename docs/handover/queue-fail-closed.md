---
workstream: queue-fail-closed
status: in-progress
branch: claude/queue-fail-closed
pr: none
plan: queue-fail-closed
issue: none
session: https://claude.ai/code/session_01MGeFxF7JmsWwnj5MiThqag
agent: opus
updated: 2026-10-22
next: Run ./joharness.sh ci and verify, then edge review with the verifier
---

## Goal

Queue readers and writers fail closed: a missing or broken queue hook reads
UNREADABLE (never DRAINED), the janitor keeps blocked/done claims, and a
claim with no `status:` line gets `status: abandoned` on release.

## Decisions

- `dispatch` checks both hooks (handover-context.sh too): either unread is no
  picture of the queue. It returns at the hook read with `verdict : UNREADABLE`,
  after the role lines are printed; the verdict says "no role either" because
  moving the hook read above the role section would need the edge walk moved
  too (DISPATCH_WITHHELD), a reorder out of this plan's scope.
- `drain_hook_read` wraps drain_hook in the caller's shell so the reason line
  reaches the verdict; drain_hook itself still prints it to stderr.
- One predicate `janitor_releasable` (in-progress, review, empty) for
  janitor_candidates and the sweep's `(candidates:` list; an unknown status
  is not releasable either (fail closed). The report still prints the row,
  with a `never released` line.

## Rejected

- None yet.

## Review

- r1: red on main before the fix (selftest, 2026-10-22): `FAIL a non-executable queue hook reads UNREADABLE`, `FAIL a hook exiting non-zero reads UNREADABLE with its exit code`, `FAIL and no plan file changes:  M docs/plans/base-a.md ... M docs/plans/widehold.md`, `FAIL dispatch never offers a blocked claim for release`, `FAIL --apply refuses a blocked claim`, `FAIL and the claim now reads status: abandoned` (fixed)
- r2: (verifier) janitor --apply pushed an identical tree and said `release` for a claim with no readable frontmatter (none, unterminated, CRLF) (fixed: unchanged blob = skip, nothing pushed, selftest mgr-nofm)
- r3: (verifier) a quoted or unknown status now holds its plan with no janitor route (wontfix: fail closed is the plan; the sweep row names it `never released`, the human resolves it)
- r4: (verifier) hook stderr reached the verdict line; `DRAINED` could ride inside it (fixed: reason is the exit code only, hook stderr discarded; selftest refutes the stderr text)
- r5: (verifier) the --apply skip reason did not name blocked/done/unreadable status (fixed)
- r6: (verifier) two janitor refutes vacuous if the line is absent (fixed: expects on the sweep's `never released` row added)
- r7: (verifier) orchestrate.md has no rule for `verdict : UNREADABLE`; it reads as not-an-end, keeps passing, role spawn lines sit after the verdict and are never reached (no change: fails closed; .claude/commands wording is out of scope)

## Blockers

None.

## Where to look

- `joharness.sh:drain_hook`, `janitor_candidates`, `janitor_apply`.
