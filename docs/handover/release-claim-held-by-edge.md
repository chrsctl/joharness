---
workstream: release-claim-held-by-edge
status: in-progress
branch: release-claim-held-by-edge
pr: none
plan: release-claim-held-by-edge
issue: 626
session: https://claude.ai/code/session_012hikkNfLjLPU4pMwpU4VZG
agent: opus
updated: 2026-10-25
next: Confirm trimmed dispatch run and r20 mutation fails; ci; then finish (PR, merge)
---

## Goal

Issue #626 follow-up: a parked claim whose block the queue has since absorbed
through a `needs:` edge should release itself, without a human's `halt`.

## Decisions

- A1: confirmed — `.agents/harness/queue-context.sh:265-270` builds one label `[..., blocked by: <x>, claimed on <branch>]`; dispatch's claimed-row loop holds it in `label` (the plan-checker showed the cited 8502 reader skips claimed rows).
- A2: refuted — `cmd_halt` has no write helper; its guard verb, `next:`, commit subject and edge-record restore are inline. `release` reuses `cmd_guard`, `release_rewrite`, `release_why` and the lease pattern, and keeps its own short write loop; halt is untouched.
- Writer of `abandoned` without a human: the orchestrator, through `release`, only for a claim dispatch prints RELEASABLE. Guard `release` = kill/loop checks plus the janitor's `pr:` refusal.
- Release needs the block's own next: to name the needs: stem as a token (r16): an unrelated edge absorbs nothing. Only a token equal to a queue-label stem counts; the words are never acted on.
- Edge newer than block: compared as author timestamps (block commit on the claim branch, needs-adding first-parent commit on the base); either unreadable = not releasable. Equal = not releasable.
- `release` re-runs dispatch in-process and parses the claimed plan rows carrying `RELEASABLE:`; the decision read is the tracking ref right after that read.
- retro_queue_block: a released claim reads `abandoned`, so it stops making a retro due early; intended.

## Rejected

- None yet.

## Review

- r1: (plan-checker) guard release lacked the pr: refusal the Traps demand (fixed)
- r2: (plan-checker) A2 wrong, halt has no reusable write helper (fixed)
- r3: (plan-checker) next: dropped release_why (fixed)
- r4: (plan-checker) A1 cited a reader that skips claimed rows (fixed)
- r5: (plan-checker) block age is minutes, not a commit; unknown age unhandled (fixed)
- r6: (plan-checker) .agents/harness/AGENTS.md lists lease users, not in scope (fixed)
- r7: (plan-checker) orchestrated.sh pins docs, not in scope (fixed)
- r8: (plan-checker) release-command tests placed in guard.sh (fixed)
- r9: (plan-checker) two BLOCKED rows, anchor ambiguous (fixed)
- r10: (plan-checker) fixture acceptance not runnable, plan vs requirement unstated (fixed)
- r11: (plan-checker) README quote spans a line break (wontfix: content correct, grep is not the reader)
- r12: shellcheck SC2015 on the edge comparison in release_edge (fixed)
- r13: dispatch read each parked row's block history twice, past dispatch-order's one-query bound; one read now, dispatch_block_age_min folded into dispatch_block_ts (fixed)
- r14: the post-release label was asserted on dispatch output, which never prints a held plan's label; read from the queue hook now (fixed)
- r15: (verifier) an empty, reasonless or capitalised `Money:` next: was RELEASABLE and lost its INVALID BLOCK? mark; release_reason_ok now requires block_reason_ok too (fixed)
- r16: (verifier) any newer needs: edge released a block that never named it; the block's next: must name the stem as a token (fixed)
- r17: (verifier) the blocked-count test passed without the fix; now asserts the count is unchanged across a release (fixed)
- r18: (verifier) Acceptance said verify runs dispatch.sh; it is ci (fixed)
- r19: (verifier) consumer-side Acceptance cannot run, selftests are canonical-only (fixed: says so)
- r20: (verifier) two claims on one branch: release could write a claim dispatch never judged; release re-checks pr:, reason and stem on the file it writes (fixed)
- r21: (verifier) the ledger rule asked for a plan stem the release line lacked; the line prints `plan <stem>` (fixed)
- r22: (verifier) no case for the requirement after release, negatives not refuted on release DUE (fixed); no case for a lease lost between guard and push (wontfix: the window cannot be entered from a test without a hook; guard's moved-head refusal is tested)
- r23: (verifier) author time can predate a rebase-merged edge (wontfix: the error is a false not-releasable, the safe side; the plan names author time)
- r24: (verifier) plan named dispatch_block_age_min; branch 2 behind main (fixed: renamed, merged origin/main)
- r25: (verifier) r20's per-file re-check had no test failing without it; case with two claims on one branch, product: and money: (fixed)
- r26: (verifier) stale comment said no stem is read from next: (fixed)
- r27: (verifier) the reason word itself counted as the stem token; next_names reads after the first colon (fixed)

## Blockers

None.

## Where to look

- `joharness.sh` dispatch parked-claim row near `BLOCKED: the human's`.
