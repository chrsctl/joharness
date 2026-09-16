---
workstream: stale-session-check
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: stale-session-check
issue: 249
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: opus
updated: 2026-09-16
next: Encode the four measured liveness rules into the health pass, review, retire, open the pull request
---

## Goal

Issue #249, oldest open. Its widened ask is a mechanism that regularly
checks whether sessions have gone stale and acts on it. The issue separates
the two halves itself: the DECISION LOGIC exists in the health pass, and
what is missing is a scheduler that does not share the fleet's fate. It puts
the scheduler out of scope for a first cut, and calls it the whole question.

This is the first cut: four rules the run measured, which the health pass
does not carry and which cost real money without them.

## Decisions

- Scheduler stays out. The issue says so, and any answer is either an
  operator action with money attached or another agent session, which
  inherits the failure it is meant to catch. Reported to the human, not
  decided here.
- Tier opus, above the queue's usual sonnet, because every rule here decides
  whether to kill or respawn a live session. Wrong-but-plausible is the
  failure mode: a rule that reads a working manager as dead destroys work
  and spends the cap twice, which `.agents/docs/agent-selection.md` names as
  the opus condition.
- `.claude/commands/orchestrate.md` is a protocol path. Supervised mode, so
  a session may commit it; under unsupervised this same diff would be
  refused, and that is correct.
- #249 is NOT closed by this pull request. Its remaining half is the
  scheduler, which is the human's. One comment on the issue records what
  landed so the next reader does not re-derive it.

## Rejected

- Building the recurring checker as a session that arms its own next pass.
  That is precisely the shape that froze for 82h40m in the run this issue
  came from, and the issue says so in its own words.

## Review

- r3: (verifier) the triple's third leg was unevaluable across passes: `connection_status` is nowhere in step 4's ledger grammar, and step 4's own rule says a field the ledger does not carry is a row unreachable after a compaction. PR234 r3 on this file, verbatim — dead text keyed on a ledger entry nothing writes. (fixed — `conn=` joins `seen=` in the grammar, and the signature says why)
- r4: (verifier) "turns the pair into a verdict one pass sooner" licensed killing a live session on ONE pass. The input that breaks it: a manager six minutes into a long turn, read twice 60s apart, shows frozen `updated_at`, static head and `disconnected`. Triple complete, work destroyed, cap paid twice — the exact defect the optional-tools row already names. (fixed — the clause is gone and the paragraph now says the two reads are two PASSES, like every other verdict here)
- r5: (verifier) the LOOP precondition decided liveness on `updated_at` alone, against this file's "two signals decide, never one" and against this plan's own acceptance; and it named no action for the not-alive branch, so a looping manager read between turns escaped with no row matching. (fixed — the pair, `updated_at` AND head, plus the fall-through named: drop to the rows below, where a dead manager gets a successor. The churn clause's no-prior-reading case writes `seen=` and decides next pass)
- r6: (verifier) the duplicate rule's own remedy could never reach a verdict in the case it is written for: it sent the reader to the signature, which requires a static HEAD, and the branch head moves continuously because the successor is pushing. Report forever, no terminating condition. (fixed — the duplicate test reads each session's own `updated_at` and `connection_status`, and the rule says not to reach for the head)
- r7: (verifier) the writer-not-worker rule prescribed resolving the worker from a field this same file disqualifies four lines later. A live successor carrying its branch only under `session_context.outcomes` would be invisible, no duplicate reported, and the dead predecessor then respawned onto a branch already being driven — the rule manufacturing the duplicate it exists to catch. (fixed — both fields named, and why reading one alone fails)
- r8: (verifier) the group-by-branch check had no "not you" exclusion, so a KILL or LOOP checkout makes the orchestrator report itself; and it had no way to report once, so a state the file itself prescribes gets flagged every pass forever. (fixed — yours excluded, ledger `dup=<branch>`, report once)
- r9: (verifier) the duplicate rule imported "nothing to stop" from the FAILED row, whose session is crashed. The IDLE row's whole doctrine is the opposite — between turns, and demonstrably able to wake. A literal reader carries the wrong reason onto the wrong path. (fixed — the reason now says between turns rather than crashed)
- r10: (verifier) the worked example told the reader that head movement read from git can be an artefact of push age. False, and it undercuts the STALL rows and the LOOP clause that both key on head movement: three of the four readings were real pushes. (fixed — says so, and confines the ageing to the one reading after the head stopped)
- r11: (verifier) "before two of those readings" is false. The source's own table timestamps four readings and one death; only the last follows it. Copied from the issue, which states two. The diff had also dropped the four timestamps, so the file carried a number nobody could check. (fixed — one reading, and all four timestamps restored)
- r12: (verifier) the mirror in `.agents/docs/orchestrated.md` still read `any` in its `looping` row's control-plane column, which is the rule this branch exists to overturn, while its own text asserts the two files carry the same rows. (fixed — the mirror's row carries the pair and points at the worked reading)
- r13: (verifier) nine new measurements carried a date and no owner, in a file whose neighbours all name their call and minute, and whose data no checkout can recount. (fixed — each cites issue #249)
- r14: (verifier) the plan's Acceptance was green whether the rules worked or not, and two of its five bullets were already unmet. (fixed — every bullet now names what to read, and the two unmet ones are the defects r3 and r5 record)
- r15: (verifier) caveman filler in new text, "actually" and "just", and the heading broke the parallel its three siblings keep. (fixed — "LOOP, and dead")
- r16: (verifier, process) the `## Review` section was empty in the commit it read: r1 and r2 were written after their fixes and were still uncommitted. Loop step 5 wants findings before the fix and in the same commit. (recorded; this round writes the findings and their fixes together)
- r17: (session) two acceptance bullets written this round were themselves written numbers: a whole-file `grep -c` for the two ledger fields reads 1 and 2 rather than the 1 each the bullet asserted, because each string also appears in the rule that writes it, and an `any` count over the mirror answers a different question than the one row that matters. Found by running my own acceptance instead of asserting it. (fixed — both bullets name the line to read)
- r1: (session) the signature paragraph claimed "no healthy one did", a universal from two observed live sessions, in a file whose own doctrine says one counter-example disqualifies a field and n=1 is not enough to build a rule on (`PR234 r12`). (fixed — it now states the five readings it rests on, three confirmations and two counter-checks, and draws the corroboration-not-decision conclusion from that rather than from a sweep nobody ran)
- r2: (session) the LOOP precondition said "two control-plane reads with `updated_at` moving between them", leaving a literal reader to think both must happen inside one pass — which would stall the pass. The ledger already carries the previous reading; that IS the first read. (fixed — the row names the ledger's reading and this pass's, and says no extra read is needed)

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` section 2 — the field table, the
  disqualified-fields paragraph, and the row table, in that order.
