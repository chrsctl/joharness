---
workstream: one-release-command
status: in-progress
branch: claude/one-release-command
pr: none
plan: one-release-command
issue: none
session: https://claude.ai/code/session_01J1YMK6KyCC596i2QaG6VSX
agent: opus
updated: 2026-10-28
next: Full ci and verify on this head, then the retire commit, pull request, merge
---

## Goal

Make janitor --apply, halt and release ONE command (`release`, with
`--human`; `halt` an alias), and remove `free` and the freer role. The user
asked to simplify the commands that unstick abandoned work.

## Decisions

- A1: confirmed — janitor_apply, cmd_halt and cmd_release each call release_rewrite, release_why, cmd_guard and push --force-with-lease.
- A2: confirmed — cmd_free merges onto the caller's own branch and never pushes.
- A3: confirmed — cmd_guard's only in-script callers pass janitor, halt and release; kill and loop appear only in orchestrate-reference.md GUARD.
- A4: confirmed — JOHARNESS_CLERK_STALE_HOURS row, default 24.
- The `done, no pull request` reason also waits HANDOVER_STALE_SECONDS, and needs a plan: named (not none): a `plan: none` done record is a role's (a surveyor's holds-genuine stays unmerged by design), which the freer also refused.
- A no-claim branch is one that never ADDED a workstream file since the base: an edge that retired its claim waits on its pull request and is not listed.
- Behaviour lost 1: a doc-only branch with a stale claim is released, not merged; its plans stay on the branch and every release line names them `plans not landed:` for a human to re-file.
- Behaviour lost 3: a doc-only branch that never claimed is a report-only `no claim:` line; nothing is written, branch deletes stay a human's.
- Write order per branch: tip, guard, then the report check — as janitor --apply did, so a gone branch exits 0 whether listed or not.

## Rejected

## Review

- r1: (plan-checker) Behaviour lost 3 contradicts A4 and Out of scope on clerk branches with no claim (fixed: A4 and Out of scope now forbid writing only; the report may name the plans)
- r2: (plan-checker) the fixed interface lists two reasons, the plan adds a third, done no pull request (fixed: three reasons, plus the report-only no claim line)
- r3: (plan-checker) a report of releasable branches only cannot print the pr: exempt detail (fixed: non-qualifying stale claims stay listed, indented, with why)
- r4: (plan-checker) removing dispatch_freeable leaves no doc-only scan for no claim (fixed: the replacement scan is specified)
- r5: (plan-checker) five queued plans share files and are unnamed in needs: or Traps (fixed: Traps names them; needs: stays none, dispatch holds overlapping scope apart)
- r6: (plan-checker) acceptance items name no failure shape (wontfix: each line's expected value is the pass condition; anything else fails)
- r7: (plan-checker) prose acceptance bullets are not runnable here (wontfix: the new cases land as selftest assertions verify runs; the consumer line is a SHIPS note)
- r8: (plan-checker) the dispatch grep passes on unchanged code because live origin has no such branch (wontfix: the selftest fixtures pin the removed strings; the grep is a smoke check)
- r9: (plan-checker) the halt no-such-branch line passes unchanged (no change: it pins halt's output staying equal to release --human, which the previous line discriminates)
- r10: (plan-checker) A3's grep finds nothing; the orchestrator spells GUARD kill (fixed: evidence rewritten)
- r11: (plan-checker) cleanup already carries leftovers and merged branches: a duplicate, not a move (fixed: the janitor copies drop, cleanup's merged section gains the five names)
- r12: (plan-checker) the release DUE tail line already exists (fixed: worded as extending it)
- r13: (plan-checker) cmd_guard has five checks, the anchor names four (fixed)
- r14: (plan-checker) the Lineup has no freer row; it is orchestrated.md's Roles table (fixed)
- r15: (plan-checker) a stale blocked claim with a needs: reason reads both qualifying and never released (fixed: listed once, by its needs: reason)
- r16: (plan-checker) report lines share the release   : prefix the orchestrator's ledger rule counts (fixed: the ledger reads the write's lines only)
- r17: (plan-checker) a release topic needs a file scope: lacks (fixed: release.sh in scope, janitor.sh and halt.sh go)
- r18: (plan-checker) cleanup's five merged names have no test in scope (fixed: cleanup.sh in scope and pinned)
- r19: (plan-checker) no subject for the done reason (fixed: release: done, no pull request)
- r20: (plan-checker) Removed omits n_freer_live and the free-* in-flight walk (fixed)
- r21: (plan-checker) the tree moved during the round-2 read (no change: a plan check reads the plan; the verifier runs on a still tree)
- r22: (verifier) orchestrate-reference § Release told the orchestrator to release every release DUE branch, stale and done ones included, with no session check (fixed: a needs: one at once, a stale or done one only once get_session reads ARCHIVED or not found)
- r23: (verifier) a due release left the DRAINED verdict at exit, so the freed plan waited for a human restart (fixed: the verdict names a due release and says schedule the next pass)
- r24: (verifier) release_done_only's whole-diff test had no case failing without it (fixed: a stale done branch carrying code is never listed)
- r25: (verifier) dispatch dropped a branch's own claimed plan from plans not landed, the report kept it (fixed: dispatch reads release_unlanded per branch, as the report does)
- r26: (verifier) a branch-controlled workstream path printed raw could forge a queue line in the report (fixed: paths printed through the stem charset; the report's queue section matches the write's anchored shape)
- r27: (verifier) release_human leaked a global commit and copied release_push (fixed: calls release_push)
- r28: (verifier) stale and done write lines carry no plan token for the ledger rule (fixed: they print plan <stem> when the claim names one; the ledger rule says no plan token = no entry); report, dispatch and write column orders differ (wontfix: report and dispatch lead with the reason, the write keeps the needs: write's path-first shape the ledger already reads)
- r29: (verifier) release_unlanded's live filter had no case failing without it (fixed: a leftover plan is never named not landed)
- r30: (verifier) Behaviour lost 1 and 3 not recorded in Decisions (fixed)
- r31: (verifier) the no-claim line tells a human to re-file plans an open pull request may still land (fixed: wording names the open pull request first)
- r32: (verifier) stale janitor comments in joharness.sh, handover-context.sh, scout.sh, retro.sh (fixed in joharness.sh and handover-context.sh; scout.sh and retro.sh: wontfix: they describe fixture history, a role stem named janitor-<date>, still true of past branches)

## Blockers

None.

## Where to look

- `joharness.sh:release_rewrite` — the shared write.
