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
next: Run ci, retire node and workstream file, open PR, merge
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
- Answer NO: cost median 0.209 (clears 0.46), but on 9 of 9 valid diffs
  sonnet missed a recorded `(fixed)` finding opus found (387 excluded: head
  already held its fixes). Step 3 trial not owed.

## Rejected

- Reviewing the merged head: fixed defects are gone there, so no run at any
  tier could find a `(fixed)` finding; step 2 would always pass.

## Review

- r1: (verifier) PR 387's round-1 head already held c7b98ca, which fixed r1-r9/r11; "10 of 10" is 9 of 9, denominator 74 (fixed — 387 excluded in Method, Findings, graduation)
- r2: (verifier) "confounds only make a run find MORE" false: contention killed ci at both tiers (402 r14), five runs shared scratchpad/ci.out (fixed — confounds rewritten, no ci reading trusted)
- r3: (verifier) GROUNDED marks cited a Verification section that read "None yet" (fixed — Verification written from this pass)
- r4: (verifier) cost reading had no command and its transcripts do not outlive the session (fixed — script in Method, per-run costs named as the record)
- r5: (verifier) 394 opus read before its last paid turn: 1.5181 not 1.4794 (fixed — sum 9.560, ratio 0.173; median unchanged)
- r6: (verifier) "5-27 vs 9-63" mixed two counts (fixed — 7-27, every tool_use block)
- r7: (verifier) table left out 402 r8, 386 r10, 384 r7 (fixed — added; totals restated as a range)
- r8: (verifier) 389 r2 "fixed in part" left out of the count unstated (fixed — table says so)
- r9: (verifier) Findings 3 claimed all parent verifiers ran opus 5; parent shows two sessions (fixed — WEAK, two named)

## Blockers

None.

## Where to look

- `docs/research/sonnet-verifier-on-opus-plans.md` — the item.
