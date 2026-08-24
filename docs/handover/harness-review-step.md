---
workstream: harness-review-step
status: review
branch: claude/harness-review-step-xrnmu7
pr: none
plan: none
session: https://claude.ai/code/session_01B5Pq9Ps7b9PSzJ3Hf9MjT7
agent: opus
updated: 2026-08-24
next: Human decides whether to open the PR (outer harness forbids opening one unasked); then merge per Loop step 7. Re-run `./joharness.sh feedback` at ~30 reviewed edges to see whether recurrence is falling
---

## Goal

Two asks, one workstream. First: research, then add a review step to the
harness, off by default, enabled by config. Then: a feedback loop — human's
constraint, "research what's best; we need to quantify how good a loop is",
so the loop had to be picked from measurement, not taste. Harness already ORDERS review (Loop step 5, review depth
by tier) but nothing checks it happened — instruction only. Gap: the record
lives in the workstream file's `## Review`, and only a human reading the
hook output ever notices it is empty. Opt-in gate closes it.

## Decisions

- Knob `JOHARNESS_REVIEW` in `joharness.conf`, values `off` (default) /
  `on`. Off = zero cost, zero output, `ci` byte-identical to today. Same
  doctrine as `JOHARNESS_ENV_SETUP=lazy`.
- Gate lives in `ci`, not in a Stop hook. Stop-hook enforcement of protocol
  discipline was weighed and rejected once already (harness-review
  workstream, PR #6): blocking Stop hooks need loop guards and JSON. `ci` is
  the gate a session cannot skip — same argument the churn ceiling and graph
  lint already rest on.
- Gate checks the RECORD, not the finding count. Findings-per-round is no
  signal (agent-selection.md, review churn: "false both ways"). A clean pass
  records one line saying so. Enforcing recording is honest; enforcing
  findings would teach sessions to invent them.
- `./joharness.sh review` runs with the knob off too — recipe on demand
  costs nothing and a session may want it. Knob decides only whether `ci`
  gates.
- Depth recipe read from the workstream `agent:` tier, falling back to the
  claimed plan's tier, then sonnet. Same tier the review-depth rule already
  keys on; no second vocabulary.
- Two tiers, like churn's warn/ceiling, decided during r1 below: armed, the
  gate only warns until the workstream reaches the edge (`pr:` set, or
  `status:` review/done), and reds there. `ci` runs all through a build, so a
  one-tier gate would red every push from the claim commit on — red as a
  branch's normal state is how a gate stops being read. Edge is where the
  Loop already puts the review (step 5), so the gate fires when the rule
  comes due, not before.
- Feedback loop picked by counting this repo's own history, not by argument
  (numbers and method: `.agents/docs/feedback.md`). Coverage is already 8/8
  since the review ledger landed and 0/19 before it, so "run the review for
  them" buys nothing. Retention is zero — the finish ritual deletes the
  workstream file by design, so all 41 recorded findings sit in merge history
  where nothing reads them — and 36% of file-level fixes land where an earlier
  edge already fixed one. Both point at the same intervention: read findings
  back out of merged history and put them in front of the session about to
  touch the same file.
- Recurrence is the score, volume is not. The review-churn rule already
  measured that finding counts are false in both directions; a loop scored on
  volume gets volume, especially from a literal reader. Recurrence cannot be
  gamed by producing more output.
- `feedback` walks history on demand and stores nothing, like `churn` and the
  graph lint. `review` (standalone only, never the `ci` gate) names the hot
  files in the branch's own diff — the moment the loop pays is when the
  reviewer is already looking at them.
- Dodge accepted, on the record: a session that never sets `pr:` and leaves
  `status: review` never trips the gate. Every alternative that closes
  it (fire on any commit) costs the tier above. Lying in the workstream file
  is visible in the diff and to the human, the same bargain
  `JOHARNESS_CHURN_LIMIT=0` already makes.

## Rejected

- Stop-hook enforcement — see Decisions; rejected before, nothing new
  changes it.
- Counting findings, or requiring N>0 real findings. Review churn rule says
  finding counts carry no signal. Gate would reward theatre.
- Gating on the diff alone (no workstream file needed). Copy/sync tasks and
  plan-queue PRs carry NO workstream file by protocol ("When NOT to write
  one"), so a diff-only gate reds exactly the branches the protocol tells to
  have no record. Gate prints the hole instead of faking coverage.

## Review

Edge review at opus depth (this workstream's tier): correctness, security,
does-it-reproduce as separate passes over the full diff.

- r1: correctness — one-tier gate reds `ci` from the claim commit onward,
  and `ci` runs all through the build, so red becomes a working branch's
  normal state and stops carrying information. (fixed: warn below the edge,
  red at it — `review_at_edge`)
- r2: correctness — only the first workstream file was checked (`head -1`),
  so a branch carrying two records passed on one review that never covered
  the other half of its diff. (fixed: loops every file `lint_nodes` returns)
- r3: security — the workstream's `plan:` value reaches a filesystem path in
  `review_tier`. `lint_stem` takes the basename, so `../../etc/passwd` reads
  `docs/plans/passwd.md`; no traversal. (no change needed)
- r4: does-it-reproduce — a knob value that is neither `on` nor `off` (`true`,
  `yes`) read as off in silence, so a repo that believed it had opted in got
  no gate and no signal. (fixed: `review_on` warns, naming the value)
- r5: does-it-reproduce — the gate's own selftest fixture proved on/off but
  not the edge tiers or a second workstream file. (fixed: 27 cases, both
  edge signals, two-workstream branch, conf path, tier fallbacks)
Second round, over the feedback measure, same three lenses.

- r7: security/correctness — `fb_current_path` matched the recorded path as
  a REGEX against `git ls-files`, so a path carrying `+`, `(` or `{` would
  resolve to a sibling. Same class as the literal-pathspec lesson the sync
  engine already carries. (fixed: string suffix on a path boundary, awk, no
  regex)
- r8: correctness — the walk read every edge ever merged, one `git show` per
  commit. Fine at 37 edges, unusable at 3000, and a measure nobody runs twice
  measures nothing. (fixed: newest 50 by default, `JOHARNESS_FEEDBACK_EDGES`,
  and the window is PRINTED when it bites — an unannounced window is how a
  measure starts lying)
- r9: correctness — first-parent walk. Without it the walk descends into the
  branches and a branch that merged main mid-flight (the protocol tells long
  ones to) contributes a second edge carrying the same workstream file.
  Measured wrong before the fix: 51 edges and 42 findings against a true 37
  and 41. (fixed, with the regression case in selftest)
- r10: portability — recurrence ordering used `tac`, which is GNU-only and
  absent on the macOS machines this harness also runs on. (fixed: awk
  reverses)
- r11: does-it-reproduce — `fb_marker` reads disposition from prose, so a
  finding whose text says "fixed; no change to the docs" classifies as
  no-change. (wontfix — the alternative is a structured field per finding,
  and a field a hurried session fills in wrong is the failure mode the
  delete-on-merge design exists to avoid. Named in the doc's blind spots)
- r12: correctness — found by re-running the measure after merging main:
  the meter held two definitions of a finding. Volume counted any `- ` bullet
  under `## Review` (matching the handover hook), attribution required the
  TEMPLATE's `r1:` id, and one merged edge had written all five of its
  findings without one — counted as volume, invisible to attribution, and
  the scorecard read that edge as contributing nothing. (fixed: the count of
  unlinkable findings is printed, and named in the doc's blind spots.
  Relaxing attribution to any added bullet was rejected — a diff hunk does
  not say which section the line landed in, so a `## Decisions` bullet would
  read as a finding)
- r6: does-it-reproduce — found by running `JOHARNESS_REVIEW=on
  ./joharness.sh ci` on this branch: 3 of the new selftest cases failed,
  because the suite's "knobs exported in the invoking shell must not steer
  the fixtures" unset list never learned the new name. Same hole already
  stood open for `JOHARNESS_CHURN_THRESHOLD` and `JOHARNESS_CHURN_LIMIT`.
  (fixed: all three added to the list)

## Blockers

None for this branch. Found, not this branch's: `./joharness.sh verify` fails
on an immediate re-run — `devenv-smoke` namespace still Terminating, exactly
the queued `smoke-rerun-safety` plan. First run also failed once on a cold
`docker pull alpine:3` that succeeded on retry. Clean run: 7 passed, 0
failed.

## Where to look

- `.agents/docs/feedback.md` — how a loop gets scored, the counted numbers
  behind the choice, and what the measure cannot see.
- `joharness.sh:fb_fix_map` — the whole attribution trick: the protocol
  commits a finding WITH its fix, so that commit's non-protocol paths are
  where the finding landed. No new field for a session to fill in wrong.
- `joharness.sh:cmd_review` — the step. Reads the working tree, not a ref:
  `ci` judges what this branch is about to push.
- `joharness.sh:cmd_ci` — gate wired after churn, only when enabled.
