---
workstream: starved-counts-green-runs
status: in-progress
branch: manager/starved-counts-green-runs
pr: none
plan: starved-counts-green-runs
issue: none
session: https://claude.ai/code/session_01J1YMK3ThwWNCgDW9ez1fyc
agent: opus
updated: 2026-11-11
next: Run verify, spawn the opus verifier, then finish and merge
---

## Goal

STARVED counts BEHIND refusals, so a red run counts as "outrun" and a human
gets asked a question with no human decision in it. `finish` prints OUTRUN /
NOT OUTRUN on a BEHIND refusal from the certificate; manager.md §4 counts
only OUTRUN and offers the human a real choice.

## Decisions

- A1: refuted in part — a red CATCH-UP keeps the certificate (`checks_gate`
  removes it only when `checks_catch_up` fails), so the certificate cannot say
  "last run green". Plan amended: a second record, `checks_green_file`.
- A2: confirmed — the BEHIND return precedes `checks_catch_up`; selftest case
  "a green head the base outran is OUTRUN" passes.
- A3, A4: transcripts not re-read here; the code does not depend on them.
- A5: not measured; a lost git dir reads NOT OUTRUN, the safe side.
- OUTRUN needs HEAD = the green head, or its tree = clean merge of that head
  with `merge-base HEAD <ref>`: an ancestor test alone passes own commits no
  run saw (plan-checker r2).
- manager.md keeps one sentence; the `next:` template and the why go to a new
  `manager-reference.md` § Starved: manager.md's reading budget had 54 bytes
  free and the template alone is 178.

## Review

- r1: (plan-checker) manager.md edit breaks its reading budget (fixed: detail moved to manager-reference § Starved, manager.md shrank 32 bytes)
- r2: (plan-checker) certificate + ancestor test reads OUTRUN after a red CATCH-UP or own commits (fixed: green record + clean-merge test, selftest cases 5 and 6)
- r3: (plan-checker) "still behind after three" is not in consumer-repos.md (fixed: plan says add one sentence there instead)
- r4: (plan-checker) "NOT OUTRUN" contains "OUTRUN", refute ambiguous (fixed: refute the prefix `OUTRUN       a green run at`)
- r5: (plan-checker) NOT OUTRUN text garbled (fixed: plan text reworded to the printed line)
- r6: (plan-checker) `<commits per run>` and `<k>` undefined (fixed: behind counts per OUTRUN refusal, k = latest)
- r7: (plan-checker) fail-on-origin/main acceptance has no command (fixed: selftest.sh in an origin/main worktree with branch checks.sh)
- r8: (plan-checker) verify count delta unstated (fixed: at least 7 new passes)
- r9: (plan-checker) acceptance items lack a failure statement (fixed)
- r10: (plan-checker) case 4 construction unstated (fixed: a second branch's green in the same worktree)
- r11: paired run: `bash .agents/harness/selftest.sh` on aae714c0 (origin/main ac4086b2 + the claim's handover file) with this branch's checks.sh, 2026-11-11: 4303 passed, 8 failed, all 8 the new `outrun:` expects (no change)
- r12: (verifier) in the documented loop (see behind, merge, finish) every finish starts 0 behind, so OUTRUN never prints and STARVED never fires (fixed: manager.md §4 and § Starved say run `finish` as is first; its refusal is the measurement)
- r13: (verifier) github mode measures no behind, so STARVED became unreachable there (fixed: § Starved keeps the old count when JOHARNESS_CHECKS is not local)
- r14: (verifier) NOT OUTRUN advice "block defect:" contradicts §3's defect = outside the item (fixed: own red is fixed; outside cause blocks per §3)
- r15: (verifier) r11 named a branch commit as origin/main (fixed)
- r16: branch selftest 2026-11-11: `bash .agents/harness/selftest.sh` 4313 passed, 0 failed, 1 skipped; `./joharness.sh verify` (docker layer) 6 passed, 0 failed (no change)

## Blockers

None.

## Where to look

- `joharness.sh:checks_gate` — BEHIND branch and certificate handling.
- `.agents/harness/selftest/checks.sh:kccu_sync` — CATCH-UP fixtures.
