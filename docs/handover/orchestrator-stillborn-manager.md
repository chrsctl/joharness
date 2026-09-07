---
workstream: orchestrator-stillborn-manager
status: in-progress
branch: claude/check-manager-crm-ui-automation-br4cn4
pr: none
plan: orchestrator-stillborn-manager
issue: none
session: https://claude.ai/code/session_019pSQgotmS3gsHwKxhTmey4
agent: sonnet
updated: 2026-09-07
next: Edit .claude/commands/orchestrate.md and .agents/docs/orchestrated.md per the plan, run ci, review, retire both files.
---

## Goal

The human asked, after a health check on one manager found it dead on
arrival: can we fix it in the harness. The state the check found — a
spawned manager that never ran a turn — has no row in the health table and
no path in the health pass that reaches it. Give it both.

## Decisions

- The branch name is the session's, not the workstream's: this session was
  started as `Check manager: crm-ui-automation-rehearsal` and its branch
  was set for it. The workstream file is named for the work.
- Discriminator is `last_served_model` + `sources`, both absent, confirmed
  across the ledger's previous pass and this one. Not `used_tokens` — the
  plan carries the counter-example that refuses it.

## Rejected

- Keying the row on `context_usage.used_tokens == 0`. A live, working
  session read 0 in the same `list_sessions` page, minutes apart from the
  dead one (plan, decision 2). It is the obvious field and it is wrong.
- Keying on `external_metadata.current_branches` being absent. It is
  absent on healthy sessions too — this very session has branches in
  `session_context.outcomes` and no `current_branches` at 10:28Z.
- Nudging the stillborn manager from this session. Its orchestrator was
  `RUNNING` and mid-pass at 10:24:20Z with the item on its ledger; a
  second driver is the duplicate-manager cost Runs already prices.
- Editing the gx copy. Harness fixes land canonical first.

## Review

Depth sonnet — `/code-review` (high) equivalent read plus
`.claude/agents/verifier.md`, which returned 20 findings on `f82dbc7` and
the worktree beside it. Numbering is the verifier's.

- r1: (verifier) the step 3 guard wedges an item forever. A manager that
  runs one turn, hits `./joharness.sh authority` with a verdict that is not
  VERIFIABLE — the first line of its own prompt — and exits without
  claiming has `last_served_model`, so it is not stillborn; it is IDLE, so
  it is not gone; it has no branch, so no row matched. Skipped at step 3 on
  every later pass, never reported, dispatch never reaching DRAINED. Step
  2's prose asserted the closed set that misses it. (fixed: three members,
  not two, and a report-only row for the third — a respawn only repeats the
  refusal.)
- r2: (verifier) the respawn limit was unenforceable for the case the row
  invents. The row said "at the limit REPORT and stop"; step 3's exception
  spawned a STILLBORN or gone item unconditionally, with no reference to
  the limit, and the normal enforcement is a `status: blocked` write on a
  branch that does not exist. Unbounded respawn, once a pass, in the
  human's money. (fixed: step 3 spawns a ledger-named item ONLY when this
  pass's health pass said to, so step 2 is the single authority and the
  limit is counted where the decision is made.)
- r3: (verifier) at `f82dbc7` two of the four mechanisms were dead text —
  they keyed on a ledger entry nothing wrote. `PR226 r3` verbatim, same
  file. (fixed in `7f3b760`, which was pushed before this report arrived:
  step 0.4, step 3 and step 4 now define and write `<stem>@new`.)
- r4: (verifier) the row archived on ONE reading, and the sentence claiming
  otherwise was false — a ledger write made when `create_session` returned
  is not an observation of the session record, and every other row here
  compares two reads. The false positive it admits is a PENDING session
  still attaching. (fixed: a first-look row records `seen=` and does
  nothing; the verdict needs a second read with `updated_at` unchanged,
  exactly as the crash rows.)
- r5: (verifier) the field rows licensed acting on one field — "whatever
  else the record says", "the one field that separates" — against the
  file's own "two signals decide, never one", for a low-tier literal
  reader. (fixed: both rows state what the field is and nothing more, and
  a line says the pair is read together or not at all.)
- r6: (verifier) the worked reading claimed `post_turn_summary` PUTS
  `status_bucket` there, which reverses the authority split run 1 paid for
  and would put the crash rows on a signal the file forbids. Nothing
  measured supports a causal claim. (fixed: correlation only — a healthy
  manager read the same bucket beside its own summary, this record read it
  with none, so the value does not discriminate and is in no row.)
- r7: (verifier) `archive_session` absent was undefined for this path, and
  the KILL carve-out's remedy needs a branch. Failure mode is the duplicate
  manager, unresolvable by claim-by-push because neither has claimed.
  (fixed: the optional-tools row reverses for an unclaimed session —
  report it and spawn nothing.)
- r8: (verifier) the crash rows sit above and swallow a never-born session
  whose bucket reads FAILED. (fixed as a statement rather than a reorder:
  that path is correct — the crash rows confirm across two reads the same
  way and RESPAWN now spawns fresh for a `new` entry — and the file says
  so, so a reader is not left to wonder why the row order does not match
  the advertisement.)
- r9: (verifier) "eleven of twelve" was a written number, and the sole
  evidence that the discriminator has no false positives. (fixed in
  `7f3b760` by counting, and again here: the call, its limit and its minute
  are on the sentence, plus the statement that no checkout can recount
  control-plane data.)
- r10: (verifier) "at least 15 minutes" contradicted the file's own
  timestamps — 10:13:29.630Z to the last observation at 10:28Z is 14m30s.
  (fixed.)
- r11: (verifier) "byte-identical" overclaimed three reads that established
  one field, and `10:23:4xZ` is a timestamp with a placeholder digit.
  (fixed: `updated_at` unchanged, and the two reads that carry real
  minutes.)
- r12: (verifier) a plural rule about `current_branches` from n=1. (fixed:
  restated as the single counter-example it is, with the note that one is
  enough to disqualify a field and not enough to build a rule on.)
- r13: (verifier) `orchestrated.md` still said the command file carries
  "both worked readings"; there are three. (fixed.)
- r14: (verifier) the heading swapped a stale count for a phrase that is
  also wrong — ten word rows, two signal columns, "one word each" reading
  as two. (fixed: "two signals, one verdict", which is a description and
  not a count.)
- r15: (verifier) the doc row dropped the bound its neighbours carry, so
  the human-facing file said a stillborn is respawned without limit.
  (fixed: the row carries the two passes, the limit and the report.)
- r16: (verifier) the plan had none of the shape `.agents/docs/plans/README.md`
  names, and its acceptance was `ci`, which reads no health-table text and
  is green whether a row is right, wrong or unreachable — the `PR226 r9`
  gap in the change that cites `PR226 r9`. (fixed: Scope, Out of scope,
  Acceptance, Where to look and Traps, and the acceptance is the
  discrimination read — worked examples deleted, six records walked down
  the table, each naming the row it must land on.)
- r17: (verifier) the ledger grammar left `next=` and `same=` undefined for
  a `@new` entry, both non-optional in the line's own brackets. (fixed:
  `next=new same=0` until it claims.)
- r18: (verifier) fixes sat in the tree with an empty `## Review`. (fixed:
  this section, and it is committed with them.)
- r19: (verifier) the third worked reading abbreviated `IDLE` and
  `REVIEW_READY` where its two neighbours quote `SESSION_STATUS_*`
  literals, so a reader matching strings matches two of three. (fixed.)
- r20: (verifier) this file said the gx orchestrator had the item "on its
  ledger", which reads as contradicting the plan's diagnosis that the
  ledger was the missing half. Both are true and the prose was sloppy: the
  live orchestrator's own wake message did carry
  `crm-ui-automation-rehearsal@new next=just spawned wave1`, written on its
  own initiative — nothing in the file prescribed that entry, and nothing
  told the health pass to walk ledger-only stems. What was missing is the
  instruction, not the data. (fixed: said that way here and in the plan.)
- r21: (verifier, wontfix) `orchestrated.md`'s prior-art comparison still
  lists six health words. It is a comparison against another system's five,
  not an enumeration of the table, and it was already partial before this
  diff. Widening it would break the pairing it exists to make.

Discrimination read, run rather than described (plan § Acceptance step 2):
the three worked readings deleted into a scratch copy, six records walked
down the table from the top. They land on six DISTINCT rows — first-look,
stillborn, ran-and-stopped, the existing idle nudge, `working. Nothing.`
and CRASHED — each the row the plan names. The `used_tokens: 0` record
lands on `working. Nothing.`, which is the arm that fails if the rows are
ever keyed on that field.

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` § 2 — "every manager in flight" is
  dispatch's git view, which is what makes an unclaimed manager invisible.
- `.claude/commands/orchestrate.md` § 3 — spawns off dispatch's list with
  no reference to the ledger.
