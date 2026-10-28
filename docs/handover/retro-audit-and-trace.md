---
workstream: retro-audit-and-trace
status: in-progress
branch: claude/retro-audit-and-trace
pr: none
plan: retro-audit-and-trace
issue: none
session: https://claude.ai/code/session_01J1YMK5rjqiJNckSSTh2gN7
agent: opus
updated: 2026-10-28
next: Selftests (scout.sh, retro.sh, role.sh, orchestrated.sh, reading-budget.sh) and docs to the new names; new CONCERN cases in retro.sh
---

## Goal

Merge conduct and retro into ONE role, retro, with modes audit (today's
conduct) and trace (today's retro); audit CONCERNs become trace's input.

## Decisions

- A1: confirmed — `joharness.sh:cmd_role` case `clerk|scout|conduct|retro`.
- A2: confirmed — `retro_logged` prints the ledger's session column; `retro_candidates` drops those.
- A3: confirmed — plan-checker counted 483 of 490 deletions carrying `session:` on origin/main (same 7 missing).
- A4: confirmed — KNOBS rows `JOHARNESS_CONDUCT_*`, `JOHARNESS_RETRO_*` scoped `dispatch`.
- A5: confirmed — `.agents/scripts/sync-to-consumer.sh:36` "Removals are not handled".
- Open choices settled in the plan's "Settled at build" block (plan-checker r1-r10).

## Rejected

## Review

- r1: (plan-checker) audit's off gate reads conduct.md; plan never names the new gate file (fixed: plan names retro-audit.md)
- r2: (plan-checker) spawn-line acceptance passes unchanged (fixed: acceptance greps on /retro-audit, selftest bullet added)
- r3: (plan-checker) CONCERN-only trace due or empty undecided (fixed: due)
- r4: (plan-checker) retire undefined (fixed: full-history D commit, committer UTC day <= audit date)
- r5: (plan-checker) CONCERN row branch cell unspecified (fixed: branch = stem)
- r6: (plan-checker) retro.md never reads another role's ledger vs new read list (fixed: same role now, rule stays)
- r7: (plan-checker) conf-keys.sh has no CONDUCT comment (fixed: the rows' text)
- r8: (plan-checker) same last line ambiguous (fixed: same GO shape, one code path)
- r9: (plan-checker) selftest and consumer acceptance items name no command (wontfix: selftest bullets run under ./joharness.sh ci; the consumer item is SHIPS, checked after sync)
- r10: (plan-checker) stale-branch rule for retro-audit-* unmentioned (fixed: covered as conduct-*)
- r11: (plan-checker) A3 count unreproduced (no change: same 7 missing, consistent)
- r12: (plan-checker) old 🧐 titles may stop matching (no change: no code matches the title; the glossary is the only reader)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_conduct`, `joharness.sh:cmd_retro`, `joharness.sh:cmd_role` — the two halves and the shared prelude.
