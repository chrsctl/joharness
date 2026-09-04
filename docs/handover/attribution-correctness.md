---
workstream: attribution-correctness
status: in-progress
branch: claude/licensing-matches-verify-qtamqe
pr: none
plan: attribution-correctness
issue: none
session: https://claude.ai/code/session_01BgxrYUJru5VR12hRuPxkdV
agent: sonnet
updated: 2026-09-04
next: Review at sonnet depth, record findings, then retire and open the pull request
---

## Goal

Human asked two things after #206. "Can we Attribute correctly" — make the
distilled style guide carry the whole MIT notice, not half of it. "Okay
remove mention and just integrate The ideas" — take the named third-party
design record out of the tree and keep the reasoning where it is used.

## Decisions

- Full upstream notice inside `caveman.md`, at the end. MIT names both the
  copyright notice and the permission notice; a pointer to `.agents/LICENSE`
  does not survive copying the file alone, which is the exact case #206's
  review raised.
- `prior-art.md` deleted rather than paraphrased. Its stated purpose was to
  stop a session re-litigating settled rejections, and that purpose is
  served better by the argument sitting in the document that owns the
  decision than by a file a session has to know to open.
- Borrowed EVIDENCE dropped, not laundered. The file carried another
  project's measured operational failures as support for rules here. Those
  claims hold only because someone else counted them, so restating them
  without the source would make this repo assert numbers it never
  measured — against its own rule that a measured number carries what
  produced it. The rules they supported are already stated on their own
  grounds elsewhere, so nothing load-bearing is lost.
- Each argument went to the document that owns the decision: branch shape to
  `product/README.md`, no-datastore and the in-repo trade to `graph.md`,
  session interrogation to the handover alternatives table, liveness to
  `unsupervised.md`.
- `graph.md`'s one-line credit for the task-graph model kept. It is
  provenance for the document's framing, not a quotation, and the file is
  more honest with it than without.
- Migration note added for existing consumers. Removals do not travel
  (sync engine header), so a consumer synced before today keeps the deleted
  file and receives a NOTICE that no longer covers the quotations in it —
  the regression is in the consumer, not here, and only a doc line reaches
  it. Found by asking what the deletion does downstream, not by a gate.

## Rejected

- Paraphrasing the quotations and keeping the file. Offered to the human;
  they chose removal and integration, which also ends the maintenance of a
  second place where branch-flow reasoning lives.
- Keeping the borrowed health vocabulary for a future liveness monitor.
  Taking a taxonomy while removing the source is the one thing this change
  set out not to do.
- HTML comment for the upstream notice in `caveman.md`. A notice that does
  not render is not a notice.

## Review

(pending)

## Blockers

None.

## Where to look

- `.agents/docs/caveman.md` — the closing notice section.
- `.agents/docs/product/README.md` — Branch flow, three integrated bullets.
