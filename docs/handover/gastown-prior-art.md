---
workstream: gastown-prior-art
status: review
branch: claude/gastown-review-owjgzg
pr: none
plan: gastown-ideas
issue: none
session: https://claude.ai/code/session_01JU2E2vNtdyc5di2jrZfBRg
agent: sonnet
updated: 2026-09-02
next: Retire this file as the last commit before the pull request, then merge on green
---

## Goal

Close the `gastown-ideas` question by graduating it. PR #183 landed the
node answered; the queue offers it because an answered node still holds a
slot until its `graduates:` target exists. This branch writes
`.agents/docs/prior-art.md` and deletes `docs/research/gastown-ideas.md`.

## Decisions

- Graduation carries the REASONING, not a rule line. The harness deletes
  the node instead of keeping a superseded record
  (`.agents/docs/research/README.md`, Graduating), which works only if the
  why survives the delete. A session that later rediscovers gastown must
  find the rejections already argued, or it re-opens them.
- Target is a NEW file rather than rows added to existing docs: the content
  is "what comparable systems chose and why this repo differs", which no
  current file owns.
- Only the `record`-verdict findings graduate as prose (F13, F16, plus the
  three rejections F1/F6/F9). The `keep` findings (F14, F15) describe rules
  this repo already has — restating them in prior-art would be a second
  copy that rots against the first (`.agents/docs/caveman.md`).
- The two adopt-candidates do NOT graduate as plans here. They are product
  direction; the node recorded them for the human and this branch does not
  promote them.
- Same branch name, re-cut from `main`: PR #183 is merged, so the follow-up
  is a fresh change on the same designated name, not a stack on merged
  history.

## Rejected

- Keeping the node "until the adopt-candidates are decided": graduation is
  gated on the QUESTION being answered, not on the human acting. Holding it
  open would park a settled question in the queue where every future
  session re-reads it as work.

## Review

- r1: (code-review) F10's specifics died in the generalization — the node
  held that merge-commit-only is prose with no gate, verified by two greps
  with zero hits, remedy a forge setting. Deleting the node loses it
  (fixed — stated concretely under "Open, not rejected")
- r2: (code-review) the second adopt-candidate (liveness cross-check rule
  plus health taxonomy for a future heartbeat monitor) was dropped
  entirely; prior-art recorded the scars as vindication only, not as
  direction (fixed — its own bullet, pointing at `unsupervised.md`)
- r3: (code-review, verifier) "Reviewed whole at commit 649b832"
  contradicts the node's declared goal-directed sweep, which excluded
  `internal/` and most of its `docs/design/`; the qualifier dies with the
  node, leaving an overstated coverage claim permanent (fixed — scope and
  exclusions stated)
- r4: (code-review) claims the node marked WEAK — that Gas Town's
  mechanisms work in practice — graduated unhedged, including the sentence
  carrying the file's own re-open condition (fixed — both hedged to what
  was actually checked)
- r5: (code-review, verifier) zero inbound links: every sibling under
  `.agents/docs/` is reachable from a caller, this page was reachable only
  by browsing, so the rule it defends does not point at its own reasoning
  (fixed — linked from `product/README.md` Branch flow, the integration
  branch rule)
- r6: (verifier) GUPP quote altered — source reads "If you find something
  on your hook, YOU RUN IT." with capital If and a full stop; caveman
  "Never touch" makes quoted strings byte-exact (fixed)
- r7: (verifier) "Work is data" quote substituted an em dash for the
  source's ASCII hyphen; same rule, and the checker confirmed the source
  uses em dashes elsewhere, so this was not house-style normalization
  (fixed)
- r8: (code-review) `next:` ended at merge with no retire commit, which
  `finish` already reported would land this file on `origin/main` (fixed)
- r9: (code-review) "Where to look" anchored the node this same tree
  deletes; graph lint warned (fixed — anchors the surviving page)
- r10: (session) the perf-budget red recorded on the previous branch as
  container-local was really SHALLOW-CLONE-local: same code, session-start
  counted 1145 before `git fetch --depth=2000` and 618 after, both by
  `./joharness.sh ci` in this container. Corrected here because the earlier
  record now sits in merged history and cannot be edited (no action — the
  claim it corrects merged with PR 183)

## Blockers

None.

## Where to look

- `.agents/docs/prior-art.md` — the page this branch creates; it must stand
  alone, because it syncs to consumers that never had the node.
- `.agents/docs/product/README.md` Branch flow — the one inbound link.
