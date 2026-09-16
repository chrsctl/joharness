---
workstream: stale-session-check
status: review
branch: claude/drain-8jr601
pr: none
plan: stale-session-check
issue: 249
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: opus
updated: 2026-09-16
next: Retire this file and open the pull request; the withdrawn rules wait on the research question
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

- The classifier's refusal is BROADER than the issue records, and this
  session hit it doing cleanup rather than orchestration. Issue #249 reports
  `archive_session` denied every attempt, reason `Interfere With Workloads`.
  This session was denied a plain `kill` on an orphaned `ci` run it had
  started itself, in this repo, same reason. So the refusal is not specific
  to the control-plane tool or to another session's workload — which matters
  for the question the issue raises separately, whether the respawn path
  should attempt an archive first. A procedure that depends on stopping
  something may be refused wherever it runs, and needs a branch for that
  outcome rather than an assumption.

## Rejected

- Building the recurring checker as a session that arms its own next pass.
  That is precisely the shape that froze for 82h40m in the run this issue
  came from, and the issue says so in its own words.

## Review

**Round 3 ended the patching.** A second opus verifier pass found 13 verified
defects on a tree already fixed twice, four of them introduced by round 2's
own fixes. That is review churn as `.agents/docs/agent-selection.md` defines
it, and the conflicting requirement it tells you to find is below at r20. The
response was not a fourth round: four rules were WITHDRAWN and the question
they depend on was filed as `docs/research/liveness-in-a-long-turn.md`. What
merged is the two items that need no unmeasured fact. Findings r20 to r32 are
recorded against text this branch no longer carries, because the record of
why a rule was withdrawn is worth more than the rule was.

- r20: (verifier, ROOT CAUSE) the diff relied on two incompatible claims about one field. r4's own worked input says a live manager six minutes into a long turn shows a FROZEN `updated_at`; the LOOP precondition says a live manager's `updated_at` MOVES. Both cannot hold, and nothing in the repository settles which. Every withdrawn rule rests on it. (withdrawn — filed as a research question, `graduates:` the health pass)
- r21: (verifier) r4's fix was recorded as "the clause is gone" and the clause was still at `:192`. A false record is worse than the defect: the next reader trusts the `## Review` line and does not look. (fixed by the withdrawal, which removed the paragraph entirely; recorded here because the false record is the finding, not the clause)
- r22: (verifier) the LOOP row's "pair" was degenerate for the clause it guards: the head leg IS that clause's trigger, so it discriminates nothing, and the file's own worked reading shows the dead manager reading head MOVED at the pass that had to discriminate. (withdrawn)
- r23: (verifier) a RUNNING session failing the alive pair matched NO row: every row below is keyed on not-RUNNING or merged, so the instruction to "fall to the rows below" named nothing. (withdrawn)
- r24: (verifier) the duplicate rule implied a kill on one pass with no confirming read and no tie-break — the one place in the file the two-pass rule was not restated. (withdrawn)
- r25: (verifier) the duplicate was detected and the respawn that creates the next one was not gated: no row consumed the writer-not-worker answer, and the report-once suppression then hid every later duplicate on that branch. Worse than no rule. (withdrawn; the caution that survives decides nothing, so it cannot produce this)
- r26: (verifier) both withdrawn rules required an enumeration of sessions, which is `list_sessions`, which this file explicitly allows to be absent — with no OPTIONAL row added. "A procedure that calls a tool nobody has is the bug this file was just fixed for", 40 lines above. (withdrawn)
- r27: (verifier) "YOURS EXCLUDED" was unactionable where it mattered: the orchestrator recognises its own record by a title set with a tool the file marks optional. (withdrawn)
- r28: (verifier) the duplicate rule's death test was unrecordable across passes — the ledger is per stem with one `seen=` slot, and two sessions on one branch need two. (withdrawn)
- r29: (verifier) the mirror's rewritten row stated the test as "between the last two passes" with no equivalent of the command file's no-prior-reading case, so a churn hit on a first-seen stem read as not-alive and would spawn a successor onto a live manager. r12's fix introduced it. (withdrawn — the mirror is back to what main carries)
- r30: (verifier) `seen=` gained a second writer with different semantics, which would let a later crash skip the crash path's own first look. (withdrawn)
- r31: (verifier) r13 was incomplete: one citation at `:101` carried a date and no owner. (fixed — the surviving caution cites issue #249)
- r32: (verifier) acceptance bullet 3 was red on the tree that shipped it, and its string test could never match by construction — r17's species recurring in the round that recorded r17. Three of eight bullets red overall, which IS the improvement r14 wanted, and is also the evidence the rules were not ready. (fixed — the acceptance is rewritten for what survives, and every bullet names what to read)
- r33: (session) `conn=`'s reader, added as r18, changed no action: it said its own absence does not hold the verdict, so the field was a reader in form only. (withdrawn with the rule)

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
- r19: (session) the round-2 rewrite of the LOOP row left the round-1 wording standing beside it, so the cell carried the same instruction twice and the second copy began mid-sentence in lower case. Found reading the row whole rather than the diff hunk. (fixed)
- r18: (session) `conn=` had a writer and no reader: the grammar carried it and the LOOP row wrote it, but no row in the decision table consumed it — the same dead-text shape r3 records, one level over. (fixed — the FAILED-confirmed row reads it as corroboration, and says explicitly that its absence does not hold the verdict, so the pair still decides)
- r17: (session) two acceptance bullets written this round were themselves written numbers: a whole-file `grep -c` for the two ledger fields reads 1 and 2 rather than the 1 each the bullet asserted, because each string also appears in the rule that writes it, and an `any` count over the mirror answers a different question than the one row that matters. Found by running my own acceptance instead of asserting it. (fixed — both bullets name the line to read)
- r1: (session) the signature paragraph claimed "no healthy one did", a universal from two observed live sessions, in a file whose own doctrine says one counter-example disqualifies a field and n=1 is not enough to build a rule on (`PR234 r12`). (fixed — it now states the five readings it rests on, three confirmations and two counter-checks, and draws the corroboration-not-decision conclusion from that rather than from a sweep nobody ran)
- r2: (session) the LOOP precondition said "two control-plane reads with `updated_at` moving between them", leaving a literal reader to think both must happen inside one pass — which would stall the pass. The ledger already carries the previous reading; that IS the first read. (fixed — the row names the ledger's reading and this pass's, and says no extra read is needed)

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` section 2 — the field table, the
  disqualified-fields paragraph, and the row table, in that order.
