---
plan: park-holds-only-on-pr
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: shared:joharness.sh, shared:.agents/harness/selftest/dispatch-park.sh, shared:.agents/docs/orchestrated.md, .agents/docs/orchestrator-reference.md
---

## Goal

A parked manager should hold its scope only while it waits on a real fix: a plan or pull request that names the issue it parked on. Requester, 2026-10-28: *"They should hold only if they are waiting for a PR"*, choosing "a park waiting on an issue with no PR yet frees everything".

Today a `defect: #<n>` park in state `PARKED` keeps its scope held (`joharness.sh:cmd_dispatch`: "PARKED, RESUME and RECHECK keep their scope held") even when no plan names `#<n>` anywhere. For up to `JOHARNESS_DEFECT_PLAN_HOURS` (48h), until it turns `UNPLANNED`, it blocks every plan whose scope overlaps it, though nothing is fixing the defect. In chrsctl/gx on 2026-10-28, `pm-milestones` sat 10h on #1011 and `crm-layer-verify` 2h on #1033, each holding scope while no plan named its issue.

## Scope

- `joharness.sh` (dispatch, parked-row loop): a `PARKED` claim whose `#<n>` no plan names — no `issue:` of a plan file on the base nor on a `live` branch row (git only: an open pull request counts only through a plan file it carries) — holds no scope. `dispatch_defect_state` keeps its own `named` for classification, unchanged, and exports it as `DS_NAMED` = `1` named, `0` not named with every read succeeding, `?` a read failed: `base_issues_prime`'s `git grep` exits above 1 (1 is "no match") or the base ref does not resolve, the unprimed path's base ref does not resolve, or a `live` row's plan file cannot be read (`git cat-file -e` fails). Only `0` releases: today's readers fail open (`2>/dev/null`), so the export fails closed itself. Inside the `defect:*` arm only `UNREADABLE`, `STUCK` and `UNPLANNED` join `blocked_claims` today; a `PARKED` row with `DS_NAMED=0` joins it too. From the moment a plan names `#<n>`, the park holds its scope as today, through its RESUME (RESUME is not released, as today).
  - RECHECK is left out on purpose: it takes a slot and comes back this pass, so its scope stays held.
  - The claim itself is untouched. Its `status: blocked`, its `next:`, and its RESUME and RECHECK still work. It already holds no slot.
  - Both texts of a PARKED row say which case applies. Released: flag `PARKED #<n>: a defect's, holds no slot, parked <age> ago: no plan names #<n> yet — scope released`, verdict line `PARKED #<n> <stem> (<branch>): no plan names #<n> yet, scope released, report only`. Held: the flag and verdict line as today (`… waits for a plan naming #<n> to retire, or the base to move`, `… waits for the fix, report only`). No plan stem is printed: no reader keeps it.
  - A `core path: waiting on #<N>` block is unchanged. (Corrected on the build branch: today it does NOT hold its scope while #<N> is open — dispatch releases it as any human block, `overlaps … — that branch is BLOCKED on a human: spawn, reconcile expected`; it holds again only once #<N> merges and it RESUMEs. This plan leaves that as it is.)
- `.agents/harness/selftest/dispatch-park.sh`:
  - Park on an unplanned issue → its scope is free to another plan.
  - A plan naming the issue lands → the scope is held again.
  - RESUME is unchanged.
  - A `core path: waiting on #N` block is unchanged: released while #N is open, held after its RESUME.
- `.agents/docs/orchestrated.md` and `.agents/docs/orchestrator-reference.md`: the parked-on-a-defect lifecycle, one sentence each: a park holds its scope only while a fix is planned.

## Assumptions

- A1: Scope held by a parked claim is what keeps an overlapping plan out of the free list — evidence: `joharness.sh:cmd_dispatch` ("PARKED, RESUME and RECHECK keep their scope held"; `blocked_claims`) — confidence: high
- A2: Joining `blocked_claims` releases scope without releasing the claim — evidence: `joharness.sh:cmd_dispatch` (UNREADABLE | STUCK | UNPLANNED already do this, and RESUME still reaches them) — confidence: medium. Confirm before relying on it.
- A3: `plan_names_issue` answers per issue at dispatch time, from git only — evidence: `joharness.sh:plan_names_issue` — confidence: high

## Out of scope

- Releasing the claim, writing `status: abandoned`, or `./joharness.sh release` on a park. The item resumes when the fix merges.
- Changing `JOHARNESS_DEFECT_PLAN_HOURS` / `FIX_HOURS` / `RECHECK_HOURS`.
- Reading GitHub PR state from dispatch (git only).

## Acceptance

- `.agents/harness/selftest.sh` (runs the `dispatch-park` topic; it is not runnable alone): prints `0 failed`, with these new cases in `dispatch-park.sh` passing, each on a fixture where claim A is parked `defect: #<n>` on an issue no plan names, scope `src/<a>`, and plan B scopes `src/<a>`:
  - dispatch prints B's row `overlaps <a> on src/<a> (claimed on <branch>) — that branch is BLOCKED on a human: spawn` and A's verdict line `no plan names #<n> yet, scope released`. Failure: B reads `HOLD — overlaps`.
  - a plan with `issue: <n>` lands on the base, scoped elsewhere: B reads `HOLD — overlaps <a>`. Failure: B still spawns.
  - the same plan on a live branch instead of the base: B reads `HOLD — overlaps <a>`. Failure: B spawns.
  - the base's plan scan unreadable (fail closed; fixture: a `git` on PATH that exits 2 on `grep`, the base ref intact): B reads `HOLD — overlaps <a>`. Failure: B spawns, or a row reads `scope released`.
  - existing RESUME and `core path: waiting on #N` cases pass unchanged. Failure: any of them FAILs.
- `./joharness.sh ci` prints `ci: pass`; `./joharness.sh verify` prints `0 failed`. Failure: `ci: fail`, or a non-zero failed count.

## Where to look

- `joharness.sh:cmd_dispatch`: the parked-row `case "$dst"` and the `blocked_claims` it feeds.
- `joharness.sh:cmd_dispatch_defect_state`: PARKED / UNPLANNED classification.
- `joharness.sh:plan_names_issue`.

## Traps

- Fail closed: an unreadable plan scan is "planned", so the park keeps holding its scope. Never release on an unreadable answer.
- Two or more parks on one issue hold every spawn row anyway (`HOLD — red base`, orchestrated.md, The one stop). Releasing a single park's scope does not touch that hold.
- A released scope can be taken by another plan whose work then collides with the parked branch at RESUME. That is the existing `conflict:` / reconcile path, not a reason to keep holding.
