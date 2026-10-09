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
  `stall-rows-say-what-git-knows`; #298 item 1 (+ a report-only row) `manager-ceiling-row`;
  #300 `rescope-settled-by-merged-superset`; #297
  `plan-on-a-branch-visible`; #307 `ledger-losses-named`; #305 option 1
  `known-red-base-is-the-consumers`.
- Not planned — human's decision left: #249 (scheduler outside the fleet =
  spend; duplicate-holder check withdrawn in #253 after review churn), #251
  (sampling reviewer = money, the issue says decide deliberately), #254
  (proposals 2-3 = product direction, per its own comment), #258 (leads
  already carry cross-item findings; options 2-3 need direction), #298
  item 2 (an automatic refresh kills live work; its threshold is the
  human's) and item 4 (route half-exists, per its own comment).
- Not planned — evidence disagrees: cost_usd as liveness discriminator
  (#283 opt 2, #298 item 3). orchestrate.md records cost frozen on a
  RUNNING manager; #283's comment records it frozen 19-31m on live ones.
  Needs a research file, not a rule.
- `shared:` added to some sibling plans' scopes (release-reds…,
  orchestrated-only, orchestrated-only-docs) where a new plan shares the
  path. Not all: `heartbeat-is-a-precondition`, `scout-command` (claimed,
  not mine to edit) and `upstream-placement-defects` stay unmarked, which
  still splits waves — the safe direction.

## Rejected

- #292's direction 1 as written (`--diff-filter=D` on the net diff): the
  janitor file is added and deleted on the branch, so the net diff is empty.
  The plan reads branch history instead.

## Review

Depth opus (`./joharness.sh review`). One verifier pass, 17 findings, all
fixed in the commit that records them unless marked.

- r1: (verifier) rescope plan's merged-retire `git log` lacked `--full-history`; finds 0 deletes on this repo, 12 with it (fixed: flag required, `scout_retired_ts` named)
- r2: (verifier) janitor-sees plan's per-ref log misses a retire after the sweep merged `main` in (fixed: `--full-history`, and a fixture for that shape)
- r3: (verifier) janitor-sees plan ignored `scout_retired_ts`, the solved shape: one log, `-m`, dated by retire commit not tip (fixed: redesigned on it)
- r4: (verifier) zero-candidate plan's fixture claim false — `mgr-ownplan` still a candidate there, `n_cand`=1 (fixed: plan adds a fixture releasing it, check before expect)
- r5: (verifier) eight plans ran topic files alone; they are "Not runnable alone", exit 0 over nothing, and wrote `/janitorwork` (fixed: `bash .agents/harness/selftest.sh`)
- r6: (verifier) stopped-fleet line at 1x stall fires on every single-manager stall and blocks its kill path (fixed: 24x, and the line decides nothing)
- r7: (verifier) stall plan missed the `"naming the respawn as the merge"` expect its own edit breaks (fixed)
- r8: (verifier) `orchestrated-only` deletes `cmd_drain`, a `janitor_branches` reader (fixed: trap says reconcile, fallback named)
- r9: (verifier) plan-on-branch compared raw `plan:`; a path spelling lists a branch's own plan; released branches undecided (fixed: `lint_stem`, abandoned dropped, fixtures)
- r10: (verifier) ceiling plan assumed the claimed-row walk reads `pr:`; it does not (fixed: add it to the read)
- r11: (verifier) Decision overstated `shared:` coverage (fixed: wording; `orchestrated-only`'s dispatch.sh marked)
- r12: (verifier) janitor-rules plan put a field rule in janitor.md, which defers field rules to orchestrate.md; misattributed the quote (fixed: rule in orchestrate.md field table, janitor.md points)
- r13: (verifier) known-red plan wrote #305 option 2's shape as guidance and asserted step 7 satisfied (fixed: shape left open, step 7 stated as binding)
- r14: (verifier) janitor-sees fixtures would follow the suite's 2026-01 dates and fall outside a wall-clock bound (fixed: dated relative to now, said)
- r15: (verifier) mapping said #298 items 1-2; item 2 is out of scope (fixed: mapping and not-planned list)
- r16: (verifier) commit `9dc0ebd` message says "twelve plans from eleven open issues"; it is 11 plans, 14 issues (wontfix: history is not rewritten; correct numbers in the PR body)
- r17: (verifier) line-number anchor in role-files; backslash escapes in a code span; rebuilt `@new` respawn count unstated (fixed: symbol anchor, fenced block, `respawns=<RESPAWN_LIMIT>` stated as intended)

## Blockers

None. Leftover outside the repo: `/janitorwork`, `/janitororigin.git`
(selftest fixtures a topic file run alone created; `rm` refused by the
safety check — the human's to delete).

## Where to look

- `docs/plans/` — the queue this adds to.
