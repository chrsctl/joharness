---
plan: requirement-row-claim
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: .agents/harness/queue-context.sh, joharness.sh, .agents/harness/selftest/dispatch.sh, shared:.claude/commands/manage.md, shared:.agents/docs/product/README.md, .agents/docs/handover/TEMPLATE.md
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
  `docs/product/${plan}.md` as the third candidate — plan and research
  first, so a stem naming both a plan and a requirement (commit `0944070c`
  held `orchestrated-mode` as both) resolves to the plan. Those loops alone
  do NOT make the row (verifier, read against this plan's draft):
  - `lint_graph` (grep `no such plan or question`) reds a workstream
    `plan:` naming a requirement — accept `docs/product/` there too.
  - the in-flight walk builds rows from a `sed` matching only
    `docs/(plans|research)/` lines (grep `docs/\(plans\|research\)` in
    `joharness.sh`) — extend it to `docs/product/`.
  - `drain_requirement` offers the first line under "Requirements without
    plans" whatever its label — skip a claimed one.
  - `dispatch_retired_edges` skips any branch ADDING a workstream file
    ("Owns one: it IS a claim") — true once the above holds; check it.
  Acceptance is case E of the retired research node (recovery: below): the
  planning branch's row printed, its slot counted.
- `.agents/harness/queue-context.sh` — the requirements tier (`served=`):
  a requirement whose stem a claim names (the `claims` set, `abandoned`
  excluded, same as plans at `claimed_on=`) is printed with
  `claimed on <branch>` and is not a free item; `blocked` status = held,
  not offered. Served-by-plan logic unchanged.
- `.agents/harness/selftest/dispatch.sh` — the fixture of the retired node,
  cases B and E: a pushed branch with `plan: <req stem>` shows an in-flight
  row, `slots : 3 of 4 free`, and no free `UNPLANNED` item for that
  requirement; with `status: blocked` it is still not offered.
- `.claude/commands/manage.md` — the exits line already landed; touch only
  if the claim needs wording there.
- `.agents/docs/product/README.md` — "Gap still open" paragraph: rewrite
  as closed, saying how a requirement is claimed.
- `.agents/docs/handover/TEMPLATE.md` — `plan` comment: a requirement is
  claimed through the same field, by its stem.

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
