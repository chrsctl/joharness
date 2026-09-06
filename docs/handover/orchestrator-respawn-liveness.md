---
workstream: orchestrator-respawn-liveness
status: in-progress
branch: claude/drain-7uzyzi
pr: none
plan: orchestrator-respawn-liveness
issue: none
session: https://claude.ai/code/session_01V7Y1v6ee4aFAmDrY7W8SZZ
agent: opus
updated: 2026-09-06
next: Retire this file and the plan as the last commit before the pull request
---

## Goal

The health table's respawn row reads `not RUNNING` as *session gone* and
spends a manager on ONE observation. The control plane's IDLE means BETWEEN
TURNS, so `not RUNNING` selects working sessions — and every manager in run 1
that armed its own check-in read IDLE for the whole interval. The kill row
beside it demands two signals, a nudge and a confirming pass; a session
between turns was therefore cheaper to replace than one that had genuinely
stopped. Consumer `chrsctl/gx`, 2026-09-06: one duplicate manager, ~17 USD,
against a session that woke at 17:41Z and merged its own pull request.

A third state rides along: a CRASHED session also reads `not RUNNING`, and
fixing the IDLE row alone makes a crash strictly worse — a dead session would
then be sent a nudge nothing is listening to.

## Decisions

- Written for the literal reader, because that is the failure mode: the
  orchestrator of run 1 had refused this exact inference at 13:22Z by
  reasoning past the text, and followed it at 17:13Z. A rule that needs the
  reader to override it is the defect, so the fix is prose that gives the
  same answer to a reader who does not think.
- The rows that DECIDE liveness are keyed on fields now. `not RUNNING` still
  appears on the `blocked` row, where it is safe — that row never respawns —
  but no row that spends a manager turns on it any more. The phrase is what
  let one field decide liveness; the plan's point is that the control plane
  has at least five states across three fields.
- The rows I added last item (`PR in flight, no claim file`) carried the same
  `not RUNNING` defect and are fixed in the same pass. Half-applying the fix
  inside one table is how the next reader picks the wrong half.
- The "no `interrupt_session`" degradation rule is scoped to a session that
  may still be RUNNING. Read unscoped, it forbids respawning a CONFIRMED DEAD
  session — the rule against two sessions on one branch, applied where there
  is only one.

## The discrimination check (the plan's Acceptance, run)

Fresh low-tier sessions, each given ONE text and ONE observation, no
repository and no plan. Readings after the first are disguised (different
stem, sha, timestamps). 2026-09-06. Rebuild the texts with:

```bash
A='/^## 2\. Health pass/,/^Both sequences below/'
awk "$A" .claude/commands/orchestrate.md > /tmp/t-new.md          # amended
git show origin/main:.claude/commands/orchestrate.md | awk "$A" > /tmp/t-old.md
sed '/Two readings from run 1/,$d' /tmp/t-new.md > /tmp/t-rows.md  # rows, no examples
```

Round 1, with the worked examples still in the text:

| text | observation | answered |
| --- | --- | --- |
| `origin/main`'s | IDLE, `completed`, pull request open, head not an ancestor | **RESPAWN** — quoting the `not RUNNING … session gone` row verbatim. The defect, reproduced on demand. |
| amended | same shape, disguised, bucket OK | **NUDGE**, quoting the IDLE row |
| amended | crash shape, disguised, bucket FAILED | **no nudge**; ledger it, archive-then-respawn next pass |
| IDLE fix only, FAILED rows removed | that same crash shape | **NUDGE** — the wrong answer, a nudge sent to something that cannot answer |

Round 2, after the verifier showed round 1 could not discriminate the ROWS —
the worked examples restate their own answers, so a reader can produce them
without reading a row (r9). Same rows, examples DELETED from the text, and
two readings that reach the rows only the ledger can key:

| text | observation | answered |
| --- | --- | --- |
| rows only | crash, first pass, no `seen=` in the ledger | **NOTHING**, no nudge, ledger `seen=`; archive-then-respawn next pass if frozen |
| rows only | same crash, second pass, `seen=` recorded and `updated_at` + head unchanged | **ARCHIVE-THEN-RESPAWN**, quoting the confirmed-dead row |
| rows only | a `?` edge row, 308h old, no session found by title | **REPORT-TO-HUMAN**, never respawn |

Round 2's first line is the one that matters: before the row reorder the rows
alone answered NUDGE there, which is the outcome the plan calls strictly
worse. Round 1 could not see it.

## Rejected

- **Removing IDLE from the table's vocabulary and leaving the respawn row
  otherwise intact** — the plan's own first Trap. The missing nudge is half
  the defect: any single-observation respawn spends a manager on a guess.
- **Keying the crash row on `post_turn_summary.status_category: failed`.**
  It is the session's own account of its turn, and it is the same field that
  said `completed` over an unmerged head at 17:13Z. `status_bucket` is the
  control plane's, and only that may decide liveness.

## Review

Twelve findings from one `verifier` pass at opus, on prose, which is what the
plan asks for: the failure mode is a literal reader, so the check is a second
reader who did not write it.

- r1: (verifier, correctness) THE round's worst. The crash reading matched the
  IDLE row before the FAILED row, and the FAILED row said `whatever
  session_status says` without stating precedence — so a top-to-bottom reader
  nudges a dead session, which is the outcome the plan itself calls strictly
  worse. Same shape one column over: RUNNING with a FAILED bucket reached
  `Nothing` or the stall nudge first. (fixed: the crash rows sit ABOVE the
  idle rows with the reason on the line, a sentence over the table says read
  in order and act on the first match, and the FAILED rows are scoped to a
  session that is not RUNNING — a RUNNING session has moved past that turn.
  Round 2 of the check pins it on rows-only text.)
- r2: (verifier, correctness) I dropped the `status in-progress / review /
  done` qualifier from the gone row, so "no session found by title" matched a
  `?` edge row and RESPAWNED it — restoring PR225 r6 by hand, one item after
  fixing it, and live on this repo against `claude/upkeep-off-session`.
  (fixed: the qualifier is back and widened to name the edge case, and the
  `?` row now reads `any status whatsoever` with NEVER respawn on it.)
- r3: (verifier, correctness) the guarantee rested on "not in the ledger",
  and step 0.4 defines the ledger as carrying every item in flight — so that
  condition never matches, and an IDLE manager whose head had not moved fell
  to the RESPAWN row on the FIRST observation. (fixed: the rows key on
  whether a nudge or a `seen=` is recorded for that stem, not on presence.)
- r4: (verifier, correctness) the rows branched on `updated_at` and the
  ledger message had no field for it, so after a compaction the confirmed-dead
  row was unreachable and the session fell back to the idle rows. (fixed:
  `seen=<updated_at> detail=<40 chars>` added to the ledger line in step 4,
  with the stripping rule that already covers `next` and `status_detail`, and
  step 0.4 says the ledger carries them.)
- r5: (verifier, correctness) a crash confirmed on pass 2 matched the idle
  RESPAWN row before the archive-then-respawn row, so the dead session was
  left in place and a successor spawned beside it. (fixed by the same
  reorder; round 2's second reading asserts the archive comes first.)
- r6: (verifier, docs) the definition said "never PENDING" while a row called
  a PENDING session gone, and the edge rows said "gone by the definition
  above" with the definition BELOW them. (fixed: the definition moved above
  the table, and it now names the fourth gone state — did not move across a
  nudge and a confirming pass — which is what those rows actually do.)
- r7: (verifier, correctness) the `list_sessions`-only degraded path carries
  `session_status` alone, so the crash rows are unreachable there and every
  crash silently takes the nudge. No degradation row covered it, which is
  PR218 r2's recorded shape. (fixed: a row in the Tools table — take the IDLE
  path for both, never respawn on one observation to make up for the missing
  field, and say which managers were judged that way.)
- r8: (verifier, docs) three statements true in one copy and not the other,
  plus a THIRD copy in `joharness.sh`'s printed row. (fixed: `orchestrated.md`
  gains the qualifier, the never-alone half and the row order; the printed row
  names the definition instead of restating it. The plan's `scope:` does not
  list `joharness.sh` — this is one clause, and leaving a third unqualified
  copy is the rot the plan's own Acceptance forbids.)
- r9: (verifier, evidence) the discrimination check did not discriminate the
  ROWS: the worked examples restate their own answers, so a reader could
  produce them without reading a row, and the intermediate text removed the
  rows, the field row and the example together. (fixed: round 2 above, on text
  with the examples deleted — and it caught r1's consequence, which round 1
  could not. The rebuild commands are recorded with the table.)
- r10: (verifier, style) `→` in prose, which `.agents/docs/caveman.md` bans,
  and 17 USD in four places. (fixed: no arrows; the cost is in Runs, which
  owns it, and once in the command file, which the plan's Traps require.)
- r11: (verifier, process) the fix commit landed while `## Review` still said
  "Pending", against step 5's before-the-fix-and-same-commit rule. (fixed:
  this section and the round-2 fixes are one commit. Worth keeping as the cost
  of that order — a review spawned against a working tree finishes after the
  commit it was reviewing.)
- r12: (verifier, evidence) two record claims the tree did not support: "keyed
  on FIELDS, not the phrase `not RUNNING`" while a row still used it, and a
  check whose intermediate text lived only in a session scratchpad with no
  command to rebuild it. (fixed: the claim is corrected below, and the rebuild
  commands are in the check section.)

## Blockers

None here. Consumer-side acceptance (this plan SHIPS) has a cheap version the
plan itself names, which runs on a session rather than a fleet; the full
version needs a consumer fleet this session cannot reach.

## Where to look

- `.claude/commands/orchestrate.md` — the health table and the KILL sequence
  under it (the nudge-then-confirm pattern to copy).
- `.agents/docs/orchestrated.md` — the second copy of the same table.
