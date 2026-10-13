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

- Gate length: `awk '/^THE SCOUT GATE/,/^Then the AUTHOR GATE/' .claude/commands/clerk.md | wc -l` = 23 (2026-10-13; 46 on main).
- Selftest: `bash .agents/harness/selftest.sh` 2739 passed 0 failed; with joharness.sh reviewer wording reverted, 2738 passed 1 failed ("the reviewer in main's conf reads through"), 2026-10-13.
- Unreadable comments skip that proposal only (`APPROVAL UNREADABLE: <error>`): the read is per issue, so one failure says nothing about the next.
- `scout: answer` also opens `scout:`, so it stales an approval too; accepted as fail-closed rather than adding an exception.
- Revision bracket: `scout: revised` FIRST (answers, target text; stales approval), body edit, then `scout: edited` (stales any approval landing mid-bracket). The plan said one comment; the verifier showed a lone `revised` lets an approval land on the unedited body (r1, r9), so a closing marker it is. Clerk item 3 skips `REVISION OPEN` while the scout comment opens `scout: revised`; recovery = newest own `scout:` comment is `scout: revised` → make the edit (already so = none), post `scout: edited`.
- `orchestrated.md` lines on the gx #645 run stay: they record history, not the rule.

## Rejected

- Clerk checks the body holds the `scout: revised` target text: undefined with no revision, a stranger's or an older revision, or a deletion (r9).

## Review

- r1: (verifier) `scout: revised` before the edit lets an approval land on the unedited body, and a planned proposal is never revised after (fixed: gate item 3, superseded by r9)
- r2: (verifier) any `scout:` comment, a stranger's included, staled approval, contradicting "comments by anyone else" (fixed: only a footed `scout:` comment by a write-access author stales)
- r3: (verifier) orchestrated.md clerk row still said "approval event newer than its last revision" (fixed)
- r4: (verifier) an in-flight old `scout: revising` is orphaned (wontfix: no open scout issue on joharness 2026-10-13; gx #645 recorded as revised in orchestrated.md; acceptance requires 0 `scout: revising` in scout.md)
- r5: (verifier) "newer" did not say created or updated time (fixed: by created time)
- r6: (verifier) `Approved, but change X` passes the first-word rule (wontfix: the plan specifies the first-word rule; a reviewer writes a condition as a comment without `approved` first)
- r7: (verifier) a failed later page could be read as "no more comments" (fixed: any page failing = APPROVAL UNREADABLE)
- r9: (verifier) r1's item 3 "body holds the target text" deadlocks: no `scout: revised` at all, a stranger's `scout: revised`, an older revision's text, a deletion (fixed: replaced, not patched — the scout ends a revision with `scout: edited`; the clerk skips `REVISION OPEN` while the scout comment opens `scout: revised`)
- r10: (verifier) scout §5 recovery keyed on the newest own comment of any kind (fixed: keyed on the newest own `scout:` comment, same comment the clerk's item 3 reads)
- r11: (verifier) scout.md and orchestrated.md lines 40 and 413 still said any `scout:` comment stales (fixed: footed `scout:` comment by the scout / a write-access author)
- r12: (verifier) an approval given before the edit (fixed by r9: `scout: edited` is newer, so it stales that approval)
- r8: gate walk, six cases against clerk.md items 1-3: reviewer `approved` after `scout: revised` + `scout: edited` → taken (and after `scout: revised` alone → skipped, item 3); `scout: revised` after `approved` → skipped (item 2); stranger's `approved` → skipped (item 1, login); footed `approved` by reviewer login → skipped (item 1, footer); maintainer comment after reviewer `approved` → taken (stales only via footed `scout:`); `Approved.` → taken (case, punctuation) (no change)

## Blockers

None.

## Where to look

- `.claude/commands/clerk.md` — THE SCOUT GATE.
