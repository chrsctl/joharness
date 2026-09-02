---
plan: gate-review-verifier-tag
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: joharness.sh, .agents/harness/selftest/review.sh
source: merged review findings never acted on
evidence: JOHARNESS_FEEDBACK_EDGES=0 ./joharness.sh feedback (4 unmarked, counted
  since bcebb325e92f); the finding itself —
  git show 3ca42921fbe238f02a53c6935de3a328a570f06b:docs/handover/unmarked-detector-baseline.md
  — its r6: "verifier round owed and NOT run — standing instruction, nineteenth
  consecutive edge, and the second in a row touching a decision the requester
  delegated to me."
---

## Goal

The review gate checks that a branch recorded SOME findings under `##
Review` at the edge. It never checks that any of them came from the
verifier — the independent reader `.agents/harness/AGENTS.md` step 5 says
every depth spawns, tagged `(verifier)`. So a branch that only self-reviews
passes the gate exactly as if the verifier had run.

That gap is not hypothetical — it is r6's own history. The branch that
built the unmarked-findings baseline (merged as PR 161) recorded five
self-review findings, satisfied `review_report`'s `n>0` check, and never
spawned the verifier — a lapse its own author caught and wrote down as "the
second in a row." Nothing short of a human reading the diff catches the
first one, or the next. Close the gap the finding names: `review_report`
should read the SAME thing it prints instructions about.

## Scope

- `joharness.sh` — `review_report()` (~`joharness.sh:2914`) and
  `review_count()` (~`joharness.sh:2457`, or a sibling function reading the
  same bullets): when a workstream file's `## Review` section has findings
  (`n>0`) but none of them contain the literal tag `(verifier)`, the branch
  has not satisfied the step. At the edge (`review_at_edge` true — `pr` set,
  or `status: review`/`done`) this is a gate failure, same class as zero
  findings: print what is missing (findings are recorded, but none are
  tagged `(verifier)`) and return non-zero. Below the edge, mid-build, stays
  silent exactly as the zero-findings case does today — the gate only bites
  where step 5 already requires the record.
- `.agents/harness/selftest/review.sh` — the existing case "a recorded
  finding satisfies the gate" (`write_ws ws.md review 12 ... "- r1: clean
  pass, adversarial, no findings. (no change needed)"`) currently expects
  that self-review-only finding to keep `ci` green at the edge. Under this
  change it must not — update that case's expectation (or split it into two:
  self-review-only reds at the edge; the same finding with a `(verifier)`
  tag added keeps `ci` green). Add the new case explicitly rather than
  relying on the existing one to cover both shapes.

## Out of scope

- Actually spawning the verifier agent, or anything that observes whether a
  session ran it. The gate can only read what got WRITTEN, same as the
  existing zero-findings check — same limit, not a new one.
- Retroactively marking r6, or any other already-merged finding. History is
  immutable; `FB_SINCE` is the only lever that ever moves the count, and
  moving it is its own decision (`.agents/docs/handover/unmarked-detector-baseline.md`,
  merged as PR 161) — not this plan's to re-open.
- Requiring `(verifier)` on EVERY finding, only that at least one finding in
  the section carries the tag. A branch that records five self-review
  findings and one verifier finding has run the step; it should not have to
  tag every line.
- Changing `review_recipe()`, `review_tier()`, or anything about which depth
  a branch owes — this only checks that the tier's owed step left a mark.

## Acceptance

- `.agents/harness/selftest/review.sh` — updated case plus the new one, both
  green: self-review-only findings red the edge with `JOHARNESS_REVIEW=on`;
  the same section with a `(verifier)`-tagged finding added keeps it green.
- `./joharness.sh ci` — pass, 0 failing, 0 skipped.
- `./joharness.sh verify` — 0 failed.
- Mid-build (below the edge) stays silent under the new check exactly as it
  does today — no case in `review.sh` before the edge may start asserting
  gate output.

## Where to look

- `joharness.sh:review_report` — where `n` (finding count) currently decides
  pass/fail at the edge; the new check reads the same bullets `review_count`
  already isolates.
- `joharness.sh:review_count` — the awk that isolates `## Review` bullets;
  the tag check can reuse this rather than re-parsing.
- `joharness.sh:fb_marker` — a sibling case-statement pattern (matching a
  literal substring in a finding line) already used for `wontfix`/`(fixed`;
  same shape fits `(verifier)`.
- `.agents/harness/selftest/review.sh:~130` — "a recorded finding satisfies
  the gate", the case this plan changes the meaning of.
- `.agents/docs/agent-selection.md` — states the rule this gate is
  enforcing ("spawns `.claude/agents/verifier.md` at its own tier ...
  findings tagged `(verifier)`").

## Traps

- Never mark or retire `docs/handover/unmarked-detector-baseline.md` or any
  other already-merged workstream file — merged history is immutable
  (`.agents/harness/AGENTS.md` Part 2). This plan changes a gate for future
  branches, not the past.
- The gate stays off by default (`JOHARNESS_REVIEW=off` in `joharness.conf`)
  unless a separate decision turns it on; do not flip that knob as part of
  this plan — out of scope, and not this plan's call.
- This branch owes its own verifier round under the same rule it is
  enforcing — do not merge on self-review alone.
