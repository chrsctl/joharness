---
plan: abandoned-reaches-every-reader
urgency: normal
agent: sonnet
effort: high
scope: shared:joharness.sh, .agents/harness/handover-context.sh, .agents/harness/selftest/graph.sh, .agents/harness/selftest/drain.sh, .agents/harness/selftest/handover-context-rank.sh
---

## Goal

#279, defects 2, 3 and 5. `abandoned` was added to `queue-context.sh` and to
`joharness.sh`'s status enum and nothing else was taught it, so three readers
still treat a released claim as live. One of them blocks the thing a release
exists to free.

Counted 2026-10-07 on this checkout:

| reader | command | reads |
| --- | --- | --- |
| `dispatch_curate_branches` | `sed -n '/^dispatch_curate_branches()/,/^}/p' joharness.sh \| grep -c abandoned` | 0 |
| `cmd_graph` | `awk '/^cmd_graph\(\)/,/^}/' joharness.sh \| grep -c abandoned` | 0 |
| `cmd_janitor` — the one that is RIGHT | same shape | non-zero, via `[ "$status" = abandoned ] && continue` |

`dispatch_curate_branches` is first because its cost is the largest measured in
the issue: releasing a curate claim does not free the cycle, and one stayed
frozen for 18 days while `drain` printed the released status *inside* the
in-flight line — `curate : IN FLIGHT on <branch> (curate-2026-09-17,
abandoned), so not yours`.

## Scope

- `joharness.sh:dispatch_curate_branches` — skip a claim whose `status` is
  `abandoned`, so a released cycle claim stops holding the cycle. Match
  `cmd_janitor`'s existing test; do not invent a second spelling.
- `joharness.sh:cmd_graph` — do not draw a `claims` edge from a branch whose
  claim reads `abandoned`. `.agents/harness/queue-context.sh` already does this
  at both of its claim lookups; reuse that idiom.
- `.agents/harness/handover-context.sh` — the row label that prints
  `claims issue #N`. Its own `claimed_issues` already excludes `abandoned`; the
  label does not apply the same test, so one row and one summary disagree in the
  same output. Apply the test the summary applies.
- Selftest cases, in the topics that already cover each reader
  (`.agents/harness/selftest/drain.sh`, `graph.sh`,
  `handover-context-rank.sh`): one per reader, each asserting the released shape
  AND a control asserting the live shape still reads as it did.
  The cycle case goes in `drain.sh`, not `dispatch.sh`, for two reasons: the
  issue's measured evidence is `./joharness.sh drain` printing the frozen line,
  and `dispatch.sh` is claimed exclusively by
  `docs/plans/unowned-block-age.md` — `curate` reports two exclusive claims on
  one path as a proposal for the human, and one plan's `shared:` marking cannot
  void another's exclusive claim. Both commands call the same
  `dispatch_curate_branches`, so proving it through `drain` proves the reader;
  `dispatch.sh`'s existing `curate ... IN FLIGHT` assertion is the control that
  must keep passing, untouched.
- One case for #279's fourth defect, which is not a code change: assert the
  `abandoned` filter excludes a claim whose push age is INSIDE the candidate
  window. Today `./joharness.sh janitor` reads `none — every claim pushed inside
  144h` while eight abandoned branches exist, so age excludes them and masks
  the filter; a regression in the filter would be invisible for six days.

## Out of scope

- **#279's first defect — the red on a branch older than the word.** It is a
  timing problem with a design choice, planned separately in
  `docs/plans/release-reds-the-branch-it-releases.md`. Do not touch any
  `lint_enum` call here.
- **Changing what `abandoned` MEANS, or adding a sixth status.** The word and
  its rank are settled (`handover-context.sh` rank 5).
- **`cmd_janitor`.** It is the model, not a target.
- **Suppressing an abandoned row from the hook entirely.** It sorts last by
  rank and stays visible on purpose; the issue's own text says the bracket is
  what a reader needs.
- **The curate or janitor role docs.** This plan changes readers, not roles.

## Acceptance

All pass or not done. Trust the numbers these print, not any written here.

1. `./joharness.sh ci` → `ci: pass`.
2. `bash .agents/harness/selftest.sh` → `0 failed`, with a higher pass count
   than at the merge base.
3. `./joharness.sh graph | grep -c claims` falls by exactly the number of
   abandoned claims on `origin` at the time it is run, and
   `./joharness.sh graph | grep claims` names none of them. Count the abandoned
   claims first, with the command, and put both numbers in the workstream file.
4. A fixture whose curate claim reads `status: abandoned` makes
   `./joharness.sh drain` print `curate` as DUE or available, never
   `IN FLIGHT`; and the same fixture with `status: in-progress` still prints
   `IN FLIGHT`. Both in one case, or the test passes for the wrong reason.
5. A fixture branch whose claim reads `abandoned` and carries `issue: N`: the
   hook's row does NOT say `claims issue N`, and its summary still says no
   issue is claimed. Assert both; they are the two halves that disagree today.
6. Each new assertion is mutation-tested — `./joharness.sh mutate joharness.sh
   <line> <replacement>` on the clause it pins reds that case and leaves the
   controls green. Baseline green FIRST: a mutation that reds hundreds of cases
   says nothing about one clause.
7. Consumer-side, because this ships: a consumer that syncs this change and
   releases a claim sees the freed cycle and the dropped `claims` edge with no
   further edit. State the command a consumer runs, and that it was not run
   here if it was not.

## Where to look

- `joharness.sh:dispatch_curate_branches` — the cycle holder.
- `joharness.sh:cmd_graph` — the edge drawer.
- `joharness.sh:cmd_janitor` — the correct test, to copy.
- `.agents/harness/queue-context.sh` — the same filter at two claim lookups.
- `.agents/harness/handover-context.sh` — `claimed_issues`, and the row label
  that skips its test.

## Traps

- A finding outside `## Review` does not exist: `fb_findings` stops at the next
  `## ` heading. Measured twice in one day, PR289 and PR294.
- Ownership is a DIFF against the merge base, never a tree read.
- Three readers, one word: fix the root in the shape `cmd_janitor` already
  uses rather than three different tests, or the next word reaches two readers
  again. That recurrence IS this issue.
- A test written for this must FAIL without the change: revert, run, restore.
- Never report a count without the command that re-counts it.
- `joharness.sh` and `.agents/harness/` are protocol paths — under unattended
  mode this plan is not implementable.
