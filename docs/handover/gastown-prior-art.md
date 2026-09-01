---
workstream: gastown-prior-art
status: in-progress
branch: claude/gastown-review-owjgzg
pr: none
plan: gastown-ideas
issue: none
session: https://claude.ai/code/session_01JU2E2vNtdyc5di2jrZfBRg
agent: sonnet
updated: 2026-09-01
next: Write .agents/docs/prior-art.md, delete the research node, ci, review, merge
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

## Blockers

None.

## Where to look

- `.agents/docs/prior-art.md` — the file this branch creates.
- `docs/research/gastown-ideas.md` — deleted here; full sixteen findings
  stay in history via the retire commit.
