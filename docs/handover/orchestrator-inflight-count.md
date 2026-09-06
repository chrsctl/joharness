---
workstream: orchestrator-inflight-count
status: in-progress
branch: claude/drain-7uzyzi
pr: none
plan: orchestrator-inflight-count
issue: none
session: https://claude.ai/code/session_01V7Y1v6ee4aFAmDrY7W8SZZ
agent: opus
updated: 2026-09-06
next: Add the no-claim edge row to cmd_dispatch, then its fixture in selftest/dispatch.sh
---

## Goal

`dispatch` reports a live manager's slot as free for the whole window between
its pull request opening and its merge — step 7 retires the workstream file
as the last commit before the pull request, so the claim disappears while the
branch, the pull request, the CI and the container are all still running. An
orchestrator acting on that verdict spawns a duplicate per item and exceeds
`JOHARNESS_MAX_MANAGERS`, which is the human's money. Measured on consumer
`chrsctl/gx`, 11 consecutive health passes, 2026-09-06.

## Decisions

- Fix on the CAPACITY side, never the claim side. The claims view is right —
  a retired file is genuinely not a claim, pinned with reasoning in
  `.agents/harness/selftest/handover-context-owns.sh:85`. `slots` is what
  answers the wrong question with the claims view's value.
- The row's trigger is the RETIRE RITUAL'S FINGERPRINT, not "no workstream
  file". A bare "unmerged branch carrying no workstream file" catches every
  abandoned branch this repo has ever pushed — 40+ of them here — and slots
  would read 0 of 4 forever. The fingerprint is diff-derived: the branch
  DELETED a workstream file (`--diff-filter=D -- docs/handover`) and owns
  none (`--diff-filter=ACMRT`). That is exactly what step 7 does and nothing
  else does.
- The item it holds comes from the same diff: the plan or research file the
  branch deleted (step 7 / plans README, "Done = implementing PR deletes plan
  file"). No deleted plan file = the row still holds the slot, with the item
  named `?` — a slot with an unknown item is still money committed.
- Item suppressed from the free list the same way a claimed one is (skipped,
  not annotated): the in-flight block already names the path and the branch,
  and a second rendering of one fact is how two readers start disagreeing.
- Counted separately from claimed managers (`n_edge`), with its own verdict
  line, because the ACTION differs: a claimed stall has a `session:` URL to
  `get_session`; this row has none, so the orchestrator finds it by title or
  reads it as gone.

## Rejected

- **Moving the retire commit after the merge** — the obvious repair, and the
  plan's own Out of scope: three pull requests that deferred the deletion each
  turned the base branch red within seconds.
- **Making a retired file count as a claim again** — would red
  `handover-context-owns.sh:85`, a pin whose comments record an earlier wider
  refute failing for a good reason. Never relax a guard to make room for a fix
  one layer above it.
- **Trigger = "unmerged + ahead + no owned workstream file"**, the plan's
  literal Scope wording. Tried against this repo's real remote: 40+ branches
  qualify, most of them months dead, and the count never frees. The plan's own
  second bullet — "must still be distinguishable from a genuinely abandoned
  branch" — is what rules it out.

## Review

Pending — edge review at step 5 (opus: adversarial, separate lenses, plus
`verifier`).

## Blockers

None here. Consumer-side acceptance (this plan SHIPS) cannot be met from this
session: GitHub scope is `chrsctl/joharness` only, and the reproduction repo
is `chrsctl/gx`. Recorded in the pull request body as the outstanding bar.

## Where to look

- `joharness.sh:cmd_dispatch` — the `--- managers in flight` loop and `n_slots`.
- `joharness.sh:dispatch_retired_edges` — the new scan.
- `.agents/harness/selftest/dispatch.sh` — the fixture, both directions.
