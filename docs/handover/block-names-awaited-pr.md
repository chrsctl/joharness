---
workstream: block-names-awaited-pr
status: in-progress
branch: manage/block-names-awaited-pr
pr: none
plan: block-names-awaited-pr
issue: 596
session: https://claude.ai/code/session_01TmpgarMNYAZa3MkLwRnKKu
agent: opus
updated: 2026-10-24
next: Run ci and verify on the r10-r14 fixes, then retire and open the PR
---

## Goal

A `core path:` block may name the human PR it waits on
(`core path: waiting on #<N>: <question>`); `dispatch` lists the item
resumable once `origin/main` shows that PR merged (issue #596).

## Decisions

- A1: confirmed — `grep -n "waiting on #" joharness.sh .claude/commands/manage.md` printed nothing before the change.
- A2: confirmed — `cmd_dispatch`'s `fx_*` arrays carry the defect RESUME rows; the merged-PR row is a third `fx_kind` (`MERGED`) ranked with RESUME, so slots, verdict and scope hold reuse them unchanged.
- A3: confirmed — only `core path: waiting on #<N>` with that PR's merge commit on the base's first parent leaves the human-block branch; every other block keeps its row.
- `next:` is re-read with `gr_field_raw`: the parsed field stops at ` #` (YAML comment), as the defect path already does.
- Built by the manager, no workers: three files share one design and the selftest needs the dispatch change; splitting would serialize anyway.
- Plan fixed on the branch (plan-checker): § Resume lives in `orchestrate-reference.md` (added to scope), `selftest.sh` dropped from scope, Acceptance made runnable plus a consumer-side line.

## Rejected

## Review

- r1: (plan-checker) orchestrate.md has no § Resume; it is orchestrate-reference.md, not in scope (fixed)
- r2: (plan-checker) reused RESUME row would get the defect resume next: and share STUCK counting (fixed: own row text and own next: wording in § Resume)
- r3: (plan-checker) acceptance "fails reverted" is no command (fixed)
- r4: (plan-checker) acceptance names no failure output (fixed)
- r5: (plan-checker) Where to look misses the resume machinery and orchestrate-reference.md (fixed)
- r6: (plan-checker) selftest.sh in scope with no work (fixed)
- r7: (plan-checker) manage.md "never respawned" would contradict the exception (fixed)
- r8: (plan-checker) a waiting core path: block releases its scope, so the resumed item may race an overlapping plan (wontfix: same as every human block today; resumed, its scope is held again and the manager reconciles by merging origin/main)
- r9: (plan-checker) issues #596/#597 unverified (no change: plan cites them, nothing in code depends on them)
- r10: (verifier) a merge older than the block resumes it, so a re-block on the same #N loops unbounded on nudges (fixed: merge commit must be dated no earlier than the block; unknown block age reads false)
- r11: (verifier) `--grep` matched a body line, and any head branch counted (fixed: subject only, head must be `<owner>/human/`)
- r12: (verifier) manage.md "the one block respawned" false beside defect RESUME (fixed: "the one human's block respawned")
- r13: (verifier) a resumed item whose own PR carries `human-review` from the block still needs a second human touch at finish (wontfix: the label rule is Loop's, `.agents/harness/AGENTS.md`, outside this plan's scope; named in the PR body)
- r14: (verifier) no cases for the slot-wait MERGED row, merge-before-block, body match (fixed: four cases; each new refute FAILs against the previous commit's joharness.sh)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — blocked rows and PARKED RESUME rows.
