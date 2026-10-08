---
research: a-manager-blocked-before-its-first-push
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/orchestrated.md
---

<!--
A report from a consumer (`chrsctl/gx`), filed by the route
`.claude/commands/upstream-report.md` names. Canonical decides. The
consumer-side measurements could not be re-taken here, because they are
about a fleet's control-plane records; they are marked REPORTED below, and
every harness claim beside them was measured on this checkout.
-->

## Question

Does the orchestrator's health table carry any row that reaches a manager
blocked before its first push — and does the row that does match forbid the
one action that would recover it?

## Echo

The health table decides liveness from two readings, and nearly every row it
has takes a branch for granted: push age comes from `dispatch`, and
`dispatch` reads git. A manager that blocks seconds after it starts has
pushed nothing, so there is no ref, no row, and no push age for any clock to
run against. What I am asking is which row such a session falls to.

The table does have rows for a session that never claimed — it reasoned about
exactly this shape once, for a session that never ran at all. So the question
is not whether the author considered the no-branch case. It is whether the
discriminator chosen for it (did a turn ever run) separates the two
no-branch outcomes that matter: never started, versus started and stopped
somewhere no instruction can reach.

Not asking whether a manager should avoid asking questions. #304 asks that
and answers it. A permission prompt is a different event: the session did not
choose to ask and cannot choose a push instead, because the block is inside
the tool call and the session has no turn in which to act.

## Sweep

`goal-directed` — enough to establish which row a blocked-before-push
manager matches and what that row instructs. Not a survey of the liveness
signals (#283 measured five of them), and not a proposal for a new knob.

## What would settle it

- **A row keyed on the block.** If `status_bucket` BLOCKED or a
  `REQUIRES_ACTION` status appears anywhere in the table, the signal is read
  and this closes as a wording or threshold question. Settled by enumerating
  the status vocabulary the file actually names.
- **Which row matches instead, and what it says to do.** If it says report
  and never respawn, the defect is a verdict, not a blind spot — worse,
  because the table is confident. If no row matches at all, the defect is the
  blind spot. Settled by reading the rows down in their stated order against
  both readings the record could carry.
- **Whether #304's fix reaches it.** #304's cheapest fix is an instruction:
  asking is a push, not a wait. If a permission prompt can be converted into
  a push by any instruction, this is #304 and should be appended there rather
  than filed. Settled by what the session can do between the prompt firing
  and the answer arriving.

## Method

Run on this checkout at `832f5fdd`:

    grep -on "SESSION_STATUS_BUCKET_[A-Z_]*" .claude/commands/orchestrate.md | sort -u
    grep -n "BLOCKED" .claude/commands/orchestrate.md
    grep -n "permission_mode\|dontAsk\|bypassPermissions" .claude/commands/orchestrate.md \
      .agents/docs/orchestrated.md .claude/commands/manage.md
    sed -n '149p;173,176p;183,189p' .claude/commands/orchestrate.md
    sed -n '5230,5232p' joharness.sh
    grep -rn -i "permission" .claude/commands/manage.md

## Findings

- **The table names two status buckets and neither is the block.**
  `grep -on "SESSION_STATUS_BUCKET_[A-Z_]*" .claude/commands/orchestrate.md`
  returns exactly two hits, `SESSION_STATUS_BUCKET_FAILED` at `:210` and
  `SESSION_STATUS_BUCKET_REVIEW_READY` at `:262`. `grep -n "BLOCKED"` on the
  same file returns one hit, `:450`, which is a workstream file's
  `status: blocked` and not the control plane's bucket. The field's own row
  (`:149`) closes the vocabulary deliberately: `..._FAILED` is *"The ONLY
  failure signal that may decide liveness"*. A BLOCKED bucket is therefore
  not a signal the table may act on, by its own rule.

- **The stall clock cannot start, because the clock is a branch.** Push age
  is `dispatch`'s column, and `dispatch`'s branch view is
  `git for-each-ref --no-merged="refs/remotes/origin/${base_branch}"`
  (`joharness.sh:5230`). A session that pushed nothing has no ref, so it has
  no row: not in flight, not stalled, not a leftover. Every RUNNING row in
  the table (`:173-176`) keys on push age, so if the record reads RUNNING
  there is no row that matches at all — the first row's *"under stall"* is
  a comparison against a number that does not exist.

- **If the record reads IDLE, a row DOES match, and it forbids the
  respawn.** Read down in the stated order, the no-branch rows are `:183-186`:

  - `:183` UNCLAIMED, FIRST look — ledger `seen=` and nothing else this pass.
  - `:184` STILLBORN requires *"NO `last_served_model` and NO `sources`"*.
    This session had both: it ran a turn and it had a checkout to read a
    commit hash out of. The row does not match.
  - `:185` matches: *"IDLE or PENDING, and the record carries
    `last_served_model`"*. Its verdict is *"It RAN and stopped without
    claiming"*, its stated cause is an authority exit — *"a verdict that is
    not VERIFIABLE ends the session there; a `NOT YOURS` exit reads the
    same"* — and its instruction is *"A respawn repeats it, so do not.
    REPORT ... and leave the entry in the ledger so no later pass spawns
    it."*

  So the matching row attributes the stop to a cause that is wrong here and,
  on that cause, forbids the one cheap recovery. A respawn does NOT repeat a
  permission prompt the way it repeats an authority exit: authority is a
  property of the repository and identical for every successor, while a
  prompt depends on what the next session's first commands happen to be. The
  row's reasoning is sound for the case it was written for and inverts the
  correct action for this one.

- **The harness already reasoned about the no-branch case, and the
  discriminator it chose excludes this.** `:184` carries the whole argument —
  *"nothing is lost, no handover is owed and there is no branch to name"*,
  down to the hand-off at the respawn limit: *"the hand-it-to-the-human write
  needs a branch and there is none, so the ledger entry and the report ARE
  the hand-off."* `:42` repeats it from the other side. So the gap is not an
  unconsidered shape; it is one test, `last_served_model` present or absent,
  standing in for *did this session get anywhere*, and a session that blocked
  on its first command is on the wrong side of it.

- **`permission_mode` is named nowhere in the harness.**
  `grep -n "permission_mode\|dontAsk\|bypassPermissions" .claude/commands/orchestrate.md .agents/docs/orchestrated.md .claude/commands/manage.md`
  returns nothing. The spawn step enumerates what `create_session` needs
  (`:28-33`) and never the permission posture, so a manager's exposure to
  prompts is whatever the runtime defaults to and no harness file states
  it, bounds it, or warns a reader that a prompt is unanswerable in a
  manager session. `grep -rn -i "permission" .claude/commands/manage.md`
  returns five hits, none about a permission prompt.

- **#304's cheapest fix cannot reach this, and that is the reason this is a
  separate question.** #304 proposes one clause: asking is a push, not a wait
  — `status: blocked`, `next:` = the question, push, exit. That works because
  `AskUserQuestion` is a call the session chose to make and could have
  replaced with a commit. A permission prompt is not a choice: it fires
  inside the tool call, the session is suspended mid-turn, and there is no
  turn in which to write a workstream file or push one. No instruction
  placed in `AGENTS.md` or `manage.md` can convert it, which is why the
  recovery has to be the orchestrator's.

- **REPORTED from `chrsctl/gx`, orchestrated run of 2026-10-08, not
  re-measured here.** `session_01RMM6KSeR8A7SKMBdd29bgZ`, manager for
  `crm-ui-hints-queue-and-palette`:

  | | |
  | --- | --- |
  | created | 04:21:54Z |
  | status at 04:22:50Z | `REQUIRES_ACTION`, "Waiting on permission: Bash" |
  | task | "Showing current commit hash" |
  | pushed | nothing |
  | released | 04:37Z, by the orchestrator interrupting it |

  56 seconds from creation to blocked, on a command that reads a commit
  hash, under `permission_mode` auto. No human is in a manager session to
  approve; the orchestrator has no message route to cloud sessions;
  `dispatch` could not see the session at all, its git view having no row;
  the only signal was `get_session`'s `status_bucket` BLOCKED. An earlier
  manager in the same run, `session_01W6PbJp6BZLLbC5WmvFYC5L`
  (`crm-contact-feed-scene`), sat about 12 hours on an `AskUserQuestion` the
  same way.

- **What it cost: a paid-for manager and a slot, for 15 minutes, and the
  recovery was outside the rules.** The orchestrator interrupted at 04:37Z,
  which no row above instructs — `:185` says report and do not respawn. The
  15 minutes are short only because `JOHARNESS_MAX_MANAGERS=1` made this the
  whole fleet and the orchestrator was looking straight at it. The second
  instance, on the same blind spot through a question instead of a prompt,
  ran about 12 hours.

## Consequence for the queue

**Two neighbours, and this is neither.** #304 is the instruction half, for a
question the session chooses — and its fix (2), moving the never-wait rule
into `manage.md`'s `## Never`, already covers the half of the proposed fix
that would have gone there, so nothing is owed to `manage.md` from this node
beyond one sentence #304 does not make: a permission prompt is not a
question, and no instruction avoids it. #283 and #298 are the stall-verdict
half, for managers that HAVE pushed; both measure signals against sessions
with branches, and #304 explicitly routes the "why did the kill never fire"
question to them. This node is the row that is missing for a session with no
branch at all, which none of the three reaches.

What changes, if the answer is yes:

- **A health row keyed on the block, read BEFORE `:185`.** A manager whose
  record carries a BLOCKED bucket or a `REQUIRES_ACTION` status with no claim
  pushed is dead on arrival: `interrupt_session`, `archive_session`, spawn
  the ITEM again — a plain spawn, as `:184` does, because nothing was claimed
  and no handover is owed. Counted against `JOHARNESS_RESPAWN_LIMIT` for the
  same reason `:184` counts: a spawn that reproduces the condition every time
  must not loop. This also owes a change to `:149`, which currently forbids
  acting on any bucket but FAILED — the rule that makes the new row illegal
  has to be amended in the same diff, or the two contradict.
- **At once, not after the stall window.** The 45-minute default is
  `JOHARNESS_STALL_MINUTES`, and the finding above is that it never applies
  here: with no branch there is no push age, so this is not a threshold to
  lower but a row to add. Said plainly because "treat it as dead after 45
  minutes" is the natural shape to reach for and it would change nothing.

What the answer owes before any of it is written: whether a blocked session's
record reads RUNNING or IDLE. The two readings match different rows — none,
and `:185` — and the fix differs. The reported instance gives a
`status_bucket` and a status string but not `session_status`, so this is the
one thing a session taking this node has to establish first, and it cannot be
established in this repository (#267).

## Verification

**Pass IN FLIGHT at this commit.** The verdicts below are the reporting
session's own reading and are not yet a second context's. The next commit on
this branch carries the pass's result and corrects any verdict it refutes.

Second context: `.claude/agents/verifier.md` at opus, which re-derived the
status vocabulary, the row ordering and the `for-each-ref` claim from the
source rather than reading the quotations above, and was told which claims
are consumer-side.

- **The table names only FAILED and REVIEW_READY, and `:149` forbids acting
  on any other bucket** — GROUNDED. Enumerated, not sampled.
- **No row matches a RUNNING session with no branch** — GROUNDED. Every
  RUNNING row keys on push age; push age comes from a ref.
- **`:185` matches the IDLE reading and forbids the respawn, on a cause that
  is wrong here** — GROUNDED for what the row says. That a respawn would
  actually succeed is an inference from how a prompt differs from an
  authority exit, not a measurement, and is marked so above.
- **`:184`'s discriminator excludes a session that ran one command** —
  GROUNDED.
- **`permission_mode` is named nowhere** — GROUNDED, three files searched.
- **#304's instruction fix cannot reach a permission prompt** — GROUNDED on
  #304's text and on what a suspended tool call leaves a session able to do.
- **The `gx` timeline, the session identifiers, the `status_bucket` reading
  and the 12-hour second instance** — UNVERIFIABLE HERE, and reported as
  such. The verifier cannot read a control plane (#267), which is the
  standing limit on every question of this shape. The harness-side findings
  do not rest on them: the missing row is missing whether or not this
  instance happened as reported.

## Graduates to

`.agents/docs/orchestrated.md` — the file that carries the health table's
why-explanation, including the `stillborn` row and the knob table the
liveness rules lean on. The answer belongs beside that row rather than in a
rule line alone, because the reasoning is the valuable part: `:184` chose
*did a turn run* as the test for a no-branch session, and the next reader has
to see why that test splits the wrong way before adding a second one.

Named, not written: the row itself lands in `.claude/commands/orchestrate.md`
and amends `:149`, both protocol text (`./joharness.sh protocol-paths`). A
plan touching it is supervised only, and this node does not propose it.
