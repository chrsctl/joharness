---
workstream: unsupervised-fanout
status: review
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: unsupervised-fanout
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: PR, merge
---

## Goal

Plan `docs/plans/unsupervised-fanout.md` (sharpened in PR #106). The queue
hook's fan-out line is unconditional: it says the same thing to a supervised
session, where a human decides whether to spawn, as to an unsupervised one,
where nobody is there to decide. Make the line mode-dependent — supervised
wording byte-identical, unsupervised an order to spawn now.

## Decisions

- The live-fleet acceptance criterion is NOT mine to satisfy unasked. It
  starts real sessions that act autonomously and merge their own pull
  requests; that is a resource and blast-radius decision for the human, not
  a step in a build. Everything else in Acceptance is done first, and the
  criterion is reported unmet rather than quietly dropped or quietly run.

## Rejected

- Re-resolving the mode inside `queue-context.sh`. Precedence across
  `$JOHARNESS_MODE`, the marker file and the conf lives in `run_mode()`
  alone; a second resolver rots against the first. `joharness.sh` exports
  the resolved value, the hook reads it, and unset means supervised — the
  safe direction, because a session that is not unattended must never be
  ordered to spawn.
- A permanent test asserting byte-identity against `origin/main`'s hook. It
  passes tautologically the moment this merges. The one-time diff is below;
  the supervised wording stays pinned by the wave and fan-out assertions
  that already existed.

## Review

`/code-review` (high) plus a mutation pass. Five findings from the review,
one more found by measuring my own comment.

- r1 `JOHARNESS_RUN_MODE` was missing from the block that unsets invoking-
  shell knobs, whose own comment says the next one added goes there too. The
  new cases invoke the hook bare on purpose, so a caller exporting the knob
  steered them. (fixed: added to the unset, and to the guard test that
  asserts the unset line verbatim — that guard went red on the edit, which
  is it working)
- r2 The spawn order had no guard for a session already holding a claim. A
  resumed or compacted session would be told to start a fleet on top of its
  own unfinished work, against Loop step 1. This hook cannot see the claim —
  it lives in a workstream file `handover-context.sh` prints — so the order
  now names the case and defers to step 1. (fixed)
- r3 The byte-identity assertion compared two POST-change supervised runs,
  so a change to supervised output would pass it. (fixed by deleting it and
  saying why — see Rejected; the real check is recorded below)
- r4 The unscoped-branch override printed with no leading newline, gluing it
  to the line above, and told the session to "claim one plan" where the
  Entrypoint paragraph below says unplanned requirements outrank plans.
  (fixed: newline, and "take ONE piece of work, requirements above first")
- r5 `.agents/docs/unsupervised.md`'s decision bullet still quoted the
  unconditional fan-out line as the rule, which the paragraph I added
  contradicts for the no-scope case. (fixed: the bullet now says the line is
  the queue's answer only when the queue proved it)
- r6 Self-caught. My own comment for r1 quoted the reviewer's 615/2 as if I
  had measured it. Re-measured on a copy with the unset cut back: 604 passed
  / 12 failed / 1 skipped, against 617 / 0 with the line whole, 2026-08-28.
  A number I did not take is a written number.

Mutation pass, 2026-08-28, by patching a copy of `queue-context.sh` and
re-running this step against it: forcing `qc_mode=supervised` fails 10 of the
new cases, forcing `qc_mode=unsupervised` fails 3. Neither survives, so the
gate is what the cases test.

## Acceptance

Met: supervised byte-identical; unsupervised names a whole wave with tiers;
across waves it orders wave 1 only and says why; a wave of one is run here,
not spawned; unscoped plans are never ordered spawned; `ci` green at 617
passed / 0 failed; `verify` 8 passed / 0 failed.

Byte-identity, the one-time check the deleted assertion was reaching for:
`git show origin/main:.agents/harness/queue-context.sh` into a temp file,
both run against this repo, `diff` clean — 2026-08-28, re-run after the
review fixes.

NOT met, and NOT satisfiable today — measured, not assumed. `main`'s queue
2026-08-28, `JOHARNESS_RUN_MODE=unsupervised
./.agents/harness/queue-context.sh`: 5 free plans, 5 waves, every wave
holding exactly one. A fan-out needs a wave of two or more, so a run right
now starts no fleet and proves nothing. Carved out as
`docs/plans/fanout-live-run.md`, which states that precondition and the
human-go requirement, rather than left as an open criterion under a plan
whose code has merged — a plan whose build is done invites the next session
to build it again.

The criterion itself: the end-to-end live-fleet run. It starts real
sessions that act autonomously and merge their own pull requests. That is a
resource and blast-radius decision for the human, and this session was not
asked to make it. Reported unmet rather than quietly dropped or quietly run.
The plan's criterion stands; whoever runs it records sessions started, pull
requests merged, and hours unattended.

## Blockers

None. The unmet criterion is now its own plan, with its precondition
stated: fanout-live-run.

## Where to look

- `joharness.sh:cmd_session_start` — resolves `run_mode`, invokes the queue
  hook as a child, exports nothing about the mode.
- `.agents/harness/queue-context.sh:399` — the fan-out line.
