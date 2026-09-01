---
workstream: gastown-review
status: done
branch: claude/gastown-review-owjgzg
pr: none
plan: gastown-ideas
issue: none
session: https://claude.ai/code/session_01JU2E2vNtdyc5di2jrZfBRg
agent: sonnet
updated: 2026-09-01
next: Retire this file, open the pull request, merge on green; graduating the node to .agents/docs/prior-art.md is follow-up queue work
---

## Goal

Human asked: "Review ideas of https://github.com/gastownhall/gastown",
then "Compare to our ideas, review, and improve. Create pr." Deliverable is
the review itself, filed so it outlives this session:
`docs/research/gastown-ideas.md` — sixteen findings (F1–F12 gastown ideas
graded for joharness, F13–F16 the reverse direction), each verified from a
second context; fifteen GROUNDED, F15 WEAK at check with its citation
fixed in the same commit.

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
- r10: (verifier) round 2's settle criterion in "What would settle it" was
  written with its round, not before the whole file — the section's own
  rule (wontfix: the deviation is stated in the paragraph itself; the
  round was a requester scope extension, and faking a pre-declared
  criterion would comply in form by lying in substance)
- r11: (verifier) F13–F16 verdicts did not use the declared record/keep
  set — true of the intermediate tree it read; recast in 322243b before
  this record (fixed)
- r12: (verifier) F13–F16 carried no GROUNDED/WEAK/UNGROUNDED mark — same
  race; Round 2 verification block landed in 322243b (fixed)
- r13: (verifier) Goal here said "twelve findings ... all GROUNDED" over a
  sixteen-finding file with one WEAK-at-check — count and grades corrected
  (fixed)
- r14: (verifier) Blockers' measured number no longer carried a command
  that reproduces it — the stated re-run now skips perf as docs-only;
  provenance rewritten with the pre-commit condition and the
  JOHARNESS_PERF=always re-run path (fixed)
- r15: (verifier) no PR existed, which step 7 has no carve-out for — PR
  opened and driven this round (fixed)

## Blockers

None. Local perf-budget red is container-local, not a blocker: measured
2026-09-01 in this container by `./joharness.sh ci` run BEFORE this
branch's first commit (HEAD equal to origin/main, the new file untracked
and moved aside) — session-start counted 1145 against budget 700. Once the
branch carries commits the perf section skips as docs-only; re-measuring
here needs `JOHARNESS_PERF=always ./joharness.sh ci` (the verifier's
re-run without it prints the skip, not numbers). GitHub's ci on `main` is
green (run 424, head `d05947d`, conclusion success), and PR #181's merge
message records the same local perf red as container-local. Merge on
GitHub's checks.

## Where to look

- `docs/research/gastown-ideas.md` — the deliverable; verdict-per-idea
  lives in Findings, actions in "Consequence for the queue".
- `.agents/harness/AGENTS.md:step 7` — the merge-method prose F10 says has
  no gate behind it.
