---
workstream: gastown-review
status: review
branch: claude/gastown-review-owjgzg
pr: none
plan: gastown-ideas
issue: none
session: https://claude.ai/code/session_01JU2E2vNtdyc5di2jrZfBRg
agent: sonnet
updated: 2026-09-01
next: Merge to land the research node; graduating it to .agents/docs/prior-art.md is follow-up queue work
---

## Goal

Human asked: "Review ideas of https://github.com/gastownhall/gastown".
Deliverable is the review itself, filed so it outlives this session:
`docs/research/gastown-ideas.md` — twelve findings, verified from a second
context, all GROUNDED.

## Decisions

- Filed as a research node, not a plan: the review writes no code, and the
  research shape (question, method, findings, verification) is exactly what
  a review is. The node lands answered; its remaining lifecycle is
  graduation.
- No PR opened: human did not ask for one, and merging is their call while
  `ci` is red on `main` (see Blockers).
- The two adopt-candidates (server-side merge-method enforcement; liveness
  cross-check rule for the unsupervised heartbeat) were recorded in the
  node's "Consequence for the queue", NOT filed as plans — adoption is
  product direction, human ratifies.
- Sources pinned to gastown commit `649b832` (2026-07-23); the clone at
  `/home/user/gastownhall/gastown` dies with this container, the commit id
  in the node's Method section is what re-runs it.

## Rejected

- Graduating immediately into `.agents/docs/prior-art.md` in this same
  branch: graduation is the merge that DELETES the node
  (`.agents/docs/research/README.md`), and doing both in one diff means the
  queue never sees the question — the human loses the decision point on the
  adopt-candidates.

## Review

- r1: (verifier) F1 sourced Dolt/daemons to gastown's README prerequisites
  table; they actually come via the install steps and `gt up` (fixed)
- r2: (verifier) F4's watchdog-chain cite belonged to gastown `README.md`,
  not `heartbeats.md` (fixed)
- r3: (verifier) F10's GitHub merge-method claim is external product
  behavior, unverifiable from the read sources — reworded to name the
  actual setting, left flagged in the node's Verification section (fixed)
- r4: (verifier) all twelve findings GROUNDED, none WEAK or UNGROUNDED at
  the finding level; the one declared WEAK item (docs-only sweep, practice
  unverified) stands as written (fixed)

## Blockers

`./joharness.sh ci` is red on the perf budget BEFORE this diff exists:
session-start counts 1145 against budget 700 (graph, queue-context, drain
also over) on a tree 0 ahead of `origin/main` — measured 2026-09-01 by
running `./joharness.sh ci` with the research file moved aside. This
branch's file adds +12 (per-item cost of one more queue node, not a
regression in kind). Unblock: fix the budget breach on `main`, or a human
merges accepting the pre-existing red.

## Where to look

- `docs/research/gastown-ideas.md` — the deliverable; verdict-per-idea
  lives in Findings, actions in "Consequence for the queue".
- `.agents/harness/AGENTS.md:step 7` — the merge-method prose F10 says has
  no gate behind it.
