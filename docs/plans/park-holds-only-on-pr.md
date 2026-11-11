---
plan: park-holds-only-on-pr
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: shared:joharness.sh, shared:.agents/harness/selftest/dispatch-park.sh, shared:.agents/docs/orchestrated.md, .agents/docs/orchestrate-reference.md
---

## Goal

A parked manager should hold its scope only while it waits on a real fix: a plan or pull request that names the issue it parked on. Requester, 2026-10-28: *"They should hold only if they are waiting for a PR"*, choosing "a park waiting on an issue with no PR yet frees everything".

Today a `defect: #<n>` park in state `PARKED` keeps its scope held (`joharness.sh:dispatch`: "PARKED, RESUME and RECHECK keep their scope held") even when no plan names `#<n>` anywhere. For up to `JOHARNESS_DEFECT_PLAN_HOURS` (48h), until it turns `UNPLANNED`, it blocks every plan whose scope overlaps it, though nothing is fixing the defect. In chrsctl/gx on 2026-10-28, `pm-milestones` sat 10h on #1011 and `crm-layer-verify` 2h on #1033, each holding scope while no plan named its issue.

## Scope

- `joharness.sh` (dispatch, parked-row loop): a `PARKED` claim whose `#<n>` no plan names, on the base or on a live branch row, holds no scope. The check is the one `dispatch_defect_state` already runs for UNPLANNED (`plan_names_issue`). Today only `UNREADABLE`, `STUCK` and `UNPLANNED` join `blocked_claims`; this case joins it too. From the moment a plan names `#<n>`, the park holds its scope as today, until that plan retires and RESUME fires.
  - The claim itself is untouched. Its `status: blocked`, its `next:`, and its RESUME and RECHECK still work. It already holds no slot.
  - The row text says which case applies, e.g. `PARKED #<n>: no plan names #<n> yet — scope released` versus `PARKED #<n>: waits for <plan> — scope held`.
  - A `core path: waiting on #<N>` block (a human PR exists by construction) keeps holding its scope, unchanged.
- `.agents/harness/selftest/dispatch-park.sh`:
  - Park on an unplanned issue → its scope is free to another plan.
  - A plan naming the issue lands → the scope is held again.
  - RESUME is unchanged.
  - A `core path: waiting on #N` block still holds its scope.
- `.agents/docs/orchestrated.md` and `.agents/docs/orchestrate-reference.md`: the parked-on-a-defect lifecycle, one sentence each: a park holds its scope only while a fix is planned.

## Assumptions

- A1: Scope held by a parked claim is what keeps an overlapping plan out of the free list — evidence: `joharness.sh:dispatch` ("PARKED, RESUME and RECHECK keep their scope held"; `blocked_claims`) — confidence: high
- A2: Joining `blocked_claims` releases scope without releasing the claim — evidence: `joharness.sh:dispatch` (UNREADABLE | STUCK | UNPLANNED already do this, and RESUME still reaches them) — confidence: medium. Confirm before relying on it.
- A3: `plan_names_issue` answers per issue at dispatch time, from git only — evidence: `joharness.sh:plan_names_issue` — confidence: high

## Out of scope

- Releasing the claim, writing `status: abandoned`, or `./joharness.sh release` on a park. The item resumes when the fix merges.
- Changing `JOHARNESS_DEFECT_PLAN_HOURS` / `FIX_HOURS` / `RECHECK_HOURS`.
- Reading GitHub PR state from dispatch (git only).

## Acceptance

- `bash .agents/harness/selftest/dispatch-park.sh`: the new cases pass, existing cases unchanged apart from row wording.
- `./joharness.sh ci` and `./joharness.sh verify` are green.
- Fixture with claim A parked on unplanned #7, scoping `src/a.py`, and free plan B scoping `src/a.py`: `./joharness.sh dispatch` lists B under `spawn`. Adding a plan with `issue: #7`: B is held again.
- Consumer-side check: after sync, a consumer's dispatch shows a park on an unplanned issue as `scope released`.

## Where to look

- `joharness.sh:dispatch`: the parked-row `case "$dst"` and the `blocked_claims` it feeds.
- `joharness.sh:dispatch_defect_state`: PARKED / UNPLANNED classification.
- `joharness.sh:plan_names_issue`.

## Traps

- Fail closed: an unreadable plan scan is "planned", so the park keeps holding its scope. Never release on an unreadable answer.
- A released scope can be taken by another plan whose work then collides with the parked branch at RESUME. That is the existing `conflict:` / reconcile path, not a reason to keep holding.
