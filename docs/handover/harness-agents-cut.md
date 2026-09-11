---
workstream: harness-agents-cut
status: in-progress
branch: claude/review-optimize-1g74te
pr: none
plan: harness-agents-cut
issue: none
session: https://claude.ai/code/session_01SqqhwxWTrXDj4t8bo2K9cU
agent: opus
updated: 2026-09-11
next: Read the whole file, classify every rule before-first-prompt vs on-demand, then move the on-demand ones to their owning file under .agents/docs/
---

## Goal

`.agents/harness/AGENTS.md` is loaded by every session, in every mode, at
every tier, before its first prompt — and it opens by citing ETH AGENTbench
for "long context file hurt agent, cost more". Cut it back toward the size
its own first line argues for, without losing a rule. Plan:
`docs/plans/harness-agents-cut.md`.

## Baseline, counted at claim time

`./joharness.sh context` on `origin/main` at `d599198`, 2026-09-11:

    CLAUDE.md                    399 bytes     56 words
    AGENTS.md                   2454 bytes    354 words
    .agents/harness/AGENTS.md  15882 bytes   2257 words
    instructions               18735 bytes   2667 words

Recounted the growth series with the command in `.agents/docs/caveman.md`
("What it costs, counted") rather than copying the plan's number, which the
plan asks for because the number moves — and it had: the plan cites 2129 on
2026-09-06, the file is 2257 today across 33 commits. 770 on 2026-08-23, so
2.9x in 19 days, not the 2.8x in 14 the plan was written against.

Acceptance is the `instructions` subtotal below 18735 bytes / 2667 words,
both numbers re-counted after the cut and written beside these.

## Decisions

- Supervised only, and this session qualifies: the file is protocol text
  (`./joharness.sh protocol-paths` lists `.agents/harness`), the mode is
  `supervised`, and the human is present. An unattended session must not
  claim this plan.

## Rejected

(nothing yet)

## Review

(pending — step 5)

## Blockers

None.

## Where to look

- `.agents/harness/AGENTS.md` — the file. Its first line is the argument.
- `.agents/docs/caveman.md`, "Where it applies" and "What it costs,
  counted" — the rule served, and how to recount.
- `joharness.sh:ctx_report` — the instrument. Out of scope to change.
