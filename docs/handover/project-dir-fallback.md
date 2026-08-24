---
workstream: project-dir-fallback
status: in-progress
branch: claude/project-dir-fallback
pr: none
plan: none
session: https://claude.ai/code/session_019c3kktaEvDBAnDv1K2i65p
agent: opus
updated: 2026-08-24
next: Open the PR, then merge once checks are green
---

## Goal

Found from a consumer repo (`chrsctl/redocted`) and brought here, because
a fix born anywhere lands in joharness first
(`.agents/docs/product/README.md`, Reconciliation).

The three context scripts fall back to
`$(dirname "${BASH_SOURCE[0]}")/..` when `CLAUDE_PROJECT_DIR` is unset.
That was the repo root when they lived at `harness/`; since the move to
`.agents/harness/` it resolves to `.agents/` — one level short. The queue
then reads `.agents/docs/plans/` (the protocol's own TEMPLATE and README,
both filtered out) instead of the project's `docs/plans/`, and reports
`plan-queue edge reached: done`.

Reproduced in THIS repo, which has a full queue:

```
$ CLAUDE_PROJECT_DIR=/home/user/joharness bash .agents/harness/queue-context.sh
  docs/plans/ci-scope-selftest.md  [normal, agent: sonnet, effort: high]
  docs/plans/compact-reorient.md   [normal, agent: sonnet, effort: high]
  ... 4 plans

$ bash .agents/harness/queue-context.sh
No plans on origin/main — plan-queue edge reached: done.
```

It fails in the "everything is done" direction, which is the one a session
acts on without checking.

## Decisions

- **Why nobody noticed:** the hook always sets `CLAUDE_PROJECT_DIR`, and
  all 21 selftest invocations set it explicitly. The fallback has never
  been executed by a test, so the move that broke it could not have gone
  red.

## Rejected

- **Also loosening the handover guard's "changes code" filter.** Suspected
  from the consumer side, checked here, and it is NOT a bug: the guard's
  comment says "same split as the churn measure" and it is exactly that
  filter — `grep -vE '^docs/(handover|plans|product)/'`, shared verbatim
  with `joharness.sh`'s churn measure. `AGENTS.md` and `README.md`
  counting as code is the design, not an oversight. Left alone.

## Review

Edge review at opus depth: correctness, blast radius, and
does-it-reproduce as separate passes.

- r1 (does-it-reproduce): the first version of the test computed the
  fallback by REPEATING the expression inside `bash -c`. That tests the
  copy in the test, not the three in the scripts — it would have passed
  with all three still broken. (fixed: a structural check that greps the
  real scripts for the one-level form, which covers all three, plus the
  end-to-end symptom run against this repo's own queue.)
- r2 (correctness): `skip` takes a name AND a reason; the first version
  passed one argument, so the skip line would have printed a blank
  reason on any repo with an empty queue — the exact case the guard
  exists for. (fixed)
- r3 (does-it-reproduce): checked by reintroducing the bug in
  `queue-context.sh` — `283 passed, 2 failed`, naming the file and the
  symptom; `285 passed, 0 failed` restored. A test that cannot fail pins
  nothing, and this repo has three of those in its history already.

## Blast radius

Three consumer repos carry this harness. The fix syncs out with it, and
nothing about the change is consumer-specific: every copy lives at
`.agents/harness/` by construction, since that is what the sync tool
writes.

## Blockers

None.

## Where to look

- `.agents/harness/queue-context.sh:32`, `handover-context.sh:27`,
  `handover-guard.sh:29` — the three copies of the fallback.
- `.agents/harness/selftest.sh` — every invocation sets the variable.
