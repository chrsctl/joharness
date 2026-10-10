---
workstream: sonnet-verifier-on-opus-plans
status: in-progress
branch: manage/sonnet-verifier-on-opus-plans
pr: none
plan: sonnet-verifier-on-opus-plans
issue: none
session: https://claude.ai/code/session_01JHoYs9T8QCVotn1UTAeo6B
agent: opus
updated: 2026-10-10
next: Run settle step 1 - paired sonnet/opus verifier runs on merged opus-tier diffs
---

## Goal

Settle `docs/research/sonnet-verifier-on-opus-plans.md`: does a sonnet
verifier on opus-tier plans cut cost per merged edge by >= 20% without more
defects reaching `main`? Graduate to `.agents/docs/agent-selection.md`.

## Decisions

- Sample: the 10 newest opus-tier merged edges with a verifier record:
  PRs 402 400 399 395 394 393 389 387 386 384.
- Head reviewed = parent of the first commit adding a `- rN: (verifier`
  line to the edge's workstream file (findings commit with their fix, so
  the parent is what round 1 saw). Round-1 record = rN lines that commit
  adds. Later rounds saw later heads: out of the comparison.
- Both tiers get the identical prompt, one worktree each at that head
  (scratchpad/wt/<pr>{s,o}); cost read from the subagent transcript jsonl
  per-message usage, priced at the parent's rates.

## Rejected

None yet.

## Review

## Blockers

None.

## Where to look

- `docs/research/sonnet-verifier-on-opus-plans.md` — the item.
