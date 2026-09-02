---
workstream: gate-review-verifier-tag
status: in-progress
branch: claude/gate-review-verifier-tag
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01U5n5yq7MV37GaiAmj6szbx
agent: sonnet
updated: 2026-09-02
next: Retire this file, open the pull request, merge.
---

## Goal

Generate-work edge, `JOHARNESS_MODE=unsupervised`: no GitHub issue, no
unplanned requirement, no free plan (the queue's only plan,
`unsupervised-endurance`, is claimed by `origin/claude/gastown-review-owjgzg`
per the session-start hook). `./joharness.sh sources` reads NOT dry — 4
unmarked findings since the `FB_SINCE` baseline. This build turns one of
those four into a plan, per `.agents/docs/plans/README.md` ("At the edge"):
one finding, one plan, carrying `source:` and `evidence:`.

## Decisions

- **Picked r6 over the other three.** The sweep names four unmarked
  findings since `bcebb325e92f`. Three (`endurance-mode-flip.md` r2,
  `sweep-recursion-guard.md` r2, `plan-provenance.md` r5) are each written
  `(recorded — ...)` — deliberately not a marker per `joharness.sh:fb_marker`'s
  own comment, and each is closed reasoning about a decision already taken
  elsewhere, not an open defect. `unmarked-detector-baseline.md` r6 —
  "verifier round owed and NOT run" — names a live, checkable gap in the
  gate itself, is not `(recorded)`-shaped, and reproduces with a command a
  human can rerun.
- **Generate, don't implement.** Loop step 2: "decompose into plan first,
  decompose = the work." This branch writes and merges the plan; the fix to
  `review_report` is the plan's scope, for whichever session (this one or
  another) takes it next.
- **Immutable history, not a retroactive fix.** r6 sits in a merged,
  deleted workstream file. Nothing this branch does can add a `(verifier)`
  tag to that history — the plan targets the gate so this class of finding
  stops recurring, not r6 itself. (Also recorded in the plan's Out of
  scope.)

## Rejected

- **Folding all four findings into one plan.** The queue rule is explicit:
  one finding, one plan. A combined plan would bury r6's specific,
  actionable gap under three findings that are each just recorded reasoning
  with nothing left to build.
- **Marking r6 `(recorded)` somewhere on `main`.** There is no live file to
  write that into — the workstream file that carried it is gone by design
  (`.agents/docs/handover/README.md`, Graduation). The count only moves by
  advancing `FB_SINCE`, and that is PR 161's mechanism to invoke again
  later, not this branch's to reach for on one finding.

## Review

Round 1, sonnet, self.

- r1: confirmed the four unmarked findings by replaying `fb_workstream` /
  `fb_findings` by hand (`git log --full-history --name-only <base>..<merge>
  -- docs/handover`, then `git show <commit>:<path>` on the last surviving
  version) rather than trusting a paraphrase — the plan's `evidence:` cites
  the exact commit and path so this reproduces. (fixed — evidence line
  carries the reproducing `git show`)
- r2: this workstream itself owes the same verifier round the plan is
  about — noted here so it is not the second one in a row that skips it.
  (open — verifier round pending before this branch reaches the edge)

## Blockers

None.

## Where to look

- `docs/plans/gate-review-verifier-tag.md` — the generated plan.
- `joharness.sh:review_report` (~2914) and `joharness.sh:review_count`
  (~2457) — where the plan's fix lands.
- `git show 3ca42921fbe238f02a53c6935de3a328a570f06b:docs/handover/unmarked-detector-baseline.md`
  — r6, the finding this plan answers.
- `.agents/docs/plans/README.md`, "At the edge" — the generate-work rule
  this build follows.
