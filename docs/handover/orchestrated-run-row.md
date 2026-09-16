---
workstream: orchestrated-run-row
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: orchestrated-run
issue: none
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-16
next: Review, retire this file and open the pull request
---

## Goal

Scope bullet 2 of `docs/plans/orchestrated-run.md`, for the run in flight in
`chrsctl/gx` since 2026-09-11. The requester asked for the counting and the
row. Not a new run: this one is already going and its numbers are the ones
the Runs table wants.

## Decisions

- One row for the CLEAN WINDOW only, 2026-09-11T09:53:25Z to
  2026-09-13T03:50:34Z, with the stall recorded beside it rather than
  inside it. Merges stop dead for 3.5 days after that because GitHub could
  allocate no runner account-wide, so step 7's first condition could never
  be met; a rate spanning the outage measures the outage.
- The run is NOT over, so the row says so. `.agents/docs/orchestrated.md`
  already has the shape for this — run 2's paragraph is an in-flight
  observation with no row — but this run has enough counted to earn one.
- Ledger columns (nudges, kills, respawns) come from the orchestrator's own
  one-shot check-in Routines, whose prompts carry the ledger. That reads
  another session's record without interrupting a live one.
- The plan's state block says gx's knobs are unconfirmed. False, and this
  session made it so by not reading gx: the conf carries
  `JOHARNESS_MAX_MANAGERS=4` with the requester's 2026-09-06 decision, and
  `JOHARNESS_MODE=orchestrated` merged. Corrected in the same pull request.

## Rejected

- Messaging the live orchestrator for its ledger. It is RUNNING and mid-pass;
  a message queues a turn and costs the run a step for data its own Routines
  already carry.

## Review

- r1: (session) the first framing of this work blamed the 3.5-day gap on the GitHub Actions outage, reading it from gx's conf note. The orchestrator's own ledger says otherwise: its self-armed pass chain stopped at 04:14Z and every manager resumed within 30 seconds of it at 14:54Z three days later, so the fleet was not blocked, it was not running. Both walls are real and they are different findings. (fixed — the entry names the freeze mechanism, and the outage separately under the boundary collision)
- r2: (session) "at least 31 managers" from a 40-session read would have been a written number dressed as a count: the dump was capped and its oldest entry postdated the run's start. (fixed — re-read at limit 100, whose oldest session predates the run by four days, giving 59 inside the window and 61 to date)
- r11: (session) r4 and r7 corrected the cost and the freeze in two files and left the plan's state block carrying the imprecise pair, 5252 USD and "an 82-hour freeze" — the same defect one file over, found by grepping each shared number across all three files rather than re-reading the diff. (fixed — 5252.42 and 82h40m everywhere; the check that found it is worth repeating before any pull request that spreads one number across files)
- r10: (session) the scripted edit for r5 failed on a line break the earlier round had moved, and the shell chain ran `ci`, committed and pushed regardless — so `07c9a79` went out with the requirement file's heading saying two runs counted and its body still saying the run had no row. `ci` cannot see a contradiction between two sentences, so nothing caught it. (fixed in the next commit; the lesson is that a partial edit must fail the chain, not just print)
- r4: (verifier) the cost line's rounded parts did not add to its rounded total: 4864 plus 389 is 5253, printed as 5252. The one figure in the diff needing no external source, failing its own addition, in a file whose rule is to trust counted numbers. (fixed — the exact figures, 4863.78 and 388.64, totalling 5252.42)
- r5: (verifier) the diff left `docs/product/orchestrated-mode.md` asserting "one run counted, a later one in flight and uncounted" and "no row", both false the moment this pull request lands run 3's row — and Scope bullet 3, which is in this plan's declared scope, covers exactly that file. (fixed — the requirement's annotation now carries run 3 and what it misses)
- r6: (verifier) the merge count cited `merged:>=2026-09-11`, a query with no upper bound, as the source of a figure bounded at the freeze. The command as written returns every merge since, not the window's. (fixed — the filter is named beside the query)
- r7: (verifier) the freeze read 3d10h in the row and 82 hours in the prose, both dropping 40 minutes, while the wall-clock beside them keeps minute precision off the same pair of timestamps. (fixed — 82h40m in both)
- r8: (verifier) `.agents/docs/orchestrated.md` stated two policies for an unfinished run: run 2's paragraph says its row is not written yet, run 3 takes a row. The distinction lived only in this workstream file, which retires. (fixed — the criterion is in the Runs section itself: counted columns and a window closed by a real event)
- r9: (verifier) "actually", a caveman-banned filler, in the added prose. (fixed)
- r3: (session) merges nearly went in as 44 from the repo-wide search, which counts two harness syncs and a session the orchestrator names as the human's own. The fleet's own count is 41. (fixed — 41 in the row, 44 named beside it; and the three-merge difference now names the two syncs it can name and admits the third is unattributed, rather than assigning it to a session on inference)

## Blockers

None.

## Where to look

- `.agents/docs/orchestrated.md` Runs — run 1's row is the shape to match.
- `chrsctl/gx:joharness.conf` — the knobs, and the requester's own note on
  why checks went local on 2026-09-16.
