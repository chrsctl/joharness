---
plan: promote-before-retire
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: shared:joharness.sh, shared:.agents/harness/selftest.sh, .agents/harness/selftest/ci-promote.sh
---

## Goal

Issue #258's second option. Loop step 7 deletes the workstream file in the
last commit before the pull request opens, and the same step says "Still-
useful bits go to the right layer's `AGENTS.md` or `docs/` first." Nothing
measures whether anyone does. Measured in a consumer, 2026-09-16: a branch
merged carrying 39 recorded findings, and `git ls-tree --name-only
origin/main docs/handover/` on that repo after the run returned nothing —
the findings were written down properly, per step 5, and then destroyed on
merge with nothing promoted. Most of those 39 were probably routine and
correctly forgotten. What is missing is not a rule; it is that nobody
DECIDES, and the moment the decision would be made is the moment the record
disappears.

## Scope

- `joharness.sh` — a report-only stage in `finish`, beside the checks that
  already fire while the fix is still a commit rather than after the merge.
  For the branch's own workstream file it counts two numbers from git alone:
  findings recorded (the `- r<N>:` bullets, using the parser
  `lint_finding_ids` already has) and whether this branch's diff against the
  merge base touches any file that could carry a promotion — an `AGENTS.md`
  in any layer, or anything under `.agents/docs/`. It prints both and says
  what it does not know.

  The sentence it prints matters more than the numbers. It is not "you
  should have promoted": most findings are branch-local and correctly
  forgotten. It is "N findings are about to stop existing on this branch;
  this diff promotes into M files" — the loss, stated at the one moment it
  is still reversible.

- `.agents/harness/selftest/ci-promote.sh` — the topic file.
- `.agents/harness/selftest.sh` — register it. The registry every topic
  appends to, hence `shared:`.

## Out of scope

- Any red. REPORT-ONLY, and `lint_finding_ids` carries the reasoning in its
  own comment: a gate that fires on an honest branch is one sessions route
  around, and a branch whose findings are all genuinely local is honest. It
  earns a strength later on a backtest, the way `churn` did.
- Judging whether a promotion is GOOD, or matching a promoted line to the
  finding it came from. That is reading content, which is the verifier's
  job and expensive; this reads commit membership and file paths.
- Options 1 and 3 of the issue. Option 1 is `docs/plans/managers-closing-
  report.md`. Option 3 — pointing `upstream` at the consumer — is the
  largest change and turns on where a consumer's own product findings
  should go, which is product direction nobody has decided.
- Changing what step 7 requires, or when the retire commit lands.
- The `## Review` rules themselves — whether a finding was recorded before
  its fix and committed with it. A plan for that was written and then
  withdrawn on its own backtest: the measurement is in
  `.agents/docs/handover/README.md`, Reviewing, and the short version is
  that the only visible half fires on branches obeying other rules. This
  stage counts findings and asks a different question — what the retire
  commit is about to destroy — which nothing in that measurement touches.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- A fixture branch with findings recorded and a diff touching no
  `AGENTS.md` and nothing under `.agents/docs/` prints the loss line with
  the right count. A fixture that promotes into one of them prints the same
  line with a non-zero second number. BOTH asserted: a line asserted in one
  state passes when the stage is deleted.
- Zero findings prints nothing. A stage that speaks on every branch is one
  readers stop reading.
- A workstream file this branch only INHERITED is not counted. The
  precedent is `ci`'s existing carve-out, for the same reason: a gate that
  reports somebody else's omission is one sessions route around.
- Report-only, asserted: `finish` stays green with the line printed, and its
  exit status is asserted, not just its text.
- Proved by reverting, per Loop step 5: removing the stage reds a positive
  assertion.
- Backtested before it is trusted, over the window `feedback` walks —
  `JOHARNESS_FEEDBACK_EDGES`, whose default the code carries, so the window
  is read rather than guessed here. Report with the command and the date:
  edges examined, findings recorded across them, and how many of those edges
  promoted anything. No threshold is set from it; the number's job is to say
  whether this repo has a habit worth a gate later.
- SHIPS: `joharness.sh` reaches every consumer. In a consumer, `./joharness.sh
  finish` on a branch with findings and no promotion prints the line.

## Where to look

- `joharness.sh:lint_finding_ids` — the `- r<N>:` bullet parser to reuse,
  and the report-only doctrine with its reasoning.
- `joharness.sh:fin_strength` — why `finish` and `ci` carry two strengths
  over the same facts, which is the precedent for adding a soft one here.
- `joharness.sh:cmd_finish` — where a stage that fires before the merge
  goes, and what it already says about what it cannot cover.
- `.agents/docs/handover/README.md` — the retire rule and the count of what
  skipping it costs.

## Traps

- Report-only means green. A stage that reds here fires on branches doing
  nothing wrong, and the first session to hit that learns to skip `finish`.
- Never read the diff's content. Paths and commit membership only; the
  moment this opens a file to judge a promotion it is a second verifier at a
  verifier's price.
- A measured number carries what produced it in the same sentence — the
  command, and when. The backtest number goes in the pull request body that
  way or it is a written number.
