---
workstream: finding-id-lint
status: review
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: finding-id-lint
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Spawn the verifier, fold the round into ## Review, then retire and open the PR.
---

## Goal

A third of recorded findings reach nothing: the fix map keys on
`^\+- r[0-9]+:`, so a bullet without an id-then-colon is invisible to the
loop that serves findings back. A `ci` stage names the malformed bullets on
this branch's diff. WARN, never red.

## Decisions

- Reading every anchor the plan names, in full, before writing a line. Last
  plan the anchor was read for the section I wanted and not the eleven lines
  that mattered, and the fix reinstated a rule this repo had rejected three
  times. That cost a verifier round and a full revert.
- **The two anchors disagreed, and reading both is what found it.**
  `fb_fix_map` attributes on `r[0-9]+:` — any number of digits. `fb_collect`'s
  NOID classifier matched `r[0-9] | r[0-9][0-9]` — one or two. Counted
  2026-08-29 across every merged workstream file in this repo's history: **23**
  findings carry a three-digit id, all of them attributed correctly by the map
  and reported as unattributable by the counter that exists to measure exactly
  that. `feedback`'s volume line read `223 carry no r1: id` before and **200**
  after, which is the 23 exactly.
  In scope because the plan's own Goal quotes that counter, and because the
  fix is not "teach the map new prefixes" (its Out of scope) but the reverse —
  removing a disagreement. `fb_keyable()` is now the single spelling both
  readers call, and `lint_finding_ids` calls it too: the defect this plan
  exists to name was itself caused by that rule living in two places.
- **The stage reads the DIFF, never the tree**, which is the plan's second
  Trap. A branch inherits every workstream file its base carries, so a
  tree-walking version names somebody else's findings on every `ci` run of
  every branch. Pinned by two cases and refuted by swapping the `git diff` for
  a `find`, which turns both red.
- **Warn, never red**, and asserted as such: `ci` exits 0 on a fixture branch
  whose `## Review` is full of malformed bullets. `churn` and `review` each
  earned their gate on a backtest and this has none.

## Rejected

- **Tightening `review_count` to the same rule.** The plan's first Trap: two
  counters, two questions. `review_count` asks whether a review happened and
  matches a looser `^- ` deliberately, sharing its awk with the handover hook
  so gate and hook can never disagree. Tightening it would turn a formatting
  slip into "no review recorded" and red a compliant branch.
- **Rewriting the 122 unkeyable findings already in history.** Out of scope by
  the plan and right: a record edited to satisfy a later rule stops being a
  record.
- **Changing `review_report`'s tree walk** to match this stage's diff walk.
  It is the pattern the Trap forbids and the plan says explicitly it is not
  this plan's to change. Left alone; the comment beside the new code says why
  it must not be copied.

## Review

(no round yet)

## Blockers

None.

## Where to look

- `joharness.sh:fb_fix_map` — the `^\+- r[0-9]+:` match that decides
  attribution. This is the form the stage must check against.
- `joharness.sh:fb_collect` — the inline `${line%%:*}` id classifier.
- `joharness.sh:review_count` — a LOOSER rule (`^- `) on purpose. Two
  counters, two questions; the plan's first Trap is not to conflate them.
- `.agents/docs/feedback.md`, "What this cannot see" — the blind spot.
