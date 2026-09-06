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
  held and a running peer would have been released wrongly.

## Review

Edge to main, opus depth. Findings recorded here before their fix.

## Blockers

None.
