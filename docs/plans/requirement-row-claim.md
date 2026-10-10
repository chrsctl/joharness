---
plan: requirement-row-claim
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: .agents/harness/queue-context.sh, joharness.sh, .agents/harness/selftest/dispatch.sh, shared:.claude/commands/manage.md
---

## Goal

A requirement cannot be claimed. A planning manager writes its workstream
file with `plan: <requirement stem>`, as `/manage` tells it to, pushes, and
stays invisible: dispatch prints no in-flight row for its branch, counts no
slot for it, and keeps offering the requirement `UNPLANNED` — so a second
planner is spawned onto the same requirement while the first runs, and a
planning pass that ended `status: blocked` (exit 4,
`.agents/docs/product/README.md`, "A requirement no plan can serve") is
respawned. Make a pushed workstream file whose `plan:` names a requirement
stem a claim on that requirement, the way it is one on a plan or research
stem.

## Scope

- `joharness.sh` — every claim-resolution site that offers
  `docs/plans/${plan}.md` and `docs/research/${plan}.md` (grep
  `for cand in "docs/plans/\${plan}.md"`; three loops at the time this plan
  was written, in `cmd_janitor` and `dispatch_retired_edges`) offers
  `docs/product/${plan}.md` as the third candidate. The in-flight walk must
  then print the planning branch's row and count its slot, same as case E
  in the retired research node (recovery: below).
- `.agents/harness/queue-context.sh` — the requirements tier (`served=`):
  a requirement whose stem a claim names (the `claims` set, `abandoned`
  excluded, same as plans at `claimed_on=`) is printed with
  `claimed on <branch>` and is not a free item; `blocked` status = held,
  not offered. Served-by-plan logic unchanged.
- `.agents/harness/selftest/dispatch.sh` — the fixture of the retired node,
  cases B and E: a pushed branch with `plan: <req stem>` shows an in-flight
  row, `slots : 3 of 4 free`, and no free `UNPLANNED` item for that
  requirement; with `status: blocked` it is still not offered.
- `.claude/commands/manage.md` — the `docs/product/<r>.md` item kind names
  the four exits of `.agents/docs/product/README.md`, "A requirement no plan
  can serve", in one line.

## Out of scope

- Any change to the `UNPLANNED` test's meaning (served = an open plan's
  `requirement:`). Settled: it stays.
- A status or `planned-out` field on requirement files. Rejected in
  product/README.md.
- `orchestrate.md` spawn rule for `UNPLANNED` — once the row carries a
  claim, the existing HOLD/claimed handling applies; touch it only if the
  selftest proves it does not.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Revert the `joharness.sh` and `queue-context.sh` change, run
  `.agents/harness/selftest/dispatch.sh` — the new cases FAIL; restore — pass.

## Where to look

- Retired node, fixture and findings:
  `git log --diff-filter=D --format=%H -1 -- docs/research/a-requirement-no-plan-can-serve.md`
  then `git show <commit>^:docs/research/a-requirement-no-plan-can-serve.md`.
- `joharness.sh` comment "Owns one: it IS a claim" — false for a claim that
  resolves to nothing today; true after this plan.
- `.agents/harness/queue-context.sh` `claimed_on=` — the plan-side claim
  test to mirror.

## Traps

- Never skip, disable or quarantine a test to get green.
- A test written for the fix must fail without it.
- No commit under `./joharness.sh protocol-paths`.
