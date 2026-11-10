---
plan: defect-park-own-issue
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: joharness.sh, .agents/harness/selftest/dispatch-park.sh, .agents/harness/selftest/analysis.sh, .claude/commands/manager.md, .claude/commands/orchestrator.md, .agents/docs/manager-reference.md, .agents/docs/orchestrated.md
---

## Goal

A manager whose plan has `issue: N` parked `next: defect: #N: …` on its own
issue (chrsctl/gx, 2026-11-10: plan `timeline-drag-start-date`, `issue:
1323`, head eef91cf82f76, parked 31h+). `defect:` is for a defect OUTSIDE the
item (manager.md §3), but nothing refuses it: dispatch prints a plain
`PARKED #N` row that can never clear — RESUME waits for a plan naming #N to
retire (the parked branch's own), RECHECK needs no plan naming #N, STUCK only
notifies. Dispatch must read such a park as `INVALID BLOCK?` (not the human's;
the orchestrator asks it to do the work or name a real reason), and
manager.md / manager-reference § Defect must say not reproducing your own
issue is work: do the plan's goal, or close it as not reproduced with
evidence.

## Scope

- `joharness.sh` — one reader `own_defect_park` (plan path + raw next: + ref
  → true when the defect number equals the plan's `issue:`); dispatch's
  `defect:` branch routes such a claim to the human-block branch with an
  `INVALID BLOCK?` flag naming why; `analysis` prints the same condition.
- `.agents/harness/selftest/dispatch-park.sh` — fixture: plan `issue: 31`,
  claim parks `defect: #31: …` → row carries `INVALID BLOCK?`, no `PARKED #31`.
- `.agents/harness/selftest/analysis.sh` — the same through `analysis`, if its
  fixture reaches it cheaply.
- `.claude/commands/manager.md` §3, `.agents/docs/manager-reference.md`
  § Defect, `.agents/docs/orchestrated.md` The one stop,
  `.claude/commands/orchestrator.md` the INVALID BLOCK? row — the rule, one
  line each.

## Assumptions

- A1: the plan's `issue:` is readable from the branch ref at the claim's plan
  path — evidence: `joharness.sh:dispatch_defect_state` reads files at
  `refs/remotes/origin/<branch>` — confidence: high.
- A2: an `INVALID BLOCK?` row already makes the orchestrator message the
  manager and never respawn — evidence: `.claude/commands/orchestrator.md`
  INVALID BLOCK? row — confidence: high.

## Out of scope

- Closing the gx issue or touching gx's branch: the consumer's.
- Any change to `block_reason_ok`'s word list: `defect:` stays a reason.
- Refusing the park at the manager's push (a guard): dispatch is the reader.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed; the new dispatch-park cases pass and
  fail with the `joharness.sh` change reverted.

## Where to look

- `joharness.sh:block_reason_ok` — the reason list.
- `joharness.sh:dispatch_defect_state` — the park machinery a self-park must skip.
- `joharness.sh:defect_issue` — the number reader.
- `.agents/docs/orchestrated.md` — "The one stop".
- `.agents/docs/manager-reference.md` — "## Defect".

## Traps

- Never skip or disable a test to get green.
- A test for the fix must FAIL without it.
