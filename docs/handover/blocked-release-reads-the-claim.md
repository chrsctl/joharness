---
workstream: blocked-release-reads-the-claim
status: in-progress
branch: claude/drain-7uzyzi
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01V7Y1v6ee4aFAmDrY7W8SZZ
agent: opus
updated: 2026-09-06
next: Retire this file as the last commit before the pull request
---

## Goal

Two defects the review of PR #227 found, both still live on `main` after it
merged, both in the same mechanism: the release of a hold behind a BLOCKED
claim.

1. **Keyed on the BRANCH, not the claim.** One branch can carry two workstream
   files. A blocked claim on one released a hold behind the other — a live,
   in-progress manager — and handed out its exclusive scope. In both readers:
   `claim_blocked_branches` in the hook, `blocked_branches` in `dispatch`.
2. **A TAB forged the release.** `status: blocked<TAB>on the human` split the
   hook's own tab-separated claims record, so its third field read exactly
   `blocked` and any pushed workstream file could free a hold. The comment
   beside it claimed `in-progress  BLOCKED: ...` could not forge the release,
   which was true for the space spelling it named and false for a tab.

Same shape as the finding PR #227 fixed — "read every holder, not the first"
— one field over: one blocked claim must never speak for a claim that is not.

## Decisions

- Both readers fixed, because both derive it. The hook keys
  `<plan stem>@<branch>`; `dispatch` keys the same pair, taking the stem out of
  the hold line it already reads (`<stem> on <path> (claimed on <branch>)`).
- The status is VALIDATED where it is written, not sanitised where it is read.
  `dispatch` already normalises anything outside the graph's vocabulary to
  `unreadable`; the hook was the forgeable half of the same fact, so it now
  applies the same list.
- `fields plan status` in one fork, since both keys come from one document
  already in hand. That was a cost finding from the same review.

## How this branch came about

I took `claude/dispatch-held-plan-blocks-queue` as edge work under `/drain`:
the hook named it, `status: review` with an empty `## Review`, and the control
plane had no session for it by branch or by title. I reconciled it with
`main`, reviewed it (one `verifier` pass, thirteen findings) and fixed what
the review found. Its own session then came back, reviewed it independently —
finding the same root defect, "the release must read every holder, not the
first" — retired it and merged it as PR #227 while I was still verifying.

Nothing was merged twice and no work of theirs was lost: their pull request
landed, mine never opened. What survived is what their fix does not cover, and
it is above. Recorded because `/who` was right when I asked and wrong twenty
minutes later, which is the protocol's own warning about push time and
liveness, from the other side: a session absent from the control plane is not
proof it has ended.

## Rejected

- **Fixing the retired-edge interaction here.** The review found the fixed
  symptom still reachable through `main`'s retired-edge scan: a plan whose
  branch is past its retire commit has no claim, so the hook partitions it
  while `dispatch` withholds it — the peer gets a WAIT for a pass nobody
  sits. It needs one of two readers to learn the other's fact, which is a
  design call, so it is filed as
  `docs/plans/dispatch-retired-edge-blocks-queue.md` with its reproduction
  rather than bundled into a fix for a different defect.

## Review

- r1: (verifier, correctness) the blocked release was keyed on the BRANCH, so
  a blocked claim released a hold behind a live claim on the same branch.
  Reproduced with `mgr-beta` carrying blocked `beta.md` and in-progress
  `iota.md`: `iotapeer` was offered as free with the reconcile named, against
  a manager that had not stopped. (fixed: both readers key the claim;
  `iotapeer` pins it.)
- r2: (verifier, security) a TAB in the status field forged the release
  through the hook's tab-separated record. (fixed: validated against the
  graph's vocabulary at the point it is written; the tab spelling is a
  fixture case.)
- r3: (verifier, cost) two `awk` forks per claiming workstream file where
  `fields` exists to make one — 126 to 128 on the built shape, 243 to 249
  live, against a budget of 141. (fixed: one pass.)
- r4: (session, docs) `(open)` is offered as a verdict by
  `.agents/docs/handover/TEMPLATE.md` and rejected by the gate that reads
  these markers (`joharness.sh:fb_marker`). Mid-build that is right; at a
  retire commit it reds, which it did to me and cost a cycle. (fixed: the
  TEMPLATE says `(open)` is mid-build only and names the gate.)
- r5: (verifier, correctness) the fixed symptom is still reachable through the
  retired-edge scan. (wontfix here — filed as
  `docs/plans/dispatch-retired-edge-blocks-queue.md`, urgent, with the
  reproduction. See Rejected.)

## Blockers

None.

## Where to look

- `.agents/harness/queue-context.sh` — `claim_blocked_pairs` and the hold loop.
- `joharness.sh:cmd_dispatch` — `blocked_claims` and the `hold_live` loop.
