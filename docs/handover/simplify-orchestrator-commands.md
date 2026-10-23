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
next: Run ci, spawn the verifier on the branch diff, record, then finish
---

## Goal

Simplify the orchestrator and keeper role text: one statement per rule, no
history, no behaviour change (plan simplify-orchestrator-commands).

## Decisions

- A1: confirmed — quotes found on origin/main dbe65938; the four files did not change since 860a3f9c.
- A2: confirmed — dispatch prints `verdict   : DEGRADED — shallow clone` (`joharness.sh:cmd_dispatch`).
- A3: confirmed — `orctext` pins the ledger grammar and lead line in orchestrate.md; plan fixed to keep them.
- No `cmd_keeper` exists: LIVE is prose only. keeper.md's clauses are the reference's two halves read on the sessions it can name; one line says so. The reference adds `enabled` true to "pending wake", as keeper.md already had (a fired one-shot is not pending).
- keeper.md keeps its own `create_session` parameters: the keeper reads no reference (`orchestrated.md` reading table).
- Four-file line total cannot fall by moving text between the counted files; acceptance now bounds orchestrate.md (always loaded) and caps the total.

## Rejected

- Moving the ledger grammar out of orchestrate.md: `orctext` selftest pins red it.

## Review

- r1: (plan-checker) ledger grammar, lead line and spawn-prompt lead text are pinned in orchestrate.md; plan said move them (fixed: plan keeps them)
- r2: (plan-checker) "second never act on a lead" ambiguous; the pinned one is the Report's (fixed: plan names the table cell)
- r3: (plan-checker) Report heading and heartbeat sentence pinned in place (no change: kept, only unpinned lines moved)
- r4: (plan-checker) scout trigger (i) to (iii) pinned and cited by scout.md, orchestrated.md (fixed: plan cuts only the SCOUT COMMENT definition)
- r5: (plan-checker) § Resume carries the `next:` wording joharness.sh matches (fixed: plan keeps texts, cuts only restated Relay mechanics)
- r6: (plan-checker) `cmd_keeper` anchor does not exist (fixed: anchor removed, plan states no code counts LIVE)
- r7: (plan-checker) keeper and reference LIVE differ only by the keeper's tools; both pinned (fixed: one line names them the same definition)
- r8: (plan-checker) create_session parameters differ per role and are pinned (fixed: only `source_url` and `clone_depth` written once)
- r9: (plan-checker) all keeper.md role-title notes pinned (fixed: plan says none goes)
- r10: (plan-checker) verify red on the untouched tree (no change: re-run here printed `6 passed, 0 failed`, docker egress was transient)
- r11: (plan-checker) consumer-side and PR-body acceptance items are not runnable (no change: a shipping plan must name the consumer-side check, plans README; PR body item is a reviewer check)
- r12: (plan-checker) acceptance grep missed the self-attach aside (fixed: pattern extended)
- r13: (plan-checker) 780-line bound unreachable: moves stay inside the counted files (fixed: bound on orchestrate.md, total capped at 905)
- r14: REGISTER's keeper `create_session` omits `clone_depth: 5000` (wontfix: behaviour change, separate plan)
- r15: (plan-checker) A1 names 860a3f9c, origin/main is dbe65938 (no change: the four files are identical)

## Blockers

None.

## Where to look

- `.agents/harness/selftest/orchestrated.sh` — pins phrases in all four files.
