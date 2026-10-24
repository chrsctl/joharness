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
next: Retire plan and workstream file, open PR, run finish, merge
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
- Cuts past the plan's named list (feedback "What this cannot see", "Why `feedback` exists" folded into stage 4, consumer-repos Layers/Ahead/What syncs/Upgrade prose) are rewraps and deduplication; the verifier's over-cut list (r12-r20) was restored.

## Rejected

- Dropping the Loop step 5 background/`pgrep -f` clause: the guards do not cover it (A2).
- Mechanical reflow of whole docs to 80 columns: added lines (prose had been widened) and would split the verifier.md boundary pin line.

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

- r12: (verifier) .claude/agents/verifier.md said a command out of a hunk is "not a finding", contradicting the section (fixed: now "execution, not verification")
- r13: (verifier) .claude/agents/plan-checker.md lost "Silence is not a result." (fixed)
- r14: (verifier) .agents/docs/caveman.md lost "style never grows output" and "keep correct verb form" (fixed)
- r15: (verifier) .agents/docs/feedback.md §4 lost "never drop it silent" and the consumer-PR-does-not-count clause (fixed)
- r16: (verifier) .agents/docs/consumer-repos.md lost eight symptoms/negations: CRLF bash failure, cmd.exe, below the pinned block, autocrlf ships CRLF, re-running changes nothing, other two leave joharness-update, never in a new workflow, commit there first, files their failures (fixed)
- r17: (verifier) .agents/docs/feedback.md disposition mechanism cut, only example left (fixed)
- r18: (verifier) .agents/docs/agent-selection.md lost mid-build gate behaviour and the model behaviour behind findings 1-2 (fixed; findings 3-5 titles already carry it)
- r19: (verifier) .agents/harness/AGENTS.md step 5 dropped which file holds `## Review` and what review prints (fixed)
- r20: (verifier) .agents/harness/AGENTS.md "label human-review this branch's" missing "on" (fixed)
- r21: (verifier) workstream Decisions claimed every rule stays while r12-r18 were open (fixed: bullet reworded)
- r22: (verifier) AGENTS.md reached 90 partly by widening lines, words fell about 10 percent (wontfix: plan target is lines; no width rule exists, and every cut sentence was a real duplicate or history)

## Blockers

None.

## Where to look

- `docs/plans/compact-core-docs.md` — the item; its Traps list the pins.
