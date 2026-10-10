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

DEVIATION: the route permits one file per pull request (`:81-84`, `:119`).
This report carries two nodes, because the run produced two unrelated
questions and a node settles ONE. Named in both files; canonical decides
which rule gives.
-->

## Question

Does the orchestrator's health table carry any row that correctly reaches a
manager blocked before its first push — or does a literal reader find a
confident wrong row instead?

## Echo

The health table decides liveness from two readings, and most of its rows
take a branch for granted: push age comes from `dispatch`, and `dispatch`
reads git. A manager that blocks seconds after it starts has pushed nothing,
so there is no ref, no row, and no push age for any clock to run against.
What I am asking is which row such a session falls to.

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
- **Which row matches instead, and what it says to do.** Read the rows in
  the order the file prescribes and take the first that matches, for each
  reading the record could carry. If the first match says report and never
  respawn, or says the work is done, the defect is a wrong verdict rather
  than a blind spot — worse, because the table is confident.
- **Whether #304's fix reaches it.** #304's cheapest fix is an instruction:
  asking is a push, not a wait. If a permission prompt can be converted into
  a push by any instruction, this is #304 and should be appended there rather
  than filed. Settled by what the session can do between the prompt firing
  and the answer arriving.

## Method

Run on this checkout at `832f5fdd`:

    grep -on "SESSION_STATUS_BUCKET_[A-Z_]*" .claude/commands/orchestrate.md | sort -u
    grep -n "BLOCKED" .claude/commands/orchestrate.md
    grep -ric "permission" .claude/commands/manage.md
    grep -rn "permission_mode\|dontAsk\|bypassPermissions" .claude/commands/ .agents/docs/
    sed -n '139p;149p;183,191p;503,506p' .claude/commands/orchestrate.md
    awk -F'|' 'NR>=171 && NR<=195 && $2 ~ /RUNNING/ {print NR": "$2"|"$3}' \
      .claude/commands/orchestrate.md
    sed -n '182,187p' .agents/harness/queue-context.sh
    sed -n '7113,7120p' joharness.sh

## Findings

- **The table names two status buckets and neither is the block.**
  `grep -on "SESSION_STATUS_BUCKET_[A-Z_]*" .claude/commands/orchestrate.md`
  returns exactly two hits, `SESSION_STATUS_BUCKET_FAILED` at `:210` and
  `SESSION_STATUS_BUCKET_REVIEW_READY` at `:262`. `REQUIRES_ACTION` appears
  nowhere in the repository. `grep -n "BLOCKED"` on the same file returns one
  hit, `:450`, which is a `dispatch` row derived from a workstream file's
  `status: blocked` (the row text is `joharness.sh:8353`) and not the control
  plane's bucket. The field's own row (`:149`) closes the vocabulary
  deliberately: `..._FAILED` is *"The ONLY failure signal that may decide
  liveness, and only while `session_status` is not `RUNNING`"*. A BLOCKED
  bucket is therefore not a signal the table may act on, by its own rule.

- **The stall clock cannot start, because the clock is a branch.** The queue
  hook builds claims only from remote refs that fail `ref_merged`
  (`.agents/harness/queue-context.sh:182-186`), and push age is
  `dispatch_age_min` (`joharness.sh:7116`), whose own comment states the
  substance: *"Minutes since the last commit on a remote branch; empty when
  the ref is not here (never fetched, or already deleted), and empty is said
  as unknown by the caller — never as zero"* (`:7113-7115`). A session that
  pushed nothing has no ref, so it has no row: not in flight, not stalled,
  not a leftover, and no number for any threshold to compare.

- **A literal reader finds a confident WRONG row, and it is not the one I
  expected.** `:139` instructs *"Read the rows IN ORDER and act on the FIRST
  that matches"*. For a never-pushed session, `:190` reads
  `any | any | branch merged (dispatch no longer lists it)` — and its
  parenthetical test, *dispatch no longer lists it*, is literally TRUE of a
  session that was never listed. Its verdict is **"done. Nothing."** So the
  failure is not a blind spot. A literal reader — the standard this harness
  writes for — is handed a row saying the work is finished, on a manager that
  never started, before reaching any row about a session that failed to
  claim. Either `:190` has to be narrowed to a branch that once existed, or
  it is the match and the table says the opposite of the truth.

- **If the reader gets past `:190`, the row that matches forbids the
  respawn.** The no-branch rows are `:183-185`:

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
  prompt depends on what the next session's first commands happen to be.
  The row's reasoning is sound for the case it was written for and inverts
  the correct action for this one. That a respawn would in fact clear the
  prompt is an inference, not a measurement — it cannot be measured from
  this repository.

- **The harness already reasoned about the no-branch case, and the
  discriminator it chose excludes this.** `:184` carries the whole argument —
  *"nothing is lost, no handover is owed and there is no branch to name"*,
  down to the hand-off at the respawn limit: *"the hand-it-to-the-human write
  needs a branch and there is none, so the ledger entry and the report ARE
  the hand-off."* `:42` repeats it from the other side. So the gap is not an
  unconsidered shape; it is one test, `last_served_model` present or absent,
  standing in for *did this session get anywhere*, and a session that blocked
  on its first command is on the wrong side of it.

- **`permission_mode` is named nowhere, and `manage.md` never says the word
  `permission`.** `grep -rn "permission_mode\|dontAsk\|bypassPermissions"`
  over `.claude/commands/` and `.agents/docs/` returns nothing outside this
  node's own text. The spawn step enumerates what the `create_session` call
  takes — *"`source_url` ...; `model` ...; `title` = `manager: <stem>`;
  `prompt` = this block"* (`:503-506`) — and never a permission posture. And
  `grep -ric "permission" .claude/commands/manage.md` returns **0**: in 222
  lines, the file a manager reads as its own rules never mentions permission
  at all. So a manager's exposure to prompts is whatever the runtime defaults
  to, no harness file states it or bounds it, and nothing warns a reader that
  a prompt is unanswerable in a manager session.

- **#304's cheapest fix cannot reach this, and that is why this is a
  separate question.** #304 proposes one clause: asking is a push, not a wait
  — `status: blocked`, `next:` = the question, push, exit. That works because
  `AskUserQuestion` is a call the session chose to make and could have
  replaced with a commit. A permission prompt is not a choice: it fires
  inside the tool call, the session is suspended mid-turn, and there is no
  turn in which to write a workstream file or push one. No instruction placed
  in `AGENTS.md` or `manage.md` can convert it, which is why the recovery has
  to be the orchestrator's.

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
  the only signal was `get_session`'s `status_bucket` BLOCKED.

- **What it cost, also REPORTED: a paid-for manager and a slot for 15
  minutes, and the recovery was outside the rules.** The orchestrator
  interrupted at 04:37Z, which no row above instructs — `:185` says report
  and do not respawn, and `:190` says nothing is wrong. The 15 minutes are
  short only because `JOHARNESS_MAX_MANAGERS=1` made this the whole fleet
  and the orchestrator was looking straight at it.

- **A second `gx` session is NOT counted here, and the reason matters.**
  `session_01W6PbJp6BZLLbC5WmvFYC5L` (`crm-contact-feed-scene`) sat about 12
  hours on an `AskUserQuestion` in the same run. The first draft of this node
  counted it as a second instance of this shape. It is not shown to have
  been branchless, and #304's own evidence is that an `AskUserQuestion` block
  DOES produce a `dispatch` row — its instance printed
  `STALL? no push for 9h` on a row the whole time, which requires a ref. So
  that session probably belongs to #304, #283 and #298, and this node stands
  on ONE instance. Said plainly because the instance count is the whole
  weight of a report, and inflating it to two would be the written number
  this route exists to refuse.

## Consequence for the queue

**Two neighbours, and this is neither.** #304 is the instruction half, for a
question the session chooses — and its fix (2), moving the never-wait rule
into `manage.md`'s `## Never`, already covers the half of the proposed fix
that would have gone there, so nothing is owed to `manage.md` from this node
beyond one sentence #304 does not make: a permission prompt is not a
question, and no instruction avoids it. #283 and #298 are the stall-verdict
half, for managers that HAVE pushed; both measure signals against sessions
with branches, and #304 explicitly routes the "why did the kill never fire"
question to them. This node is the row that is missing — and the row that is
wrong — for a session with no branch at all, which none of the three reaches.

What changes, if the answer is yes:

- **Narrow `:190` first, because it is a wrong verdict and not a gap.**
  *"branch merged (dispatch no longer lists it)"* has to require that a
  branch once existed, or the row claims a never-started manager is done.
  This is the cheapest of the three and the only one that prevents a
  confident wrong reading rather than adding a reading.
- **A health row keyed on the block, read BEFORE `:185`.** A manager whose
  record carries a BLOCKED bucket or a `REQUIRES_ACTION` status with no claim
  pushed is dead on arrival: `interrupt_session`, `archive_session`, spawn
  the ITEM again — a plain spawn, as `:184` does, because nothing was claimed
  and no handover is owed. Counted against `JOHARNESS_RESPAWN_LIMIT` for the
  same reason `:184` counts: a spawn that reproduces the condition every time
  must not loop. This also owes an amendment to `:149`, which bars any bucket
  but FAILED from deciding liveness — the rule that makes the new row illegal
  has to change in the same diff, or the two contradict.
- **At once, not after the stall window.** The 45-minute default is
  `JOHARNESS_STALL_MINUTES`, and the finding above is that it never applies
  here: with no branch there is no push age, so this is not a threshold to
  lower but a row to add. Said plainly because "treat it as dead after 45
  minutes" is the natural shape to reach for and it would change nothing.

What the answer owes before any of it is written: whether a blocked session's
record reads RUNNING or IDLE. The two readings reach different rows — `:190`
either way, then `:185` on the IDLE path — and the fix differs. The reported
instance gives a `status_bucket` and a status string but not
`session_status`, so this is the one thing a session taking this node has to
establish first, and it cannot be established in this repository (#267).

## Verification

Second context: `.claude/agents/verifier.md` at opus, which re-derived the
status vocabulary, the row ordering and the branch-view claim from the source
rather than reading the quotations above, and was told which claims are
consumer-side. It refuted four claims in this file's first draft, one of them
by finding a stronger version of the finding; each is corrected above and
named here.

- **The table names only FAILED and REVIEW_READY, and `:149` bars any other
  bucket from deciding liveness** — GROUNDED. Enumerated, not sampled;
  `:450` confirmed to be a workstream status, not a bucket. The draft's
  restatement that `:149` *"forbids acting on any other bucket"* was wider
  than the text and is narrowed above.
- **`:190` is a confident wrong match for a never-pushed session** —
  GROUNDED, and found by the second context, not the first. The draft claimed
  a blind spot on the RUNNING reading; the verifier read the rows in the
  order `:139` prescribes and found `:190` matches first and says *"done.
  Nothing."* This replaced the draft's weaker claim.
- **Every RUNNING row keys on push age** — REFUTED. Five RUNNING rows exist,
  and `:191`'s push-age cell is `any`; the draft cited `:173-176` and
  silently excluded the counter-example. The conclusion survives — `:191`
  still needs a `dispatch` row — but the enumeration did not, and the claim
  is gone from the findings above.
- **Push age comes from a ref, so a never-pushed session has no number** —
  GROUNDED, but the draft's citation was wrong: `joharness.sh:5230` is
  `janitor_branches()`, not `dispatch`. Corrected to the queue hook's branch
  enumeration (`queue-context.sh:182-186`) and `dispatch_age_min`
  (`joharness.sh:7113-7120`), whose own comment states it.
- **`:184`'s discriminator excludes a session that ran one command, and
  `:185` matches and forbids the respawn** — GROUNDED. All four row
  quotations verified verbatim with correct line numbers.
- **`permission_mode` is named nowhere** — GROUNDED, repository-wide.
  CORRECTED: the draft said `grep -i "permission" manage.md` *"returns five
  hits, none about a permission prompt"*. It returns ZERO — the word does not
  occur in the file. The draft's five came from a different grep carrying
  three other alternatives, and the number was never re-counted. The true
  figure is stronger than the one claimed, which is the reason to state it:
  the draft's own Method handed a reader the command that refutes its
  sentence.
- **`:503-506` is the `create_session` argument enumeration** — GROUNDED.
  CORRECTED: the draft cited `:28-33`, which is the required-MCP-tools block.
- **#304's instruction fix cannot reach a permission prompt** — GROUNDED on
  #304's text and on what a suspended tool call leaves a session able to do.
  The second context also established that #304's instance HAD a branch,
  which is what removed the second `gx` session from this node's instance
  count.
- **The `gx` timeline, the session identifier, the `status_bucket` reading,
  `permission_mode` auto and the 15 minutes** — WEAK. Checked from one
  context only: the verifier has no control-plane tool and `chrsctl/gx` is
  not this checkout, which is the standing limit #267 records. The
  harness-side findings do not rest on them: `:190` matches a never-pushed
  session, and `:185` forbids its respawn, whether or not this instance
  happened as reported.

## Graduates to

`.agents/docs/orchestrated.md` — the file that carries the health table's
why-explanation, including the `stillborn` row (`:132`) and the knob table
(`:327`) the liveness rules lean on. The answer belongs beside that row
rather than in a rule line alone, because the reasoning is the valuable
part: `:184` chose *did a turn run* as the test for a no-branch session, and
the next reader has to see why that test splits the wrong way before adding
a second one — and why `:190` has to be narrowed before any row is added
beneath it.

Named, not written: the rows themselves live in
`.claude/commands/orchestrate.md`, which is protocol text
(`./joharness.sh protocol-paths`). A plan touching it is CORE ONLY, and
this node does not propose it.
