---
plan: abandoned-reaches-every-reader
urgency: normal
agent: sonnet
effort: high
scope: shared:joharness.sh, .agents/harness/handover-context.sh, .agents/harness/selftest/graph.sh, shared:.agents/harness/selftest/dispatch.sh, .agents/harness/selftest/handover-context-issue-claim.sh
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

`dispatch_curate_branches` is first because its failure is the only one that
blocks rather than misinforms: a release does not free the cycle, and `drain`
renders the released status *inside* the in-flight line —
`curate : IN FLIGHT on <branch> (curate-2026-09-17, abandoned), so not yours`.
The argument is the issue's counterfactual, which needs no number: had the
released session not returned, the cycle was frozen permanently. (An earlier
draft of this plan said "frozen for 18 days". Re-counted: the released status
stood for 28 minutes — `git log --all --follow -- '*curate-2026-09-17.md'`. The
18 days were an ordinary `in-progress` claim, which this defect does not
explain.)

## Scope

- `joharness.sh:dispatch_curate_branches` — skip a claim whose `status` is
  `abandoned`, so a released cycle claim stops holding the cycle. Match
  `cmd_janitor`'s existing test; do not invent a second spelling.
- `joharness.sh:cmd_graph` — do not draw a `claims` edge from a branch whose
  claim reads `abandoned`. Copy `cmd_janitor`'s shape (read the field, test it),
  NOT `queue-context.sh`'s: that one awks over a precomputed TSV and this reads
  per-ref frontmatter, so the idiom does not transfer.
- `.agents/harness/handover-context.sh` — the row label that prints
  `claims issue #N`. Its own `claimed_issues` already excludes `abandoned`; the
  label does not apply the same test, so one row and one summary disagree in the
  same output. Apply the test the summary applies.
- Selftest cases, in the topic that already covers each reader
  (`.agents/harness/selftest/dispatch.sh` for the cycle,
  `graph.sh` for the edge, `handover-context-issue-claim.sh` for the row): one
  per reader, each asserting the released shape AND a control asserting the live
  shape still reads as it did.
  The cycle case belongs in `dispatch.sh`, beside the existing
  `curate ... IN FLIGHT` fixture — its own helper runs `./joharness.sh drain`, so
  the issue's measured evidence is already exercised there. It canNOT go in
  `selftest/drain.sh`: that topic's helper hardcodes `JOHARNESS_CURATE_HOURS=0`,
  the cycle's off switch, which makes the whole curate block unreachable, and the
  topic's own header says so.
  **Declared, not dodged:** `docs/plans/unowned-block-age.md` also touches
  `dispatch.sh`, so this plan marks that path `shared:` — the protocol's word for
  an expected reconcile rather than an exclusive claim. Measured with both plans
  present: `./joharness.sh curate` reads `NOTHING TO CURATE — every declaration
  reads true`, so the one-sided marking is enough for that check. Whichever plan
  lands second extends the existing fixture; that is a cost accepted knowingly,
  not a collision ruled out.
  The row case's control: `handover-context-rank.sh` pins the literal
  "and 4 more, ranked below these" — a seventh fixture branch makes it 5, so
  count that assertion before adding a branch anywhere in the hook's topics.

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
   abandoned claims **that name a plan** — `graph` draws no edge for
   `plan: none`, and two of the eight abandoned claims carry it, so the naive
   count is wrong by two. Count both numbers first, with the commands, and put
   them in the workstream file; then `./joharness.sh graph | grep claims` names
   none of the released branches.
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
7. Consumer-side, because this ships (`ci` prints it under `== ship scope`).
   In a consumer that has synced this change and has one released claim naming a
   plan its base branch carries, these two commands are the check, and both must
   hold THERE, not only here:
   `./joharness.sh drain | grep -c 'curate.*IN FLIGHT'` → 0, and
   `./joharness.sh graph | grep -c '<that branch> -- claims'` → 0.
   Run them in a consumer; if no consumer is reachable, say so and say the bar
   is unmet rather than specified.

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
- There is no single root to fix: the three readers each read frontmatter their
  own way, so three tests is the honest answer. What must be shared is the
  SHAPE — `cmd_janitor`'s read-the-field-and-test — so the next word added to the
  enum has one pattern to follow. The recurrence IS this issue.
- A test written for this must FAIL without the change: revert, run, restore.
- Never report a count without the command that re-counts it.
- `joharness.sh` and `.agents/harness/` are protocol paths — under unattended
  mode this plan is not implementable.
