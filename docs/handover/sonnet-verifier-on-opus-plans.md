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
next: Spawn opus verifier: step-5 review plus blind re-take of the findings match from transcripts
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
- Answer NO: cost median 0.209 (clears 0.46), but sonnet missed recorded
  `(fixed)` findings on 10/10 diffs, opus re-found one on 9. Step 3 trial
  not owed.

## Rejected

- Reviewing the merged head: fixed defects are gone there, so no run at any
  tier could find a `(fixed)` finding; step 2 would always pass.

## Review

## Blockers

None.

## Where to look

- `docs/research/sonnet-verifier-on-opus-plans.md` — the item.
