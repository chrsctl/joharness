---
plan: finding-routes-defect-grammar
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: joharness.sh, .agents/harness/selftest/review.sh, .agents/docs/manager-reference.md
---

## Goal

`ci` stage `finding routes` passes a FIRST out-of-item defect that
reproduces on `origin/main` when its `## Review` verdict cites `PR body`,
though § Defect step 3 says it must become an issue. The clerk plans from
issues only, so such a defect leaves the queue. Make the lint refuse it.

## Scope

- `joharness.sh:fr_routed`, `joharness.sh:lint_finding_routes` — a verdict
  that says the finding reproduces (`reproduces`, `defect`) is routed only by
  `#<n>` / `/issues/<n>`, OR by `PR body` when an EARLIER `wontfix` line in
  the same workstream file's `## Review` cites `#<n>` for a defect (§ Defect
  step 4: only a second or later unmatched defect goes body-only), OR by
  `defect not filed` (§ Defect step 5: `issue_write` failed). A NEGATED
  keyword (`not a defect`, `does not reproduce`, `no … reproduced`) is not
  a defect. Every other out-of-item verdict keeps today's grammar. Failure
  text names the new case.
- `.agents/harness/selftest/review.sh` — fixtures: first defect `PR body` →
  red; defect `#12` then defect `PR body` → green; observation `PR body` →
  green.
- `.agents/docs/manager-reference.md` § Lead — the paragraph "The gate checks
  the citation, not the route" says the lint cannot tell a first defect
  from a second; reword to what the lint now does. Name no plan stem there:
  the file ships to consumers.

## Assumptions

- A1: `fr_routed` reads only the verdict text, and nothing in `finish` counts
  filed issues — evidence: `joharness.sh:fr_routed`;
  `grep -n -i -E 'issue_write|defect: ' joharness.sh` — confidence: high
- A2: `lint_finding_routes` takes its lines from `fb_findings`, `## Review`
  only — evidence: `joharness.sh:fb_findings` — confidence: high

## Out of scope

- Scanning `## Decisions` or the pull request body for defects. Free prose;
  a keyword scan there would red observations. The rule stays a manager duty
  (§ Lead).
- Reading GitHub to confirm `#<n>` exists: harness commands never call the
  GitHub API.

## Acceptance

- `.agents/harness/selftest.sh` — `0 failed`, the five new fixtures among
  the passes; with the `joharness.sh` change reverted, the first-defect
  fixture fails.
- Consumer-side (the plan SHIPS): after sync, a consumer branch whose
  workstream file's `## Review` holds `- r1: x (wontfix: pre-existing,
  reproduces on origin/main, in PR body)` and no `#<n>` makes that
  consumer's `./joharness.sh ci` red at stage `finding routes`.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed.

## Where to look

- `joharness.sh:lint_finding_routes` — the gate; `fr_out_of_item`,
  `fr_routed` beside it.
- `.agents/harness/selftest/review.sh` — existing `finding routes` fixtures.

## Traps

- A verdict citing `PR #12` as evidence is not routed (`fr_routed` strips
  it first); keep that.
- Keyword match catches negations ("not a defect"); handled in Scope, test it.
- NEVER skip, disable or quarantine a test to get green.
