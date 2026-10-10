---
workstream: plan-identity-is-its-filename
status: in-progress
branch: claude/plan-identity-is-its-filename
pr: none
plan: plan-identity-is-its-filename
issue: none
session: https://claude.ai/code/session_012bxo4eAEpDFu4EzUFuRBCj
agent: opus
updated: 2026-10-10
next: Verifier at opus running on the graduation; record findings in ## Review, fix, retire, PR
---

## Goal

Settle `docs/research/plan-identity-is-its-filename.md` (a consumer report
from `chrsctl/gx`: two plan files for one defect), graduate the answer into
`.agents/docs/plans/README.md`, delete the node.

## Decisions

- Graduate as a section in plans/README.md, not a new key or dispatch dedupe: the node itself says a key is unproven (would two sessions write one value?) and dispatch reconciles too late.
- Re-checked on this head: TEMPLATE grew `issue:` since the node's 832f5fdd; clerk skips a PLANNED issue, so that is a planning-time dedupe for issue-born plans only. Recorded in the section.

## Rejected

- Keeping the node's grep `cascade` over `.agents/docs/`: the graduated text itself would contain the word and falsify its own claim; narrowed to `.claude/commands/`.

## Review

## Blockers

None.

## Where to look

- `docs/research/plan-identity-is-its-filename.md` — the node, findings already written.
- `.agents/harness/queue-context.sh:stem`, `wave_split_hit` — identity and the one reconciler.
