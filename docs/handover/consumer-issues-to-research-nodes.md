---
workstream: consumer-issues-to-research-nodes
status: in-progress
branch: claude/consumer-issues-to-research-nodes
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_011v7iQ91Wf8TyxVFzQceszb
agent: opus
updated: 2026-10-08
next: Record the verifier's findings in ## Review, retire this file, open the pull request — never merge it
---

## Goal

Direct human ask: convert the open issues filed from a consumer on
2026-10-07/08 into queue items the orchestrated loop can claim. Loop step 2 is
the rule it serves — `./joharness.sh dispatch` reads `docs/plans/` and
`docs/research/` on `main` and never GitHub issues, so an issue is invisible
to the orchestrator that runs here. The conversion IS the work; this branch
writes no harness code and fixes nothing. Precedent: `605557b7` (five issues
to plans and research) and the node `bash-guard-reads-prose-as-a-loop.md`,
which is a consumer report canonical decides on.

Nine issues: #296, #297, #298, #300, #303, #304, #305, #307, #283. The pull
request is for the human to merge, not this session.

## Decisions

- `issue: none` in the frontmatter, deliberately — same reason the precedent
  gave: the field holds one number and this work converts nine, so naming one
  would tell another session the other eight are free. Each node carries its
  own issue number in its text, which is what lets the merge that ANSWERS a
  question close it.
- **Nine nodes, one per issue. None merged.** The closest pair is #283
  (can any signal dispatch reads support a death verdict) and #298 (is there
  any ceiling on an item's time and money). #298 calls itself a companion to
  #283 and its item 3 IS #283's comment — one shared sub-item, the time floor
  under the frozen-cost test. That sub-item lives in the #283 node, because it
  is a liveness threshold; #298's node points at it rather than restating it.
  Two questions, two graduation targets, one cross-reference.
- **Research nodes, not plans, for all nine — and three of them are close
  to buildable.** #296, #303 and #304 each name a fix small enough to carry an
  Acceptance. They are filed as nodes because the ask was a conversion to
  nodes and because each still holds one decision a build would make silently:
  #296 which base ref the count reads and what an unreadable one does (I
  measured the proposed patch failing OPEN); #303 whether the gate is worth a
  selftest line; #304 where the clause goes. Flagged in the pull request body
  so canonical can convert any of them to a plan without re-reading the
  issues.
- **No consumer repository, plan name, item name or pull request number in
  any node** (`.agents/docs/consumer-repos.md`, "Name no consumer"; the
  precedent applied the same rule to `docs/`). Measurements are cited as
  measurements — the counts, the dates, the commands.
  The consumer's pull request numbers are left out even though they are now
  explicitly NOT covered: #273's contradiction was settled on `main` in the
  direction that exempts them (merged mid-branch, and reconciled into this
  branch), and nothing in any node needs one — the issues' measurements are
  anchored by date, time and count. An earlier draft of this bullet gave
  avoiding that contradiction as the reason; the contradiction is gone and the
  choice stands on its own.
- **Every claim read from this repo's source was re-run at `cb0028e`**, not
  copied from the issue. Line numbers in the issues were written against an
  earlier `main`; the ones that moved are given as content, not numbers.
  Measurements taken on a consumer's live fleet are marked
  reported-not-re-measured, as the issues themselves mark them.

## Rejected

- One node merging #283 and #298. They share one sub-item and nothing else:
  #283 is about whether a signal can carry a verdict, #298 about whether a
  spend has a ceiling. A merged node would graduate to two files, and the
  shared time floor would be found by whoever took it rather than by whoever
  needs it.
- Writing #296, #303 and #304 as plans despite the ask. Each would then need
  an Acceptance naming the decision it has not made — which is the shape
  `.agents/docs/research/README.md` exists to catch. Flagged for canonical
  instead.
- Re-measuring the consumer's fleet numbers. Not possible here, and the
  issues say so themselves. Invented numbers would read as a record.

## Review

## Blockers

None.

## Where to look

- `.agents/docs/research/README.md` — the nine sections, routing, and the
  no-date rule in `## Verification`.
- `docs/research/bash-guard-reads-prose-as-a-loop.md` — the consumer-report
  shape this follows, including how it carries measurements it could not take.
- `.agents/docs/consumer-repos.md`, `## Name no consumer` — what a citation
  may carry.
