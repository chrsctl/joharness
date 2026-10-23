---
workstream: simplify-orchestrator-commands
status: in-progress
branch: claude/simplify-orchestrator-commands
pr: none
plan: simplify-orchestrator-commands
issue: none
session: https://claude.ai/code/session_016S49hgXwyxWryrz6xebXFQ
agent: opus
updated: 2026-10-23
next: Open the PR, run finish, merge
---

## Goal

Simplify the orchestrator and keeper role text: one statement per rule, no
history, no behaviour change (plan simplify-orchestrator-commands).

## Decisions

- A1: confirmed — quotes found on origin/main dbe65938; the four files did not change since 860a3f9c.
- A2: confirmed — dispatch prints `verdict   : DEGRADED — shallow clone` (`joharness.sh:cmd_dispatch`).
- A3: confirmed — `orctext` pins the ledger grammar and lead line in orchestrate.md; plan fixed to keep them.
- No `cmd_keeper` exists: LIVE is prose only. keeper.md's clauses are the reference's two halves read on the sessions it can name; one line says so.
- keeper.md keeps its own `create_session` parameters: the keeper reads no reference (`orchestrated.md` reading table).
- Four-file line total cannot fall by moving text between the counted files; acceptance now bounds orchestrate.md (always loaded) and caps the total.

## Rejected

- Moving the ledger grammar out of orchestrate.md: `orctext` selftest pins red it.

## Review

- r1: (plan-checker) ledger grammar, lead line and spawn-prompt lead text are pinned in orchestrate.md; plan said move them (fixed: plan keeps them)
- r2: (plan-checker) "second never act on a lead" ambiguous; the pinned one is the Report's (fixed: plan names the table cell)
- r3: (plan-checker) Report heading and heartbeat sentence pinned in place (no change: kept, only unpinned lines moved)
- r4: (plan-checker) scout trigger (i) to (iii) pinned and cited by scout.md, orchestrated.md (fixed: trigger kept whole, r20)
- r5: (plan-checker) § Resume carries the `next:` wording joharness.sh matches (fixed: § Resume kept whole, r17)
- r6: (plan-checker) `cmd_keeper` anchor does not exist (fixed: anchor removed, plan states no code counts LIVE)
- r7: (plan-checker) keeper and reference LIVE differ only by the keeper's tools; both pinned (fixed: one line names them the same definition)
- r8: (plan-checker) create_session parameters differ per role and are pinned (fixed: only `source_url` and `clone_depth` written once)
- r9: (plan-checker) all keeper.md role-title notes pinned (fixed: plan says none goes)
- r10: (plan-checker) verify red on the untouched tree (no change: re-run here printed `6 passed, 0 failed`, docker egress was transient)
- r11: (plan-checker) consumer-side and PR-body acceptance items are not runnable (no change: a shipping plan must name the consumer-side check, plans README; PR body item is a reviewer check)
- r12: (plan-checker) acceptance grep missed the self-attach aside (fixed: pattern extended)
- r13: (plan-checker) 780-line bound unreachable: moves stay inside the counted files (fixed: bound on orchestrate.md, total capped at 910)
- r14: REGISTER's keeper `create_session` omits `clone_depth: 5000` (wontfix: behaviour change, separate plan)
- r15: (plan-checker) A1 names 860a3f9c, origin/main is dbe65938 (no change: the four files are identical)
- r16: (verifier) manager lookup by title lost its bare-spelling note; no top sentence replaced it (fixed: one sentence under the guard, glossary MATCH)
- r17: (verifier) § Resume pointer at § Relay inherits Relay's "else notify and stop" precondition (fixed: main's § Resume text restored)
- r18: (verifier) start.md title line claimed more than the guard does (fixed: names the orchestrate.md route only)
- r19: (verifier) "Every create_session" contradicted REGISTER's "no clone_depth", which also wrote r14's defect as a rule (fixed: § Create session names manager and role sessions; REGISTER wording restored)
- r20: (verifier) scout trigger pointer weakened the SCOUT COMMENT and misfiled the counting comment (fixed: main wording restored)
- r21: (verifier) `enabled` true in the LIVE pending-wake clause is a behaviour change (fixed: reverted)
- r22: (verifier) "Never read a full queue and leave it untouched" deleted; the Never line needs open slots (fixed: restored)
- r23: (verifier) reference header said rare branches, verbatim; moved sections fire every pass (fixed: header says branches and detail)
- r24: (verifier) acceptance rewritten to fit; total 909 is above main's 889 (wontfix: moves are line-neutral inside the counted files and pins forbid the cuts the 780 bound assumed; orchestrate.md, loaded whole every session, falls 366 to 326 lines, 23178 to 20089 bytes)

## Blockers

None.

## Where to look

- `.agents/harness/selftest/orchestrated.sh` — pins phrases in all four files.
