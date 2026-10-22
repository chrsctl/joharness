---
workstream: rules-cleanup
status: in-progress
branch: rules-cleanup
pr: none
plan: rules-cleanup
issue: none
session: https://claude.ai/code/session_01GdPHVTtzFeJHFTdksHvAHv
agent: opus
updated: 2026-10-22
next: Green ci and verify, merge origin/main, retire, PR, merge
---

## Goal

Rule files disagree with each other and with the code, load more than each
session needs, and carry history caveman.md forbids. Fix contradictions,
cut always-loaded text, move history out of docs (plan rules-cleanup).

## Decisions

- Keeper prompt is `/keeper` (the heartbeat REGISTER and spec), so the
  schedule names keeper.md and the keeper role comes from the prompt like
  every role. The title stays a guard on both files: keeper.md runs only
  titled `keeper:`, and orchestrate.md sends a keeper-titled session to
  keeper.md (live Routines still on `/orchestrate keeper` keep working
  until REPLACE, which accepts both prompts).
- Banner and `start` gain the `/keeper` route (joharness.sh, outside the
  plan's scope list): without it the banner tells a keeper it is the
  orchestrator, the very contradiction item 4 removes.
- reading-budget.sh's pointer check (outside the scope list) becomes a
  check that no `(why: history/` pointer and no history/ directory return;
  the byte bounds stay. Not a disabled test: its subject was deleted by
  the plan.
- AGENTS.md Block names `block_reason_ok` as the one list; step 2 keeps
  routing, unplanned-build, tier and boundary rules, drops the picking
  order (dispatch and the role commands own it).

## Rejected

- None yet.

## Review

- r1: (verifier) plans/README, research/README, handover/README cite Loop step 2 for the picking order it no longer holds (fixed: point at `dispatch`)
- r2: (verifier) banner said "No item named? ORCHESTRATOR" before the /keeper route, so a /keeper prompt matched the orchestrator first (fixed: keeper route before the default, `Neither?`)
- r3: (verifier) compaction pointer in handover-context.sh named only orchestrate.md or manage.md (fixed: adds keeper.md)
- r4: (verifier) up-to-date check marked every `/orchestrate keeper` Routine stale, so each session-made one paid a REPLACE (two lineage levels) and each UI-made one pushed forever (fixed: both prompts are up to date; REGISTER makes `/keeper`)
- r5: (verifier) a keeper whose tree predates keeper.md follows origin/main's orchestrate.md pointer to a file it lacks (fixed: pointer names `git show origin/main:.claude/commands/keeper.md`)
- r6: (verifier) AGENTS.md let any role block on every `block_reason_ok` word, wider than manage.md §3 (fixed: role command allows, block_reason_ok is the one list)
- r7: (verifier) start.md description, keeper.md "## 0. Start" without its file, double blank line (fixed)
- r8: (verifier) history cut dropped the `### What each role reads` heading; table had no keeper row (fixed: heading back, keeper row added)
- r9: (verifier) three measured numbers lost their source: dispatch CORE ONLY output, 30m47s, three skeptics (fixed: date or issue restored as provenance)
- r10: (verifier) rewritten scout section stated a consumer's config as present fact in a shipped doc (fixed: section deleted, it was a one-pass measurement record)
- r11: (verifier) agent-selection.md dropped which cache-read source wins (fixed: pricing page wins over the skill cache)
- r12: (verifier) deleted history files carry no recovery command (fixed: PR body carries `git log --diff-filter=D -p -- .agents/docs/history/`)
- r13: (verifier) keeper.md role-unreadable and never-retried clauses, and items 1-2, were unpinned; reading-budget scanned two files only (fixed: pins added; scan covers every .md under .agents/docs and .claude)
- r14: remaining dates (`grep -nE "20[0-9]{2}-[0-9]{2}-[0-9]{2}"`): orchestrated.md 17 to 5, each the date of a measurement a current rule or number rests on (CORE ONLY output, $5.12 re-warm, 304,615 tokens, bound-not-fresh fired session, 77,897 characters); verifier.md and conduct.md 0 before and after; keeper.md carries orchestrate.md's "(read 2026-10-16)", the date of the list_triggers account-wide read (no change)

## Blockers

None.

## Where to look

- `docs/plans/rules-cleanup.md` — the item.
