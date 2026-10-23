---
workstream: roles-beyond-cap
status: blocked
branch: claude/roles-beyond-cap
pr: 565
plan: roles-beyond-cap
issue: none
session: https://claude.ai/code/session_018FNpTGRJapDHTuQhgkbGwR
agent: opus
updated: 2026-10-23
next: defect: #566: pretool-bash-guard heredoc timing reds lint on pull_request runs; resume = retire this file and the plan again, finish, merge PR #565
---

## Goal

Repo owner (relayed from chrsctl/gx): `JOHARNESS_MAX_MANAGERS` caps managers
only; curator and clerk must still spawn while every manager slot is full.

## Decisions

- Surveyor and freer leave the cap too (owner's lean: neither builds a plan).
  Freer: at most one in flight, FREEABLE rows no longer count as free manager
  items. Surveyor: never subtracted in code; the OVERLAP-BOUND trigger keeps
  its idle-slot condition, since it detects plans held while slots idle.
- `JOHARNESS_MAX_MANAGERS=0` holds every role, FREEABLE rows included
  (`HOLD — ... the human's pause`).
- Freer: one `freer DUE` tail line, valid under any verdict but PAUSED, so a
  verdict that says "spawn nothing" or "wait" (OVERLAP-BOUND, a full fleet)
  speaks for managers only. OVERLAP-BOUND can now fire beside a FREEABLE row;
  both spawn.
- A blocked freer counts as in flight for one-at-a-time (as a blocked curator
  does) and holds no slot.
- `JOHARNESS_PENDING_SPAWNS` counts manager `@new` entries only.

## Rejected

- Curator and clerk keep taking a slot, with a reserved role slot: still holds a role behind a full fleet once reserved slots fill, and spends a manager's money on a role's wait.

## Review

- r1: (verifier) no test pinned the FREEABLE case of the DRAINED verdict; deleting `role_will_spawn` for it stayed green (fixed: own fixture in dispatch-branch-plans.sh asserts `a role is due` and `freer DUE`)
- r2: (verifier) OVERLAP-BOUND / 0-slot verdicts said spawn nothing beside a spawnable FREEABLE row (fixed: `freer DUE` tail line, any verdict but PAUSED; reference row says so)
- r3: (verifier) JOHARNESS_MAX_MANAGERS=0 did not hold the FREEABLE row (fixed: HOLD row under the pause, tested)
- r4: (verifier) orchestrated.md conduct row still said a role is held for a slot (fixed)
- r5: (verifier) a freer or surveyor `@new` ledger entry fed JOHARNESS_PENDING_SPAWNS and cost a slot until its first push (fixed: orchestrate.md §1 counts manager `@new` entries only)
- r6: (verifier) a blocked freer did not hold a second freer, a blocked curator does (fixed: blocked counts as in flight for one-at-a-time, no slot; tested)
- r7: (verifier) code commit did not update the workstream file (fixed: this commit carries it with the fixes)
- r8: (verifier) new orchestrated.md paragraph narrated the change, mixed reasons, role table lacked a freer row (fixed: rule-only rewrite, freer row added)
- r9: (verifier) 246h incident figure in a selftest comment (fixed: removed; it lives in the PR body)
- r10: (verifier) second pass on the fix commit: five mutants all red, no defect in r1-r9 fixes (no change)
- r11: (verifier) FREEABLE rows and `freer DUE` do not hold on a stale view (fetch failed, DISPATCH_FETCH=0), where clerk, conduct and scout do (wontfix: FREEABLE behaved so on main, not a regression; holding it re-plumbs every FREEABLE fixture, outside the cap change; flagged in the PR body)
- r12: (verifier) orchestrated.md FREEABLE row called the freer a manager; orchestrate.md §3 opened with "up to slots" before the role exemption (fixed)
- r13: (verifier) a live freer is counted in dispatch's "N manager(s) in flight" wording (wontfix: on main already, the printed action is right; wording only)

## Blockers

Parked on #566 (manage-reference § Defect, step 2: blocks the merge, no
issue matched). GitHub `lint` on head eb54cbbb fails only on
`pretool-bash-guard` "a 20,000-line heredoc ... 15s (wanted < 15s)", twice
(run 39933056125, both attempts); PR #564's run failed identically before
this branch merged main, and the diff touches neither the guard nor its
test. Code, review and `finish: pass` are done; resume = re-run step 7.

## Where to look

- `joharness.sh:cmd_dispatch` — slot arithmetic and role tail lines.
