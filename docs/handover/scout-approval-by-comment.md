---
workstream: scout-approval-by-comment
status: in-progress
branch: manage/scout-approval-by-comment
pr: none
plan: scout-approval-by-comment
issue: 461
session: https://claude.ai/code/session_017cwAYs3qgKcSgStGZVWrDU
agent: opus
updated: 2026-10-13
next: Merge origin/main, rerun ci and verify, retire plan and workstream file, open PR
---

## Goal

Scout proposals are approved by the reviewer's `approved` comment, read with
`issue_read get_comments`, not by the `approved` label event from the timeline
(#459, #461 item 2).

## Decisions

- Gate length: `awk '/^THE SCOUT GATE/,/^Then the AUTHOR GATE/' .claude/commands/clerk.md | wc -l` = 24 (2026-10-13; 46 on main).
- Selftest: `bash .agents/harness/selftest.sh` 2739 passed 0 failed; with joharness.sh reviewer wording reverted, 2738 passed 1 failed ("the reviewer in main's conf reads through"), 2026-10-13.
- Unreadable comments skip that proposal only (`APPROVAL UNREADABLE: <error>`): the read is per issue, so one failure says nothing about the next.
- `scout: answer` also opens `scout:`, so it stales an approval too; accepted as fail-closed rather than adding an exception.
- Scout §5 recovery: a newest own `scout: revised` whose target text is not in the body yet = make that edit next pass (the comment already stated it, so an approval after it covered that text).
- `orchestrated.md` lines on the gx #645 run stay: they record history, not the rule.

## Rejected

- None yet.

## Review

- r1: (verifier) `scout: revised` before the edit lets an approval land on the unedited body, and a planned proposal is never revised after (fixed: gate item 3, body must hold the revised target text, else `REVISION OPEN`)
- r2: (verifier) any `scout:` comment, a stranger's included, staled approval, contradicting "comments by anyone else" (fixed: only a footed `scout:` comment by a write-access author stales)
- r3: (verifier) orchestrated.md clerk row still said "approval event newer than its last revision" (fixed)
- r4: (verifier) an in-flight old `scout: revising` is orphaned (wontfix: no open scout issue on joharness 2026-10-13; gx #645 recorded as revised in orchestrated.md; acceptance requires 0 `scout: revising` in scout.md)
- r5: (verifier) "newer" did not say created or updated time (fixed: by created time)
- r6: (verifier) `Approved, but change X` passes the first-word rule (wontfix: the plan specifies the first-word rule; a reviewer writes a condition as a comment without `approved` first)
- r7: (verifier) a failed later page could be read as "no more comments" (fixed: any page failing = APPROVAL UNREADABLE)
- r8: gate walk, six cases against clerk.md items 1-3: reviewer `approved` after `scout: revised` (body edited) → taken; `scout: revised` after `approved` → skipped (item 2); stranger's `approved` → skipped (item 1, login); footed `approved` by reviewer login → skipped (item 1, footer); maintainer comment after reviewer `approved` → taken (stales only via footed `scout:`); `Approved.` → taken (case, punctuation) (no change)

## Blockers

None.

## Where to look

- `.claude/commands/clerk.md` — THE SCOUT GATE.
