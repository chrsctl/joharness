---
workstream: token-optimization-research
status: in-progress
branch: claude/token-optimization-research-oxzyk7
pr: none
plan: token-optimization-techniques
issue: none
session: https://claude.ai/code/session_01VNm5NhCjAM1wS1zpdAEnSN
agent: opus
updated: 2026-10-09
next: Retire workstream file, open PR, merge when green
---

## Goal

Human asked: research token optimization techniques, example
wernerkasselman-au/llm-tips `token_optimization.md`. Direct ask, research
shape — node `docs/research/token-optimization-techniques.md`.

## Decisions

- Two filters: claim survives its source, AND hits a token stream this
  harness pays. Prose compression already a rule (caveman.md); bill is
  context re-reads (agent-selection.md Cost levers).
- Graduation target caveman.md: negative result, "checked, not adopted".
- Follow-up ask "anything to optimize in existing harness files": yes,
  measured. Filed two plans, not built (nothing builds unplanned):
  `role-command-trim` (orchestrate.md 8,340 words, manage.md 1,950, plus
  `context` counting role files) and `agents-chain-dedupe` (duplicates
  across root and harness AGENTS.md). Each `needs:` the queued plans that
  edit the same files first.
- Hooks checked and left alone: pretool-feedback injects once per file per
  session (second run on joharness.sh printed nothing), bash guard silent
  unless deny.

## Rejected

- Counting tokens with tiktoken: OpenAI tokenizer, undercounts Claude.
  No Anthropic credentials in container, so repo numbers are bytes/words
  from `./joharness.sh context`, labelled as such.

## Review

- r1: Format table numbers wrong model and values (verifier) (fixed)
- r1: 2.5%/0.4% arithmetic wrong, is 3.8%/0.7% (verifier) (fixed)
- r1: customer_id tokenizer, tiktoken overreach, tool-schema source, Compel single query (verifier) (fixed)
- r2: agents-chain-dedupe let root `## Handover` go; root copy is deliberate for non-Claude readers (handover/README layer 1) (verifier) (fixed — root Part 1 unchanged, harness copy is the duplicate, diff check added)
- r2: agents-chain-dedupe Goal cites step 4 text and destinations outside `scope:` (verifier) (fixed — step 4 in scope, feedback.md added, other destinations leave text in place)
- r2: caveman.md called 0.1x reads and 2,048 minimum "stale"; source still has both for some models (verifier) (fixed — reworded per model)
- r2: role-command-trim § 2 word count 4,344 does not reproduce, is 4,432 (verifier) (fixed — command added)
- r2: role-command-trim 6,265 needs --first-parent to reproduce (verifier) (fixed — command added)
- r2: line-number anchors in both plans (verifier) (fixed — named test cases instead)
- r2: caveman.md closing sentence contradicted node's "No new plan" (verifier) (fixed — names the follow-up ask that filed the plans)
- r2: role-command-trim Traps missed orchestrated-only, orchestrated-only-docs, upstream-placement-defects, abandoned-reaches-every-reader (verifier) (fixed)
- r2: branch carries plan files beyond research node + graduation target (verifier) (wontfix — plans answer a second human ask in the same session, not the research question; recorded in Decisions)
