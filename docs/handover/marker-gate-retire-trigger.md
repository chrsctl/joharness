---
workstream: marker-gate-retire-trigger
status: review
branch: claude/marker-gate-retire-trigger
pr: none
plan: marker-gate-needs-no-done
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Open the pull request and merge it
---

## Goal

Apply the handoff `claude/marker-gate-needs-no-done` left. That branch's
session (A2, the endurance retry) designed, implemented, tested and
`code-review --high`'d this fix, then **reverted it** — its whole scope is
protocol text and the session was running unsupervised, which
`docs/product/unsupervised-mode.md` forbids. It marked itself `blocked` and
named the commit holding the patch.

This session is supervised, so this is the supervised half of that handoff.

The defect: `lint_finding_markers` reds only at `status: done`, and nothing
requires a branch to ever say it. PR 172 went `review` straight to its
retire commit and merged an undispositioned `r5`.

## Decisions

- **Applied, not redesigned.** `git checkout a6ef911 -- joharness.sh
  .agents/harness/selftest/review.sh`, exactly as the handoff instructed.
  Redesigning would have discarded a `code-review --high` pass and a
  verifier run for nothing.
- **Verified rather than trusted**, which is the rule that matters when the
  work arrives from another session. Every claim in that workstream file
  was treated as a hypothesis: the counts, the mutation coverage, and the
  one failure it reported.

## Rejected

- **Taking the handoff's "1170 passed, 1 failed" at face value.** It
  reported a perf-budget failure it believed container-local (`graph` 391
  against a 260 budget). Re-run here: **1171 passed, 0 failed**, and
  `ci: pass`. Its diagnosis was right and its number was environmental —
  had I recorded 1/failed as this branch's state, I would have shipped a
  written number that was true on one machine.

## Review

Findings r1–r4 belong to the handoff session and are recorded in full on
`origin/claude/marker-gate-needs-no-done`
(`docs/handover/marker-gate-needs-no-done.md`) — its r1 (folding `retired`
into `fin_strength` broke the `== finish` silence), r2 (`fin_retired_own`
over-reported a re-added file), r3 (`--first-parent` ownership), r4 (its
verifier's form finding). They are not re-listed here; that file is the
record and this branch's `## Review` is for what THIS session found.

- r1: the handoff asserts the fix is pinned. Checked rather than believed
  — `mutate` on the gate line (`joharness.sh:2386` -> `if false`) reds
  **4**, and on r2's tree check (`:4493`) reds **3**, including
  `a re-added file is not a retirement`. Both halves are pinned, the
  second being the one a naive fix would have missed. (fixed — nothing to
  change; the claim held and now has a counted number behind it.)
- r2: the handoff's selftest number did not reproduce (see Rejected).
  Its `1 failed` is absent here and `ci` is green. (fixed — this branch
  records its own count, 1171/0, from its own run.)
- r3: verifier not spawned by THIS session — thirty-first consecutive
  edge, issue #168. Worth noting that the handoff session DID spawn one
  (its r4), which is the first verifier run on this repo in that stretch;
  the instruction that blocks me evidently does not bind a spawned
  session. (wontfix — #168 is the human's to lift, and this is new
  evidence for it.)

## Blockers

None.

## Where to look

- `joharness.sh:fin_retired_own` — log-based, `--first-parent`, tree-checked.
- `joharness.sh:lint_finding_markers` — the second red trigger.
- `joharness.sh:fb_marker` — why `(recorded` stays out of the vocabulary.
