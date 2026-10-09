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
next: Ask human whether to graduate into caveman.md and open PR
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

## Rejected

- Counting tokens with tiktoken: OpenAI tokenizer, undercounts Claude.
  No Anthropic credentials in container, so repo numbers are bytes/words
  from `./joharness.sh context`, labelled as such.

## Review

- r1: Format table numbers wrong model and values (verifier) (fixed)
- r1: 2.5%/0.4% arithmetic wrong, is 3.8%/0.7% (verifier) (fixed)
- r1: customer_id tokenizer, tiktoken overreach, tool-schema source, Compel single query (verifier) (fixed)
