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
  branch that never claimed anything. Counted on this repo 2026-09-06 with
  the loop in the comment above `dispatch_retired_edges`: 4 unmerged branches
  own no workstream file, 1 of them carries the fingerprint — so at the
  default cap of 4 the wider test reports 0 of 4 free with nothing whatsoever
  in flight.
- The fingerprint is the DELETED PLAN FILE, with the deleted workstream file
  as the second half of a union — not the other way round, which is what this
  was written as first (see Review r1). The plan file lives on `main` because
  it IS the queue item, so step 7 deleting it is a real `D` in the net diff;
  the workstream file is usually born and retired on the same branch, which
  nets to absent from every filter. A workstream deletion still counts where
  it is visible: one the branch INHERITED and swept.
- The item it holds is that same deleted plan or research file. A branch that
  swept a workstream file and finished no queue item names none and still
  holds the slot, with the item printed `?` — a slot with an unknown item is
  still money committed.
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
  literal Scope wording. Measured against this repo's real remote before
  writing it: 4 branches qualify, 3 of which never wrote a workstream file at
  all, and at the default cap of 4 the report reads 0 of 4 free with nothing
  in flight. The plan's own second Scope bullet — "must still be
  distinguishable from a genuinely abandoned branch, or this trades a
  duplicate-spawn defect for a slot that never frees" — is what rules it out.

## Review

- r1: (session, does-it-reproduce) the trigger was written as "deleted a
  workstream file", and it cannot see the ordinary case. `git diff base..tip`
  compares two STATES: a workstream file born on the branch and retired on it
  is added-then-deleted, which nets to absent from `--diff-filter=D` and from
  `ACMRT` alike. Every one of the nine new fixture cases went red on the first
  `ci`, and the one real branch it did match on this repo matched for the
  other reason — it had INHERITED its file. (fixed: the deleted plan or
  research file is the trigger, since the plan file lives on `main` and its
  deletion survives the net diff; the workstream deletion stays as the second
  half of a union, and `mgr-sweep` pins that half. Recorded rather than
  quietly repaired: reading a net diff as a history walk is the same class as
  `.agents/docs/feedback.md`'s tree-or-diff trap, one level in.)
- r2: (session, correctness) a ref with no merge base was skipped in silence,
  so on a SHALLOW clone — grafted history, most refs unreachable from the base
  — a retired edge among them is not counted and its slot reads free. That is
  the defect this function exists to fix, reproduced one clone deep, and the
  sibling reader had already paid for it: `owned_at` over-reports in exactly
  this case because a missing claim costs two sessions on one branch.
  Measured on this checkout, full clone: 0 of 124 refs (`git merge-base "$r"
  origin/main` per ref, 2026-09-06) — so nothing here would have shown it.
  (fixed: unreadable refs are counted and the listing says it is a floor and
  which number to distrust; no row is invented for a ref with no evidence,
  since that would hold a slot the fleet may need. A `--depth 1
  --no-single-branch` clone of the fixture origin pins it.)

## Blockers

None here. Consumer-side acceptance (this plan SHIPS) cannot be met from this
session: GitHub scope is `chrsctl/joharness` only, and the reproduction repo
is `chrsctl/gx`. Recorded in the pull request body as the outstanding bar.

## Where to look

- `joharness.sh:cmd_dispatch` — the `--- managers in flight` loop and `n_slots`.
- `joharness.sh:dispatch_retired_edges` — the new scan.
- `.agents/harness/selftest/dispatch.sh` — the fixture, both directions.
