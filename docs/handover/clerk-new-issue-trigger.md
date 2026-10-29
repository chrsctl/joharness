---
workstream: clerk-new-issue-trigger
status: in-progress
branch: clerk-new-issue-trigger
pr: none
plan: clerk-new-issue-trigger
issue: none
session: https://claude.ai/code/session_01J1YMK5uhS1o6RkivUJMsPa
agent: opus
updated: 2026-10-29
next: Merge origin/main in, ci, then finish (retire commit, PR, merge) clerk_last_read and the cmd_clerk lines
---

## Goal

A new open GitHub issue starts the clerk ahead of the 24h cadence: the
orchestrator reads issues, `./joharness.sh clerk` supplies `last read` and
`issue wait`.

## Decisions

- A1, A2, A4, A5: confirmed (plan-checker read the cited lines). A3: refuted as written — the computation lives in clerk_park_early; plan fixed.
- clerk_last_read fails closed on a failed clerk-merge lookup (was: read as no landed clerk); the defect trigger's own comment says any failed read makes nothing due early.
- Dispatch prints the `clerk issue read` tail line rather than the orchestrator inferring the holds: every other role is driven by a dispatch line.
- Measured 2026-10-29: `bash .agents/harness/selftest.sh` 3938 passed, 0 failed; with origin/main's joharness.sh, 14 failed (the 13 new positive cases, plus knobs-declared on JOHARNESS_RETRO_FLOOR_HOURS: origin/main had moved past the merge base; against b0424e98 the verifier measured 13). `./joharness.sh ci`: ci: pass. `./joharness.sh verify`: first run 5 passed 1 failed (unnamed, output not kept, during provisioning), then 6 passed 0 failed twice on this branch and 6 passed 0 failed on origin/main. SHIPS reproduction (scratch repo, joharness.sh + conf only): `clerk | grep -cE` printed 2.

## Rejected

- None yet.

## Review

- r1: (plan-checker) "landed = first commit" contradicts clerk_park_early, which moves both records back by the knob (fixed: plan says both, helper clerk_last_read; orchestrated.md row corrected)
- r2: (plan-checker) knob 0 read two ways (fixed: 0 switches the trigger off, `issue wait: off`)
- r3: (plan-checker) computation sits inline behind clerk_park_early's early returns (fixed: plan names the extracted helper, knob 0 = no shift)
- r4: (plan-checker) a skipped issue re-fires each run (wontfix: fires again only when the defect knob exceeds the issue wait plus the pass's length; defaults never; named in Out of scope)
- r5: (plan-checker) a new issue behind a full batch is never reached by the early clerk (wontfix: the batch order is clerk.md's and the human's knob; named in Out of scope)
- r6: (plan-checker) scout exclusion misses titles starting `scout:` (fixed)
- r7: (plan-checker) Traps claims a conf-keys entry is needed (fixed: dispatch keys need none)
- r8: (plan-checker) Acceptance items name no command (fixed: the selftest topic, `0 failed`)
- r9: (plan-checker) defect-trigger equality cannot be asserted from output (fixed: one helper; dispatch-park cases pin the defect side)
- r10: (plan-checker) SHIPS line not runnable here (fixed: the fixture is a consumer copy of joharness.sh)
- r11: (plan-checker) placement under the unreadable cadence unstated (fixed: both lines print on every path)
- r12: (plan-checker) A3 cites clerk_due, not clerk_park_early (fixed)
- r13: (plan-checker) overlap with role-on-demand, retro-event-triggers undeclared (no change: shared: scope, whichever lands later merges origin/main)

- r14: (plan-checker) the issue trigger ignored dispatch's holds (pause, stale view) (fixed: dispatch prints `clerk issue read` / `held` and the paragraph reads only on it)
- r15: (plan-checker) another issue filed in the knob-hour before a pass's record re-fires a clerk (wontfix: at most one idle pass per issue with issue wait >= defect knob; bound stated in Out of scope)
- r16: (plan-checker) the selftest is canonical-only, so not the SHIPS check (fixed: a consumer-run grep command)
- r17: (plan-checker) Acceptance items name no command or expected text (fixed: fixture, commands and expected strings)
- r18: (plan-checker) UNREADABLE path and the orchestrator side had no acceptance (fixed: UNREADABLE case and dispatch-line cases)
- r19: (plan-checker) `last read : none` undefined for the trigger (fixed: every issue counts as later)
- r20: (plan-checker) which failed reads stop the trigger (fixed: list_issues, last read, planned, claimed)
- r21: (plan-checker) orchestrate.md edit scope ambiguous (fixed: trigger list and ledger form named)
- r22: (plan-checker) clerk_park_early missing from Where to look (fixed)
- r23: (plan-checker) overlap with role-on-demand understated (fixed: Traps names the shared sections)
- r24: (plan-checker) "first commit time" author or committer, ISO form unstated (fixed: %at, YYYY-MM-DDTHH:MM:SSZ)

- r25: (plan-checker) an issue-fired clerk beside a retro audit/retro DUE line: which goes first (fixed: the clerk; no retro spawn that pass)
- r26: (plan-checker) the re-fire bound needs issue wait >= defect knob, unenforced (fixed: cmd_clerk raises the wait to the defect knob)
- r27: (plan-checker) a git failure in the extracted read prints `none`, failing open (fixed: any failed read = UNREADABLE)
- r28: (plan-checker) dispatch line text and position unstated (fixed: both in Scope)
- r29: (plan-checker) Acceptance says no failure form (fixed: one failure line)
- r30: (plan-checker) SHIPS line not runnable here (fixed: reproduced in a scratch repo holding only joharness.sh and a conf)
- r31: (plan-checker) row spellings `planned`/`claimed`/`clerk` miss their padding (fixed)
- r32: (plan-checker) ISO formatting portability (fixed: GNU then BSD date, as dispatch does)
- r33: (plan-checker) DEFECT row correction serves no Goal clause (no change: the row documents the helper this plan extracts; a false row is a defect)
- r34: (plan-checker) a read preceding its record by more than the knob misses an issue (wontfix: git holds no read time; such an issue waits on the cadence, today's behaviour; named in Out of scope)
- r35: plan-checker stopped at round 3 (counts 13, 11, 10 falling); remaining findings fixed or wontfix above (no change)

- r36: (verifier) DEFECT_CLERK_HOURS=0, or a pass longer than the knob from read to record, misses an issue filed mid-pass (wontfix: plan Out of scope, Missed issues; git holds no read time)
- r37: (verifier) an issue-fired clerk behind a full batch never reads its issue (wontfix: plan Out of scope, batch order; r5)
- r38: (verifier) four new refutes pass on origin/main (no change: they guard against over-printing; the 13 expects each fail on b0424e98's joharness.sh, verifier-measured)
- r39: (verifier) handover baseline 14 failed does not reproduce, 13 (fixed: the 14th was knobs-declared on a newer origin/main's knob; Decisions corrected)
- r40: (verifier) clerk printed a live issue wait with the cycle off (fixed: `issue wait: off — the clerk cycle is off`; the selftest case reads 1h on the previous commit)
- r41: (verifier) role-table retro rows lack the issue-fired-clerk exception (fixed: both rows name it)
- r42: (verifier) SHIPS reproduction reached only the UNREADABLE path (fixed: rerun after fetching the scratch origin: `cadence   : not due`, both lines, count 2)

## Blockers

None.

## Where to look

- `joharness.sh:clerk_due` — the one "last read" computation to reuse.
