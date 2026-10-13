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
- Revision bracket: `scout: revision` FIRST (answers, target text; stales approval), body edit, then `scout: revised` (closes it, stales any approval landing mid-bracket). Deviates from the plan's literal "post `scout: revised` first": a lone opener lets an approval land on the unedited body (r1, r9), and naming the opener `scout: revised` flips that word's meaning on revisions finished under the old `revising`→`revised` bracket, e.g. gx #645, failing the plan's ship check (r13). Clerk item 3 skips `REVISION OPEN` while the scout comment opens `scout: revision`; recovery = newest own `scout:` comment opens `scout: revision` → make the edit (already so = none), post `scout: revised`.
- `orchestrated.md` lines on the gx #645 run stay: they record history, not the rule.

## Rejected

- Clerk checks the body holds the `scout: revised` target text: undefined with no revision, a stranger's or an older revision, or a deletion (r9).

## Review

- r1: (verifier) `scout: revised` before the edit lets an approval land on the unedited body, and a planned proposal is never revised after (fixed: gate item 3, superseded by r9, r13)
- r2: (verifier) any `scout:` comment, a stranger's included, staled approval, contradicting "comments by anyone else" (fixed: only a footed `scout:` comment by a write-access author stales)
- r3: (verifier) orchestrated.md clerk row still said "approval event newer than its last revision" (fixed)
- r4: (verifier) an in-flight old `scout: revising` is orphaned (wontfix: no open scout issue on joharness 2026-10-13; gx #645 recorded as revised in orchestrated.md; acceptance requires 0 `scout: revising` in scout.md)
- r5: (verifier) "newer" did not say created or updated time (fixed: by created time)
- r6: (verifier) `Approved, but change X` passes the first-word rule (wontfix: the plan specifies the first-word rule; a reviewer writes a condition as a comment without `approved` first)
- r7: (verifier) a failed later page could be read as "no more comments" (fixed: any page failing = APPROVAL UNREADABLE)
- r9: (verifier) r1's item 3 "body holds the target text" deadlocks: no `scout: revised` at all, a stranger's `scout: revised`, an older revision's text, a deletion (fixed: replaced, not patched — a closing comment ends the revision; item 3 skips `REVISION OPEN` while the opener is newest (names final in r13))
- r10: (verifier) scout §5 recovery keyed on the newest own comment of any kind (fixed: keyed on the newest own `scout:` comment, same comment the clerk's item 3 reads)
- r11: (verifier) scout.md and orchestrated.md lines 40 and 413 still said any `scout:` comment stales (fixed: footed `scout:` comment by the scout / a write-access author)
- r12: (verifier) an approval given before the edit (fixed by r9: `scout: edited` is newer, so it stales that approval)
- r13: (verifier) opener named `scout: revised` makes every old finished revision (gx #645) read open, so the ship check fails (fixed: research step after churn — requirements a-h listed in session; opener `scout: revision`, closer stays `scout: revised`)
- r14: (verifier) LAST COMMENT lost the "dated as its opener" clause, dropping a question posted mid-revision (fixed: clause restored for `scout: revision`)
- r15: (verifier) opener told the reviewer to approve once the body shows the edit, before the closer stales it (fixed: "approve after `scout: revised`")
- r16: (verifier) recovery blocked by the ceiling exit or NO BRIEF (fixed for the ceiling: unfinished revisions run at any ceiling; wontfix for NO BRIEF: fails closed, and a missing brief is the human's to fix)
- r17: (verifier) item 2 undefined with no scout comment; item 1 "newest ... with no footer" readable two ways (fixed: "none = any"; "newest of the unfooted comments")
- r18: (verifier) plan text still says one-comment bracket (no change: the plan file retires in this PR; the deviation is in Decisions and the PR body)
- r8: gate walk, six cases against clerk.md items 1-3: reviewer `approved` after `scout: revision` + `scout: revised` → taken (after `scout: revision` alone → skipped, item 3; never revised → taken, item 2 none = any); `scout: revised` after `approved` → skipped (item 2); stranger's `approved` → skipped (item 1, login); footed `approved` by reviewer login → skipped (item 1, footer); maintainer comment after reviewer `approved` → taken (stales only via footed `scout:`); `Approved.` → taken (case, punctuation) (no change)

## Blockers

None.

## Where to look

- `.claude/commands/clerk.md` — THE SCOUT GATE.
