---
workstream: orchestrator-hands-off-at-context-ceiling
status: review
branch: claude/orchestrator-hands-off-at-context-ceiling
pr: none
plan: orchestrator-hands-off-at-context-ceiling
issue: none
session: https://claude.ai/code/session_01LhNpou3t5necUED7S7hFeJ
agent: opus
updated: 2026-10-14
next: Fix ci shellcheck SC2016 in selftest/orchestrated.sh, merge origin/main, ci+verify, retire, PR, merge
---

## Goal

Orchestrator hands its ledger to a fresh successor session after
`JOHARNESS_ORCHESTRATOR_PASSES` passes, so pass N stops re-reading passes
1..N-1 at cache-read price.

## Decisions

- Hand-off text lives in orchestrate.md §4 as a HAND-OFF block after the
  `harness=` recompute rule: it replaces the arm, so it sits where the arm is.
- Trigger: the `pass=` the arm would write exceeds dispatch's `passes :`
  line. Default 6 hands off at pass 6 (it would arm 7).
- One `get_session` self-read per pass feeds the `context:` line, §3's own
  id and the hand-off model, so the report line costs no extra call.
- DRAINED/PAUSED and the out-of-band arm never hand off: nothing is armed
  there, and the pass the out-of-band wake fires decides.
- `knobs-declared-once` not on main: no `KNOBS` row.
- Selftest 2026-10-13 `bash .agents/harness/selftest.sh`: 2740 passed, 0
  failed; `./joharness.sh ci` 2026-10-14 after merging origin/main: `ci: pass`.
- Selftest cases in `selftest/orchestrated.sh` (plan scope), not
  `selftest/dispatch.sh` where other header cases live.

## Rejected

- None yet.

## Review

- r1: (verifier) a `set_session_title` refused at run time passed step 1 and the hand-off ran with the old title, so the successor could exit on its own title check. (fixed: step 2 refused = no hand-off, report `hand-off skipped: set_session_title refused`; a refused restore reports `title not restored`)
- r2: (verifier) leads noted between wakes were in neither the successor's prompt nor a forward. (fixed: step 4 forwards the lead lines this arm would have written, not only the wake's)
- r3: (verifier) no Claude Code Remote `send_message` still let the hand-off run with no lead channel, and an undelivered forward was silent. (fixed: no `send_message` = `hand-off skipped`; not delivered = `lead not forwarded: <stem>`)
- r4: (verifier) GUARD's "the hand-off" meant the respawn-limit record, a second meaning of the term in one file. (fixed: GUARD says "the respawn-limit record")
- r5: (verifier) `JOHARNESS_ORCHESTRATOR_PASSES=0` handed off every pass, undocumented. (fixed: 0 lifts it, dispatch prints `lifted`, knob row says so; selftest case)
- r6: (verifier) `after <n> passes` overstates when an out-of-band arm advanced the counter. (wontfix: the trigger reads the same counter, so the report names what decided; text now says `pass=` is the wake counter)
- r7: (verifier) "a spawn prompt never carries a manager's text" is untrue of a ledger carrying `next=`/`detail=`. (fixed: reason reworded to "never carries a lead"; the ledger fields are already stripped and cut as in every wake)
- r8: (verifier) the forward covered only lead messages. (fixed: any message from another session is forwarded verbatim)
- r9: (verifier) no `get_session` left the `context:` line undefined. (fixed: `context: unread`)
- r10: (verifier) the help text's orchestrator-number list lacked the knob. (fixed)
- r11: (verifier) retitle-before-spawn order was not pinned by any case. (fixed: selftest compares the two step lines' positions)
- r12: (verifier) the dispatch case pins the line, not its position beside `health`. (wontfix: position carries no meaning for a reader that greps the line)

## Blockers

None. Local `./joharness.sh verify` 2026-10-14: 2 passed, 4 failed, every
failure a registry pull or container egress (alpine:3 pull refused), none in
code this diff touches; the merge leans on GitHub's verify run of the head.

## Where to look

- `docs/plans/orchestrator-hands-off-at-context-ceiling.md` — the plan.
