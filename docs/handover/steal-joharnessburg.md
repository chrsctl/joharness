---
workstream: steal-joharnessburg
status: in-progress
branch: claude/compare-joharnessburg-qdimm7
pr: none
plan: none
session: https://claude.ai/code/session_0126bZYruEVL7vNBLb7RXF4v
agent: opus
updated: 2026-08-24
next: Push, then open PR adding the three plan files to main
---

## Goal

Human compared this harness against `kitchen-engineer42/joharnessburg`
(the John plugin), then said "steal" against the three borrowings the
comparison named: its `PreCompact`/`PostToolUse` hooks, its lessons ledger
plus process scorecard, and its canonical glossary. Queue work, so it
enters as plans, not as an implementation branch.

## Decisions

- Three plan files, one per borrowing: `compact-reorient`,
  `process-scorecard`, `harness-glossary`. Plans, not code: sessions write
  plans and humans write requirements (`.agents/docs/product/README.md`),
  and each borrowing is separately schedulable at a different risk.
- `process-scorecard` takes half of its source. John pairs the scorecard
  with `.john/lessons/`, an append-only store. `.agents/docs/graph.md`
  Rules forbids exactly that ("No stored graph, no auto-extraction",
  "Derived state = second copy, rots") and the graph already carries the
  `graduated` edge with Loop step 7 as its ritual, so the promotion path
  exists and only the counting is missing. Scorecard derives from git at
  read time; the ledger is written into that plan's Out of scope by name so
  the next session does not re-propose it.
- `PostToolUse` trace offload dropped, in `compact-reorient`'s Out of
  scope. John reads corpora, this repo reads shell scripts, and nobody has
  measured context pressure here. This repo's bar is counted numbers.
- `compact-reorient` does not pick its hook event. Whether `SessionStart`
  already fires with `source=compact` is a live-client fact, so the plan
  requires it verified and recorded before either line is written.
- Glossary bans wordings and lints for them, but renames no code. Field
  names, subcommands and paths stay; a field rename breaks every consumer's
  synced harness and every open branch's frontmatter.
- All three touch `.agents/harness/selftest.sh`, two touch `joharness.sh`,
  so none share a wave — with each other, or with queued
  `ci-scope-selftest` and `queue-shared-scope`. Named in each plan's Traps.

## Rejected

- Implementing the three borrowings on this branch. Would have put a
  cross-cutting harness change on a branch cut for a comparison, with no
  plan, no tier assignment and no scope declaration for other sessions to
  see. The queue is how work enters.
- A lessons ledger, in any size. See Decisions; `.agents/docs/graph.md`
  Rules is the prohibition and it is not negotiable by a smaller version.
- Writing a `docs/product/` requirement above the three plans. Requirements
  are the human's to write; sessions decompose them.

## Review

Plans-only diff, no executable code, so the review ran on the two things a
plan can get wrong: anchors that do not resolve, and claims that do not
reproduce.

- r1: `## Where to look` pointed at the source-repo clone by absolute path,
  outside the work tree; graph lint warned. Rephrased so it is not an
  anchor. (fixed)
- r2: all 11 `path:line` anchors across the three plans re-read against the
  files at HEAD — `joharness.sh` 164 / 234 / 308 / 411 / 548 / 720 / 783,
  `handover-context.sh` 16 / 47, `sync-to-consumer.sh` 114,
  `handover/README.md` 86. Every one lands on the named symbol or line.
  (fixed — none were wrong)
- r3: drift counts in `harness-glossary` are case-insensitive greps, and an
  earlier case-sensitive count of the same term gave 91 rather than 107.
  Plan states the exact command it counted with, and Acceptance requires a
  re-count before the numbers ship anywhere. (fixed)

## Blockers

None.

## Where to look

- `docs/plans/compact-reorient.md`, `docs/plans/process-scorecard.md`,
  `docs/plans/harness-glossary.md` — the deliverable.
- `.agents/docs/graph.md` Rules — the paragraph that reshaped
  `process-scorecard`.
- Source repo `kitchen-engineer42/joharnessburg`, cloned read-only into
  this container outside the work tree; re-clone if a later session needs
  it (containers are ephemeral).
