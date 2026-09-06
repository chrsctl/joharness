---
workstream: dispatch-held-plan-blocks-queue
status: review
branch: claude/dispatch-held-plan-blocks-queue
pr: none
plan: none
issue: none
agent: opus
updated: 2026-09-06
next: Review, then merge. Consumers pick the fix up at their next sync.
---

## Goal

Found in a consumer (`chrsctl/gx`, 2026-09-06): `dispatch` reported
`NOT DRAINED — 36 item(s) waiting behind others: spawn nothing this pass`
with three of four worker slots free. Every WAIT line named one plan,
`crm-record-import`, which was itself `HOLD` behind the single manager in
flight — so a plan that could not start was serialising the whole queue.

The cause is in the wave partition, not in any plan. The partition is
computed over every free plan, a HELD plan among them; it therefore takes a
wave, and every plan whose scope meets it is told to WAIT for a pass it will
sit out. `orchestrated.md` already said the rule the code was missing — a
wave-2 plan waits while its partner is "free in the same pass" — so this is
the code diverging from its own documented rule.

## Decisions

- Fixed in `queue-context.sh`, not in `dispatch`: the hook has both facts
  (which plans are free, which are held), and deriving "held" a second time
  in the entrypoint is the rule-spelled-twice shape this repo keeps paying
  for.
- A hold behind a **BLOCKED** branch is released by dispatch, so that plan
  *does* run and stays in the partition. The hook needs to know which
  claiming branches are blocked; it now reads `status` from the claiming
  workstream file it was already opening for `plan`, so no second walk. Only
  the exact word `blocked` counts — the graph's vocabulary, so a workstream
  writing `in-progress  BLOCKED: …` cannot forge the release.
- A held plan now carries **no wave** on its dispatch line. That is a
  visible output change with three assertions updated: a wave number is a
  statement about what runs concurrently, and a held plan is not in that set.

## Rejected

- Releasing a WAIT in `dispatch` whenever its note named a held plan. The
  note carries only the FIRST collision, so a plan conflicting with both a
  held and a running peer would have been released wrongly. The same
  first-only shape turned out to be live in the release path itself — v1.

## Review

Edge to main, opus depth: three adversarial passes plus
`.claude/agents/verifier.md` at opus. Every number the verifier gave was
re-derived here before acting on it, and every one held.

- v1: (verifier) the fix opened a hole it did not close. A plan held by TWO
  managers — one stopped on a human, one live — is held by the live one, but
  `dispatch` read only the FIRST hold line (`awk … exit`) to decide the
  release. With the blocked holder's line printed first it released the plan
  into the live collision, and because the hook now leaves a held plan out of
  the partition, it spawned with nothing partitioned against it either: one
  plan, two readers, two answers. The release now requires EVERY holder to be
  blocked, which also closes the pre-existing half — releasing into a live
  collision was wrong before this branch too. (fixed)
- v2: (verifier) `refute "wave 1: held"` was vacuous: `beta` leads that wave,
  so the string never appears with or without the fix — the shape this repo
  lists among its seven, in the test written to catch one of them. The wave
  lines are now extracted first and membership refuted against those alone,
  and the check goes red on the reverted hook. (fixed)
- v3: (verifier) with every free plan held, the hook printed a header
  promising waves and then none, over a count that included the plans the
  next line says are not partitioned. It now says `none: nothing free is
  partitioned this pass.` (fixed)
- v4: (verifier) the 36-items-behind-one number carried a repo and a date but
  no command. It now carries `./joharness.sh dispatch` and the commit.
  (fixed)

Two of the verifier's checks are worth recording as evidence rather than as
findings: supervised and unsupervised hook output are byte-identical to
`origin/main` on a tree that has holds (re-run here against a real 37-plan
consumer checkout), and no other reader of `claims` breaks on the third
column.

A note on method, because it cost two rounds: `git checkout -- <path>`
reverts to the INDEX, and the hook fix was already committed, so the first
"revert and watch it fail" run silently restored the fix and reported six
assertions passing that could not have been discriminating. The revert that
means anything is `git checkout origin/main -- <path>`. With it: 8 red on the
hook fix, 2 red on the dispatch fix, 1688 green with both.

## Blockers

None.
