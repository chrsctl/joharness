---
workstream: issues-to-plans
status: in-progress
branch: claude/issues-to-plans
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01FqwfiZLmxGRB8odjp2rW4v
agent: opus
updated: 2026-10-09
next: Write one plan per open issue not yet planned, then ci, verifier, PR
---

## Goal

Requester, 2026-10-09: "Convert issues into plans". 20 open issues; turn
each one whose claims hold against source into plan files under
`docs/plans/`, one plan-only pull request.

## Decisions

- Already planned, skipped: #279 (`abandoned-reaches-every-reader`,
  `release-reds-the-branch-it-releases`), #311 (`issue-triager-role`),
  #304's AGENTS.md half (`orchestrated-only-docs`).
- Issue → plan: #291 #293 #284 `janitor-rules-agree`; #308
  `janitor-zero-candidate-says-why`; #292 `janitor-sees-retired-sweep`; #296
  `guard-quiet-on-empty-branch`; #303 + #304 (manage.md half)
  `role-files-say-it-first`; #283 (options 1, 3, PR-in-flight wording)
  `stall-rows-say-what-git-knows`; #298 items 1-2 `manager-ceiling-row`;
  #300 `rescope-settled-by-merged-superset`; #297
  `plan-on-a-branch-visible`; #307 `ledger-losses-named`; #305 option 1
  `known-red-base-is-the-consumers`.
- Not planned — human's decision left: #249 (scheduler outside the fleet =
  spend; duplicate-holder check withdrawn in #253 after review churn), #251
  (sampling reviewer = money, the issue says decide deliberately), #254
  (proposals 2-3 = product direction, per its own comment), #258 (leads
  already carry cross-item findings; options 2-3 need direction).
- Not planned — evidence disagrees: cost_usd as liveness discriminator
  (#283 opt 2, #298 item 3). orchestrate.md records cost frozen on a
  RUNNING manager; #283's comment records it frozen 19-31m on live ones.
  Needs a research file, not a rule.
- `shared:` added to sibling plans' scopes (release-reds…, orchestrated-only,
  orchestrated-only-docs) on the paths new plans share, so both sides mark
  the reconcile.

## Rejected

- #292's direction 1 as written (`--diff-filter=D` on the net diff): the
  janitor file is added and deleted on the branch, so the net diff is empty.
  The plan reads branch history instead.

## Review

## Blockers

None.

## Where to look

- `docs/plans/` — the queue this adds to.
