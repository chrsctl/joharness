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
next: Graduate research into caveman.md if human agrees, then PR carrying both plans
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
