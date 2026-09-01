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
- r5: (code-review) F15 cited escalation beads to gastown `AGENTS.md`,
  which contains no escalation content; real source is gastown `README.md`
  Escalation (fixed)
- r6: (code-review) reverse findings F13–F16 used verdict labels outside
  the file's declared set and had no settle criterion; round-2 paragraph
  added to "What would settle it", verdicts recast to record/keep (fixed)
- r7: (code-review) Verification section's "checked by a spawned subagent"
  silently extended over F13–F16, which that subagent never saw; a second
  grounding pass was run and recorded as Round 2 (fixed)
- r8: (code-review) two citation code spans split across line wraps broke
  grep-ability of the cited paths (fixed)
- r9: (session) the original Blockers claim here — ci red pre-existing on
  `main` — was scope-wrong: GitHub's ci on `main` is green (run 424,
  conclusion success), and PR #181's commit message records this exact
  perf red as container-local; Blockers rewritten (fixed)

## Blockers

None. Local `./joharness.sh ci` is red on the perf budget in THIS container
(session-start counted 1145 against budget 700 with this branch's files
moved aside, so pre-existing here, +12 from this branch's node — per-item
cost, not a regression in kind). GitHub's ci on `main` is green (run 424,
head `d05947d`, conclusion success), and PR #181's merge message records
the same local perf red as container-local. Merge on GitHub's checks.

## Where to look

- `docs/research/gastown-ideas.md` — the deliverable; verdict-per-idea
  lives in Findings, actions in "Consequence for the queue".
- `.agents/harness/AGENTS.md:step 7` — the merge-method prose F10 says has
  no gate behind it.
