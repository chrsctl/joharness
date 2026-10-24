---
workstream: compact-core-docs
status: in-progress
branch: claude/compact-core-docs
pr: none
plan: compact-core-docs
issue: none
session: https://claude.ai/code/session_017f52j2vqCkGcDCHNnfYXnj
agent: opus
updated: 2026-10-24
next: Run verify, spawn verifier at opus, record, retire, open PR
---

## Goal

Simplify and compact the protocol: cut `.agents/harness/AGENTS.md` (<= 90
lines) and eight reference docs (all nine <= 1150 lines), one home per rule,
no history, behaviour unchanged.

## Decisions

- A1: confirmed — all Scope quotes resolve on origin/main (plan-checker r10); base moved to a1f5af79, plans-only diff.
- A2: refuted — both guards allow a background `sleep infinity`/`tail -f` and a one-shot `pgrep -f` (plan-checker probes); the Loop step 5 background/`pgrep -f` clause stays.
- A3: confirmed — orchestrated.sh:797/802 and handover-context-compact.sh:70 pins kept on single lines.
- `--force-with-lease` exception list kept in step 3: no orchestrator doc names all three uses.
- Review-record form kept inline in Loop step 5 (one line), not pointed at TEMPLATE.md: sibling compact-role-commands points handover.md at Loop 5, so a pointer would go circular.
- Cuts past the plan's named list (feedback "What this cannot see", consumer-repos Layers/Ahead/What syncs/Upgrade prose) are rewraps and deduplication only; every rule, number and cited heading stays.

## Rejected

- Dropping the Loop step 5 background/`pgrep -f` clause: the guards do not cover it (A2).

## Review

- r1: (plan-checker) line targets not reachable with the listed cuts alone (no change: reached 90 and 1149 by compressing more prose in the same files, no rule dropped)
- r2: (plan-checker) A2 false, guards allow unbounded background and one-shot pgrep -f (fixed: clause kept, recorded under Decisions)
- r3: (plan-checker) dropping the force-with-lease exception would leave GUARD, janitor, halt contradicted (fixed: kept in step 3)
- r4: (plan-checker) review-form pointer target unnamed and circular with sibling plan (fixed: form inline in .agents/harness/AGENTS.md step 5)
- r5: (plan-checker) needs: none while sibling plans touch adjacent text (wontfix: no shared file; sibling scopes disjoint per plan-checker check 5)
- r6: (plan-checker) cited headings Layers, feedback §4 numbering, Fresh session, tree or diff missing from Traps (no change: all kept in .agents/docs/consumer-repos.md, .agents/docs/feedback.md, .agents/docs/agent-selection.md)
- r7: (plan-checker) verifier boundary line must stay a whole line (no change: .claude/agents/verifier.md line kept intact)
- r8: (plan-checker) "code names win" not a literal string (no change: heading kept word for word in .agents/docs/glossary.md)
- r9: (plan-checker) route 2 pointer wrong, Subagent is row 3 (fixed: .agents/docs/subagents.md names the Subagent row of Pick route)
- r10: (plan-checker) base sha stale and A1 evidence partial (no change: base diff is plans only)
- r11: (plan-checker) Acceptance prose bullets not runnable, no failure output named (wontfix: plan text, retired with this PR; the commands are runnable)

## Blockers

None.

## Where to look

- `docs/plans/compact-core-docs.md` — the item; its Traps list the pins.
