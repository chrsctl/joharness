---
workstream: no-ceiling-on-one-item
status: in-progress
branch: manage/no-ceiling-on-one-item
pr: none
plan: no-ceiling-on-one-item
issue: 298
session: https://claude.ai/code/session_01VvHXon6n8wmdf5GBNCtBjb
agent: opus
updated: 2026-10-10
next: ci green, retire workstream file, PR, merge
---

## Goal

Research node `docs/research/no-ceiling-on-one-item.md` (issue #298): what
bounds the time and money one item may consume when every health signal
reads a steadily-billing manager as healthy? Settle it, graduate, delete.

## Decisions

- Item 1 (detector) already landed: PR 357, `CEILING?` report row,
  `JOHARNESS_MANAGER_HOURS`. Checked: `git show --stat 5f4e4bd9`.
- Item 2 (refresh rule): NO automatic rule. Cheap refreshes in #298 were
  quiet-at-finish managers = STALL?/IDLE rows already respawn them. A
  pushing manager past the ceiling has no readable between-runs sign;
  archive kills the in-flight run (the issue's own counter-case).
- Item 4: interrupt-then-check already in KILL path; guard cannot compel.
- One conf knob, not per-plan: mark is a report, false positive = one line.
- Item 3 (cost floor) is `frozen-cost-is-not-death-yet`'s, not this node's.

## Rejected

- Refresh on `CEILING?`: mark fires only on in-progress, no `pr:` =
  mid-build, the counter-case. Widening to done/`pr:` set or keying on
  plane `IDLE`: neither says between runs (frozen-cost IDLE with a run going).

## Review

- r1: (verifier) expensive-side bullet named review/retired rows; `CEILING?` fires only on in-progress with no `pr:` (`joharness.sh` cmd_dispatch). (fixed — bullet rewritten on what the mark marks)
- r2: (verifier) `status: done` and `pr:` set are git-readable finish states, omitted. (fixed — named, and why they still are not between-runs)
- r3: (verifier) plane-readable `IDLE` dismissed without argument. (fixed — cites the frozen-cost IDLE manager with a run going)
- r4: (verifier) STALL? path is nudge then KILL then respawn, and a manager answering the nudge is never respawned. (fixed — steps spelled per row, saving qualified as unknowable)
- r5: (verifier) `ledger-fields-with-no-rebuild.md:212` and `a-requirement-no-plan-can-serve.md` mention the deleted stem in prose. (no change — prose in other open nodes, not edges; graph lint clean of them)
- r6: (session) first `./joharness.sh ci` 2026-10-10 FAIL: graph lint DEAD on `issue: "#298"` (quoted). (fixed — `issue: 298`; this is the verifier's unexplained FAIL)

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` — health table, `CEILING?` row.
- `.agents/docs/orchestrated.md` — knob table, `JOHARNESS_MANAGER_HOURS`.
- `joharness.sh:dispatch_claim_age_min` — what the ceiling reads.
