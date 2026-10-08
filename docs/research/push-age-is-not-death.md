---
research: push-age-is-not-death
urgency: urgent
agent: opus
effort: xhigh
graduates: joharness.sh
---

<!--
Issue #283, with its comment. Reported from a consumer by the route
`.claude/commands/upstream-report.md` names; canonical decides. The
control-plane readings — five candidate liveness signals measured against
known outcomes — are about live sessions and cannot be taken here; they are
the issue's, marked as such. What the scheduler prints, and what it measures
to print it, was read from this repo's source at `cb0028e`, and one claim in
the issue's comment did not reproduce.

`urgency: urgent` because the verdict is destructive and has fired wrong —
the reasoning is under `## Consequence for the queue`.
-->

## Question

May the scheduler print a respawn instruction on a row whose only evidence is
the age of the branch's last commit, given that a suspended fleet and a dead
manager are indistinguishable on every signal that view holds?

## Echo

The scheduler is a git-view tool by design and the control plane is the
orchestrator's to consult. On a row it cannot find a session for, it says
exactly that — cross-check the control plane by title — and then supplies the
conclusion anyway: respawn on the branch to finish it.

The conclusion is unsupported by the only evidence the row has. A branch stops
receiving commits when its manager dies, and also when the whole fleet is
stopped, and also when the manager is mid-step-7 having just retired its
workstream file. The row cannot tell those apart, and the action it recommends
for the first is destructive in the second: a second manager on a branch whose
owner is at that moment running the finish guard.

What I am asking is narrower than "how do we detect death". It is whether a row
may carry an instruction its evidence cannot support — and if the answer is
that it may not, what the row says instead. The issue's own answer is to drop
the sentence and leave the instruction where the evidence is, which costs
nothing and is the one change that prevents the destructive act.

## Sweep

`comprehensive`, over what the scheduler's view can and cannot support — every
signal it reads for this row, and what each one is true of. Not a survey of
liveness signals generally: the control-plane half is the orchestrator's and
is measured in the issue.

Comprehensive rather than goal-directed because the answer is a claim about
what a view CANNOT support, and a claim of that shape is refuted by one signal
the sweep missed.

## What would settle it

- **Whether any signal in the git view distinguishes a stopped manager from a
  stopped fleet.** If one does, the row's instruction is salvageable and the
  fix is to gate it. If none does, the sentence has to go. Settled by
  enumerating the row's inputs — which is a bounded read of one function and
  its callers, not a judgement.
- **What the row says instead.** Dropping a sentence leaves a gap, and the
  orchestrator reads this output to act. The replacement has to be actionable
  without being a verdict: name the cross-check, name what would make it a
  respawn, and stop.
- **Whether a fleet-wide question is cheap enough to be the gate.** The issue's
  third option is one command — did anything at all merge in this window —
  which distinguishes "this manager stopped" from "everything stopped". Settled
  by whether that read is available where the row is built.
- **Where the discriminator the issue names belongs.** Cost is a control-plane
  field; the scheduler cannot read it and should not. So this bullet is about
  the orchestrator's evidence table and not about the row, and the two should
  not be answered in one change.

Written before the reads below: an answer that widens what the scheduler reads
has not answered this question. The view is a git view on purpose, and the
issue argues for narrowing what it CLAIMS rather than widening what it sees.

## Method

Source reads at `cb0028e`, each re-run rather than taken from the issue:

    grep -n "respawn on the branch to FINISH" joharness.sh .claude/commands/orchestrate.md
    sed -n '8238,8250p' joharness.sh          # the edge STALL? rows
    sed -n '8218,8222p' joharness.sh          # the "PR in flight" row
    sed -n '7116,7130p' joharness.sh          # what the age actually measures
    grep -cn "gh api\|gh pr\|api.github" joharness.sh
    git grep -n "cost_usd" -- .claude .agents
    sed -n '151p'      .claude/commands/orchestrate.md   # the updated_at row
    sed -n '174,192p'  .claude/commands/orchestrate.md   # every respawn row
    git grep -niE "suspend|fleet.?wide|stopped fleet" -- joharness.sh

Not yet run, and what the third bullet of `## What would settle it` needs — the
fleet-wide question, from the view the row is built in:

    git -C "$ROOT" log -1 --format=%ct "refs/remotes/origin/${base_branch}"

## Findings

- **The instruction is still printed, verbatim, on push age alone.** `cb0028e`,
  `joharness.sh:8241`:

      STALL? no push for ${eagetext} (>= ${stall}m): cross-check the control
      plane by TITLE (manager: ${estem}) — this row carries no session line to
      read. Gone — ARCHIVED, not found, or FAILED confirmed twice, never IDLE
      alone (.claude/commands/orchestrate.md) — means nobody is driving this
      merge: respawn on the branch to FINISH it, never to restart the item

  The row asks for a cross-check and then states the conclusion. Its only
  input is the age.

- **And the age is not what the row calls it.** `cb0028e`,
  `dispatch_age_min`: `git log -1 --format=%ct "refs/remotes/origin/$1"` — the
  tip COMMIT date. The row prints it as `pushed <N>h`. For this question the
  distinction cuts the same way as the issue's point and one step further: the
  number is frozen by a stopped fleet, and it is also wrong about a commit made
  before a push. `.agents/harness/AGENTS.md:234` already says *"Push time
  not liveness. Wrong both directions"*; the row's own label claims a push time
  it never read.

- **Nothing in the git view distinguishes a stopped manager from a stopped
  fleet.** `cb0028e`: `git grep -niE "suspend|fleet.?wide|stopped fleet" --
  joharness.sh` finds no such reading, and the row's inputs are the ref's tip
  date and the stall threshold. The one cheap discriminator the issue proposes
  — did anything at all land on the base branch in this window — is not read
  anywhere in the row's construction, and the ref it would need is already in
  hand (the walk computes a merge base against `refs/remotes/origin/<base>` for
  every branch it lists). So the sweep's answer is: no signal, and the missing
  one is one `git log` away.

- **The second defect reproduces as an assertion in the source.** `cb0028e`,
  `joharness.sh:8220`: the retired-edge row prints `PR in flight, no claim
  file: step 7 retired the workstream file before the pull request opened …`.
  There is no pull-request read behind it — `grep -cn "gh api|gh pr|api.github"
  joharness.sh` returns **0** — so the phrase is inferred from the claim file's
  absence. The issue measured it naming pull requests that did not exist, on
  branches cut off between the retire commit and the pull request. The row's
  slot accounting was right for a different reason than the row gave.

- **Option 2 is undone, and the issue's comment misstates what it would
  change.** The comment says *"orchestrate.md's death test is 'frozen
  `cost_usd` across two reads + IDLE + unmoved head'"*. At `cb0028e` that test
  is not in that file: `git grep -n cost_usd -- .claude .agents` finds
  `cost_usd` **only** in `.agents/docs/orchestrated.md`, three times, each a
  spend total or a measurement narrative — never in the health table. The
  table's death tests key on `status_bucket`, `status_detail` / `updated_at`
  and the head: *"`updated_at` decides nothing ALONE, at any interval"*, and
  the confirmed-dead rows require `updated_at` AND head unchanged since a
  recorded `seen=`. So the proposed time floor is a floor under a test the file
  does not carry, and naming cost as the discriminator is still the whole of
  option 2 — a larger change than the comment implies, and one that would put
  a control-plane money field into the evidence table for the first time.

- **Every respawn the health table orders rests on at least TWO observations;
  the scheduler's row rests on one.** `cb0028e`,
  `.claude/commands/orchestrate.md`: the confirmed-dead row needs a recorded
  `seen=` plus `updated_at` AND head unchanged since it; the stall path needs a
  nudge recorded and then a second look (*"Never kill on this first one; two
  passes is the rule, and the missing tool removes the message, not the second
  look"*); the LOOP row needs `same=2` already in the ledger; the idle row needs
  a nudge and then head AND `status_detail` unchanged. The scheduler's edge row
  has no ledger, no session record, and one number — and it is the only place in
  the harness that recommends a respawn from a single reading.

- **This question has been half-answered once, and the answer was WITHDRAWN on
  review. Read that before proposing a cost test.** `cb0028e`,
  `.agents/docs/orchestrated.md`, under the knob table: an earlier draft of
  that very paragraph *"read the ambiguous row as a slow writer, built a
  cadence spread on it, and graduated a sentence licensing a kill verdict on a
  13-minute frozen pair. The reviewer found the frozen usage counters and that
  reading did not survive them."* The file's own instruction follows —
  *"Read the node in history before adding a knob here"*:

      git log --diff-filter=D -p -- docs/research/liveness-in-a-long-turn.md

  That node closed on the narrower question of what the health pass may KEY ON,
  and its answer is the table's current row. So a session taking THIS node and
  reaching for a frozen-cost threshold is walking a path that has already been
  walked and reverted at a 13-minute pair — the four windows in this file run
  19 to 31 minutes, which is the same mistake one step larger.

- **Reported, not re-measured here: three live managers read as 434h stalls.**
  On 2026-10-05, an orchestrator session itself suspended from ~2026-09-17
  20:30Z to 2026-10-05 22:45Z resumed and ran the scheduler: all three managers
  in flight were reported stalled for 434 hours, and for two of them the row
  printed the respawn instruction. All three were alive — read from the control
  plane within 90 seconds of that run, `RUNNING`, with `updated_at` at
  22:47:21Z / 22:47:28Z / 22:47:33Z and `cost_usd` 23.7686223 / 144.76052 /
  24.0942572. Their own summaries at that moment: *"Verifying numbers and
  running the finish guard"*, *"post-merge verified clean; committing renumber,
  opening PR"*, *"DB setup in parallel; workers running; restoring env after
  rate limit"*. Had the row been followed, three successors would have landed
  on three branches whose owners were mid-finish.

- **Reported, not re-measured here: five signals, four refuted.** Measured over
  that run and the one before it — push age (0 for 20 as a death signal before,
  then 3 for 3 wrong in the expensive direction at the largest age observed);
  `updated_at` (a sweep artefact; two unrelated sessions 1.6 ms apart);
  `status_detail` / `task_summary` (byte-identical across 23 minutes of live
  work); `connection_status` (`connected` survives death); `worker_epoch`
  (bumped 4→5 on a corpse at frozen cost on 2026-09-17, AND 1→2 on all three
  survivors across the suspension — it moves in both cases, so it discriminates
  neither). `cost_usd` was the only field that separated them, and the same
  resume supplied the negative control the earlier measurement lacked: a
  session read at exactly `136.9262205` on 2026-09-17T19:31:07Z with an unmoved
  head, open as possibly dead, read at `144.76052` after the resume — never
  dead, only suspended.

- **Reported, not re-measured here: the four windows that bound the cost
  test.** A live manager on 2026-10-07 read `IDLE`, `connected`, its turn ended
  on a background run, with cost frozen across four windows — 28.058789 from
  20:19:50Z to 20:38:09Z, 32.2565868 from 21:15:04Z to 21:34:19Z, 36.8669214
  from 22:11:07Z to 22:30:41Z, 42.1354032 from 22:55:14Z to 23:26:01Z. The
  windows run 19 to 31 minutes; reads 13 to 15 minutes apart met a
  two-reads-plus-IDLE-plus-unmoved-head test on every one of them. It was alive
  throughout and finished its work. A floor at the stall default would have
  been right on all four.

## Consequence for the queue

No plan is blocked on this and none carries a `research:` edge to it.

**Marked `urgent`, and here is the argument rather than the adjective.** This
is the only row in the harness that recommends a destructive act — a second
manager on a branch somebody else owns — from one reading, and it has fired
wrong three times out of three in the one run where the expensive direction was
available. Every other node in this batch costs a duplicate, a delay or a
re-measurement; this one costs a collision at the finish. The narrowest fix is
deleting a sentence. Canonical may disagree with the mark; this paragraph is
what it rests on.

Three things whoever takes it should carry in:

- **The cheap fix and the expensive fix are different changes and should not
  land together.** Option 1 is a sentence in `joharness.sh`. Option 2 puts a
  money field into the orchestrator's evidence table for the first time and
  needs the four windows above as its floor. Reading the issue's comment as
  "add a floor to an existing test" is wrong: no such test is written.
- **The second defect is a separate fix in the same row's neighbourhood.** The
  `PR in flight` phrase is asserted, and the scheduler makes no GitHub call —
  so making it honest means either softening the phrase or adding the first
  such call, which is a boundary decision and not a wording one.
- **Option 3 is one `git log` and the ref is already in hand.** It is the only
  option that turns "this manager stopped" into "everything stopped" without
  leaving the git view, which is the property the issue argues for throughout.

And one thing this node cannot have: an independently verified control-plane
half. `.claude/agents/verifier.md` declares `tools: Read, Grep, Glob, Bash`
and has no control-plane call, so the five-signal measurement above can be
re-read but not re-sampled here — the defect `docs/plans/verifier-cannot-read-the-plane.md`
(issue #267) exists to fix. Until that plan lands, every fleet number in this
file is WEAK by this repo's own vocabulary, and a session that writes a verdict
on it anyway is repeating the withdrawal recorded two findings up.

Note for a parallel wave: a research node has no `scope:`, so the overlap guard
cannot see that this node and `rescope-re-offered-after-merge` would both land
in `cmd_dispatch`'s row builders, nor that this node's option 2 reaches into
`.claude/commands/orchestrate.md` where three other nodes in this batch land.
Taking two at once collides.

## Verification

Pending: the independent read of this branch.

## Graduates to

`joharness.sh` — the edge `STALL?` row in `cmd_dispatch` is where the
unsupported instruction is printed, and `dispatch_age_min` is where the number
behind it is computed. The answer is a change to what a counted read is allowed
to CLAIM, which is code and not a rule a session obeys. Option 2's half, if
canonical takes it, graduates separately into the orchestrator's evidence table
and should carry the four frozen-cost windows with it; splitting them is the
point, because one is a deletion and the other is a new class of evidence.
