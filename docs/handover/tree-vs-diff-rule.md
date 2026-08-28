---
workstream: tree-vs-diff-rule
status: done
branch: claude/base-review-adaptions-yle8r9
pr: none
plan: tree-vs-diff-rule
session: https://claude.ai/code/session_01JWpBo9HoR5Mn1KgqBL6vqt
agent: opus
updated: 2026-08-28
next: Merge. Plan file and this file both retire in this PR
---

## Goal

Plan `docs/plans/tree-vs-diff-rule.md`: one defect class cost four merged
edges and five sessions, each fixing its own caller, none writing the rule
down. Question every one got wrong: does this branch OWN a file, or did it
inherit it from the base branch? Tree presence answers neither. Ownership
is a diff against the merge base. Write the rule where the next author
meets it.

## Decisions

- Claimed in parallel with `process-scorecard`, which
  `claude/backpass-usage-review-sbew6t` holds live. Queue proved this pair
  as wave 1 and the scopes are disjoint: that plan takes `joharness.sh`,
  `.agents/docs/graph.md`, `.agents/harness/selftest.sh`; this one takes
  `.agents/docs/feedback.md`, `.agents/harness/AGENTS.md`. Earlier in this
  session the pair was NOT safe — that branch then carried an unmerged
  16-file glossary pass over `AGENTS.md`. It merged as PR #99, so the
  overlap is gone and the wave is real again.

## Rejected

- Citing only the plan's four edges. See r1.
- Touching `.agents/docs/glossary.md` to make "inherited" vs "owned" a
  canonical term. Out of this plan's scope, and that file is the live
  `process-scorecard` session's neighbourhood — the wave holds only while
  each side stays inside its declared scope.

## Review

Opus adversarial, correctness / reproduce / style as separate passes,
2026-08-28.

- r1: (reproduce) the plan says the class cost FOUR merged edges. Counted
  from `./joharness.sh feedback joharness.sh` and `feedback
  .agents/harness/selftest.sh`: six. PR72 r1 and PR77 r2 are the two the
  plan omits, and they are the strongest evidence in the set — both
  postdate PR54 NAMING the class, so they show the cost being paid again
  after it was already known. The plan's four was a written number in an
  instruction file, which is exactly what its parent doc says not to
  trust. (fixed: table cites six, with the recount command beside it)
- r2: (correctness) the plan's Out of scope defers `graph`'s label to
  `docs/plans/graph-inherited-workstream-label.md`. That file does not
  exist: PR77 r2 shipped the fix, mutation-tested both directions. Left
  the reference alone — the plan file dies in this PR — but the table
  says "fixed at last" rather than repeating a deferral that already
  happened. (fixed)
- r3: (correctness) "diff, not tree" alone is an incomplete rule and
  would have shipped `cleanup`'s bug intact. Ownership is a diff, but
  "owns" is three different questions and the FILTER decides which:
  `cl_inflight` needs `--diff-filter=ACMRT` (plain `--name-only` counted
  deletions, so a branch that ran the finishing ritual read as still
  carrying the file it had just deleted), and the workstream recovery
  command needs `--diff-filter=D`. Both are in the record as bug-then-fix.
  Rule now carries the second half. (fixed)
- r4: (style) "Six merged edges paid for this one" in `AGENTS.md` is a
  written number. Kept: it cites the doc section that holds the recount
  command, which is how the file's other measured claims carry provenance
  ("measured at 23 in one consumer repo"). A bare count with no route to
  recounting it would not have been. (no change needed)

## Blockers

None.

## Where to look

- `joharness.sh:fin_adds_at` — newest instance, carries the reasoning to graduate.
- `joharness.sh:cl_inflight` — same fix in `cleanup`.
