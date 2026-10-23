---
research: defect-second-skips-issue-search
urgency: normal
agent: sonnet
effort: medium
graduates: .agents/docs/manage-reference.md
---

## Question

Does `manage-reference.md` § Defect step 4 ("A second defect in the same
session: pull request body only, one line each") skip step 2's open-issue
search, so a manager cites no existing issue for its second and later
defects?

## Echo

§ Defect is numbered 1–6. Steps 2 and 3 read as the path for a first defect.
Step 4 routes every later defect straight to the PR body. It neither says to
run step 2's search first nor to write `Refs #N` for a match. If a manager
reads it that way, a reproduction it measured on `origin/main` never reaches
the issue that already tracks the failure, and the issue's owner never learns
the defect still reproduces. The answer decides whether step 4 needs a clause
or the six steps need reordering.

## Sweep

`goal-directed`: only what decides whether the wording caused the miss on one
consumer edge, not a survey of every manager run.

## What would settle it

**Yes** if, on one consumer edge, all of the following hold:

- The manager reproduced two or more defects on `origin/main`.
- Each later defect already had an open issue.
- The PR body cites none of those issues.
- The manager followed step 4 as written.

**No** if the manager ran the search and cited the issues, or if the missing
citation came from something other than the step 4 wording.

## Method

From consumer `chrsctl/gx`, PR #825 (`manage/crm-kpi-pipeline-forecast`, head
aa0e60ca4, merged 2026-10-23 07:32 UTC as b089ae8ea):

- `pull_request_read get #825`: body section "Not this branch's, reproduced
  on origin/main bdafb2b10", and its only issue reference.
- `search_issues "storyboard transcripts drifted engagement-record
  storyboard-test fails"` on chrsctl/gx, run 2026-10-23 after the merge.
- The manager session transcript (`list_events`, session
  session_01AxN76yVYRzSuTxkUzbGiJU), read for its defect handling.

## Findings

- **Three defects reproduced on `origin/main`; one issue filed, two in the
  body only.**
  - Gotenberg on `--k8s`: filed as #821 at 05:21 with label `human-review`.
    This is step 3, and correct.
  - `GX_STORYBOARD=check platform/tests/web.py`, 29 drifted transcripts,
    measured on bdafb2b10: in the PR body only.
  - `npm run storyboard-test` failing `engagement-record` at 4 renders,
    390/394 on main: in the PR body only.
  - The body's only issue reference is `Refs #821`.
- **Both body-only defects already had open issues when the PR opened
  (07:31:26).**
  - #811 `defect: npm run storyboard-test red on main: engagement-record and
    chart-segmented expectations` (opened 02:39, before the session started).
  - #823 `defect: GX_STORYBOARD=check platform/tests/web.py: 29 committed
    transcripts no longer match the client's request set` (opened 06:41, by
    another session, 50 min before the PR).
  - Step 2 would have found both and required `Refs #811` and `Refs #823`.
- **The manager followed step 4 literally.** No issue search appears in the
  transcript for the second or third defect. The run's own summary says
  "Problems I found that also fail on unmodified origin/main" and lists them
  as PR-body lines.
- **Cost.**
  - #811 and #823 carry no pointer to a fresh reproduction on bdafb2b10 with
    measured counts.
  - Under `JOHARNESS_CHECKS=local`, `consumer-repos.md` § Local checks already
    says "no role queues its failures". A PR body is read by nobody after
    merge, so the measurement is lost.
  - Nothing else in this edge relays it.

## Consequence for the queue

`.agents/docs/manage-reference.md` § Defect: step 4 should state that step 2
runs for every defect. A match gets `Refs #N` in the PR body. Only an
unmatched second or later defect is limited to a PR-body line. Alternatively,
move the search above the numbered routing so it reads as applying to all.
No plan in canonical changes.

## Verification

Not yet verified by a second context. Every claim above can be re-counted
from the commands in Method against chrsctl/gx.

## Graduates to

`.agents/docs/manage-reference.md` § Defect: the rule lives there, and a
manager reads only that section when its pointer fires (`manage.md`, "A
DEFECT outside your item").
