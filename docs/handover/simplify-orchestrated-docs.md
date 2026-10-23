---
workstream: simplify-orchestrated-docs
status: in-progress
branch: simplify-orchestrated-docs
pr: none
plan: simplify-orchestrated-docs
issue: none
session: https://claude.ai/code/session_01UmhELGWH7NQD7X2oy1Db8D
agent: opus
updated: 2026-10-23
next: Run ci, verify, verifier; then retire and open the pull request
---

## Goal

Simplify the protocol: cut orchestrated.md, agent-selection.md and
subagents.md to current rule, mechanism and number (plan
simplify-orchestrated-docs).

## Decisions

- A1: confirmed — orchestrated.sh:336-346 and :618-622 pin phrases; all
  kept byte-exact (whitespace-folded). knobs-declared asserts rows only.
- A2: confirmed — quotes match origin/main; 860a3f9c..origin/main does not
  touch the three docs.
- Source dates on the Lineup facts dropped too: the scope says delete the
  dated lines; "verify against Models API when stale" stays the rule.
- Churn defaults: both prose copies (orchestrated.md Loops, agent-selection
  Review churn) point at the knob table; the "review churn" heading stays.
- "Why the first row can fail" kept as mechanism only ("A carried plan reads
  as a leftover"); copies of the Bounds and Roles text in later sections cut.
- A few edited paragraphs rewrapped where that saved a line: whitespace
  only; selftests fold whitespace. Some lines stay over 80, as in the base.
- caveman.md "Measured number keeps its command and when" outranks the plan
  where a reading is still the current basis: dates kept on the Lineup
  sources, subagents.md runtime facts and the "Run now" reading; the
  2026-10-16 Bound-not-fresh date stays cut (the plan's acceptance regex
  forbids it), its command kept. Supersedes PR548 r9/r14 only where the plan
  names the cut.

## Rejected

- None yet.

## Review

- r1: (plan-checker) the 840 line bound is reachable by rewrapping, against "no rewriting for style" (wontfix: the rewrap is whitespace only, about 13 lines; the rest is deleted history and duplicate copies)
- r2: (plan-checker) acceptance regex misses other dated lines (2026-10-23, 2026-08-25, 2026-10-07, 30m47s, 117 minutes) (fixed: all removed; `git grep -nE '20[0-9]{2}-[0-9]{2}-[0-9]{2}'` on the three docs prints nothing)
- r3: (plan-checker) Lineup source dates are ambiguous under "the dated lines" (fixed: kept as provenance, see Decisions and r10)
- r4: (plan-checker) churn numbers live in agent-selection.md, not orchestrated.md (fixed: both copies point at the knob table; heading kept)
- r5: (plan-checker) the first-row story holds live mechanism (fixed: mechanism kept as one paragraph)
- r6: (plan-checker) consumer-side acceptance line is not runnable, and no item states failure (no change: same `ci` command already listed)
- r7: (plan-checker) selftest/dispatch.sh:602 cites a missing orchestrated.md "Runs" heading (wontfix: pre-existing, in a selftest this plan may not edit; reported as a lead)
- r8: (plan-checker) incoming heading citations must keep resolving (no change: every cited heading kept)
- r9: (plan-checker) A2 hash stale, A1 evidence command prints file names not phrases (no change: claims hold)

## Blockers

None.

## Where to look

- `.agents/harness/selftest/orchestrated.sh` — phrases that must survive.
- r10: (verifier) command and date stripped from readings still the current basis, against caveman.md (fixed: restored on Lineup sources, subagents.md, Run now and the fired-session command; 2026-10-16 wontfix: plan acceptance bans it)
- r11: (verifier) subagents.md lost "plans and managers' prompts mean the second one" (fixed: restored above the table)
- r12: (verifier) agent-selection.md lost "Ambiguity is executed literally or asked back to a human" (fixed: restored)
- r13: (verifier) Fresh session bullet dropped the TTL condition and the manager re-check trigger (fixed: rewritten with both)
- r14: (verifier) frozen-cost "nothing bounds that" reason lost (fixed: restored)
- r15: (verifier) injection sentence lost "rightly" (fixed: restored)
- r16: (verifier) Decisions claimed 78-column rewrap, false; churn pointer read as a bare heading (fixed: claim corrected, pointer says "knob table")
