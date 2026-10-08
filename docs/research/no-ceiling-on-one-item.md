---
research: no-ceiling-on-one-item
urgency: normal
agent: opus
effort: xhigh
graduates: .claude/commands/orchestrate.md
---

<!--
Issue #298. Reported from a consumer by the route
`.claude/commands/upstream-report.md` names; canonical decides. The cost,
token and timing numbers are about a live orchestrated fleet and could not be
taken here — they are the issue's, marked as such. The claims about what the
harness reads and what its health table permits were read from this repo's
source at `cb0028e`.
-->

## Question

What bounds the time and money ONE item may consume in an orchestrated run,
given that every signal the scheduler reads reports a manager spending both as
healthy?

## Echo

The health table is a liveness-and-repetition table. It acts on a session that
is gone, on one that has stopped pushing, and on one that is going round in a
circle — and a manager that commits, pushes, moves its `next:` line and bills
steadily satisfies none of those. So a manager can be healthy on every signal
and still be the wrong place for the next hour of the human's money, and
nothing in the loop has a word for that state: every reading is about whether
work is HAPPENING, and none about what it has cost.

What I am asking is not "is this manager stuck". The issue is explicit that its
example was converging and says so twice. It is: does a bound belong here at
all, and if so is it a detector (`dispatch` flags it) or a rule (the
orchestrator refreshes a long manager), and what does the bound read — because
the obvious reading, elapsed time with no pull request, needs a fact the
scheduler does not have.

The second half is the part the issue only half-states and the part with
evidence under it: the same run shows a refresh working twice and shows why a
third would have cost something. So the question has a cheap side and an
expensive side, and they are not the same decision.

## Sweep

`goal-directed` — enough to decide whether a ceiling is a detector or a rule,
what it can read, and what refreshing a LIVE manager costs. Not a survey of
budget enforcement, and not an answer to what the right number is: the issue
declines to claim one and this node must not supply it.

## What would settle it

- **What the bound reads.** A ceiling phrased as "past N hours with no pull
  request" needs a pull-request fact. If the scheduler cannot have one, the
  bound has to be re-derived from something it can read, or moved to the
  orchestrator, which can. Settled by naming the readable signal.
- **Whether a refresh of a LIVE manager is ever sound, and under what
  precondition.** (The table already kills a live one on the LOOP row, so the
  question is which precondition, not whether such a row may exist.) Two refreshes in the reported run finished items in minutes
  for about a dollar each; both were sessions that had gone quiet AT THE FINISH
  with their state already on the branch. A refresh mid-diagnostic ends the
  container and loses an in-flight run. So the precondition is about where the
  manager IS, not how long it has been there — and a rule keyed on hours alone
  would fire in the wrong place. Settled by a precondition that distinguishes
  them from artifacts the orchestrator can read.
- **Whether a number belongs in `joharness.conf` at all.** A ceiling is the
  human's money and the issue says the right value differs by an order of
  magnitude between a planning item and a three-line fix. A single knob
  flattens that. Settled either by a knob with a stated meaning, or by the
  finding that the ceiling is per-plan and belongs in plan frontmatter, or by
  the finding that it is a report line and never a threshold.

Written before the reads below: a rule that archives a live, pushing manager on
elapsed time alone has not answered this question — it has moved the cost from
a slow item to a lost one.

## Method

Source reads at `cb0028e`, each re-run rather than taken from the issue:

    git grep -n "JOHARNESS_MANAGER_HOURS\|JOHARNESS_MANAGER_COST"
    git grep -no "JOHARNESS_CHURN_[A-Z_]*\|JOHARNESS_RESPAWN_LIMIT" -- joharness.sh
    grep -cn "gh api\|gh pr\|api.github" joharness.sh
    sed -n '8320,8342p' joharness.sh                  # the in-flight work line
    sed -n '7116,7130p' joharness.sh                  # what the age measures
    grep -n "RESPAWN\|to FINISH" .claude/commands/orchestrate.md
    git grep -n "cost_usd" -- .claude .agents
    sed -n '320,340p' .claude/commands/orchestrate.md  # KILL, step 1

Not yet run, and what the first bullet of `## What would settle it` needs: the
age of a branch's FIRST commit past its merge base, over this repo's own merged
edges, against how long each took to reach a pull request —

    git log --format='%ct %H' "$(git merge-base origin/main <ref>)..<ref>" | tail -1

## Findings

- **No ceiling knob exists.** `git grep -n JOHARNESS_MANAGER_HOURS` and the
  cost equivalent return **zero** hits at `cb0028e`.

  An earlier draft then listed "the knobs that exist" as six, from a grep that
  reached three of them; the independent reader counted the real set. The
  enumerating command is

      git grep -ho "JOHARNESS_[A-Z_]*" -- joharness.sh | sort -u

  which prints 45 lines at `cb0028e`, one of them the bare prefix
  `JOHARNESS_` (the pattern's tail matches empty), so **44 names**. Counted
  twice, because the independent reader and I disagreed by one and the
  difference was that line. The orchestrated ones the health
  pass and the verdict read are `JOHARNESS_MAX_MANAGERS` (a cap on
  concurrency), `JOHARNESS_STALL_MINUTES` (a silence threshold),
  `JOHARNESS_HEALTH_MINUTES` (a pass cadence), `JOHARNESS_RESPAWN_LIMIT` (a
  respawn count), `JOHARNESS_CHURN_THRESHOLD` and `JOHARNESS_CHURN_LIMIT` (two
  per-file rewrite bands) and `JOHARNESS_PENDING_SPAWNS` (this pass's unclaimed
  spawns). The 44 also hold elapsed-time knobs — `JOHARNESS_CURATE_HOURS`,
  `JOHARNESS_JANITOR_HOURS` — which is why the claim has to be stated against
  the whole set and not a shortlist: **those are cadences for a cycle, not a
  bound on one item**, and nothing in the 44 measures an item against time or
  money. That is the claim, and it survives the full count.

- **The in-flight row carries no elapsed-time and no cost field, and its one
  age is not what the row's own word says.** `cb0028e`: the work line is built
  from `rev-list --count` (commits since the base), `churn_top` (one file's
  rewrites) and the review-marks count. The age printed as `pushed <N>h` comes
  from `dispatch_age_min`, which reads `git log -1 --format=%ct` on the remote
  ref — the tip COMMIT date, not a push time, and in either case the age of the
  LAST write rather than the age of the claim. So the row says how recently the
  manager moved and never how long it has been moving.

- **There IS a row for a live, pushing manager — and it measures repetition,
  never spend.** This is the correction the issue's framing needs. At
  `cb0028e`, `.claude/commands/orchestrate.md`'s health table acts on a
  session in three ways: GONE (confirmed dead, archived or not found by title,
  stillborn, gone at the edge), SILENT (`RUNNING` with `STALL?` — no push past
  `JOHARNESS_STALL_MINUTES` — nudged once and unchanged across two passes,
  then KILL), and LOOPING — *"`LOOP?` on the line (churn past
  `JOHARNESS_CHURN_LIMIT`), or THIS pass's head moved and `next:` still
  unchanged, with `same=2` already in the ledger"*, whose own note says *"No
  nudge — a nudge asks for a push, and a loop is pushing."*

  So the table already kills a manager that is alive AND pushing. What the
  LOOP row reads is one file's rewrite count (`JOHARNESS_CHURN_THRESHOLD`
  default 5, `JOHARNESS_CHURN_LIMIT` twice it) or a head that moves while
  `next:` does not. Neither is time and neither is money. The reported item
  sat at churn 5 on one file — the warning band, under the limit — so the first
  clause did not match; whether the second could have is NOT knowable from the
  issue, which does not report that item's `next:` line or its `same=` count.
  What the reads above do establish is the shape of the gap, and it is narrower
  and more precise than "no row for a working manager": the one row for a
  working manager asks whether it is REPEATING itself, and nothing anywhere
  asks what it has spent.

- **The edge row is the shape a refresh wants, and it is reachable only when
  the owner is gone.** *"gone at the edge … RESPAWN on that branch to FINISH
  the merge"* is exactly the two cheap successes the issue reports. So the fix
  is not a new mechanism; it is the same mechanism with its precondition
  widened from "gone" to "gone, or past a ceiling at the finish" — and that
  widening is where the live-session risk enters. Note which precondition it
  would NOT be: the LOOP row's, which kills with a progress record and
  respawns to continue the item, not to finish it.

- **The scheduler cannot read a pull request, so option 1 as phrased is not
  buildable.** `grep -cn "gh api|gh pr|api.github" joharness.sh` returns **0**
  at `cb0028e`. The proxy the scheduler uses instead is the claim file's
  absence, printed as `PR in flight, no claim file`. That proxy is asserted and
  not checked, which is a separate measured defect (#283, second finding): it
  named pull requests that did not exist. A ceiling built on it inherits that.

- **Reported, not re-measured here: one item at 48 USD and 5.5 hours, read as
  healthy.** A live manager read on 2026-10-07 at 23:27Z, created 17:52Z:
  `cost_usd 48.1425436`, context `710,825 / 1,000,000 tokens`, 8 commits, 2
  findings, churn 5 on one test file, no pull request. Cost rising between
  reads, branch still receiving pushes, churn at the warning band and under the
  loop limit — healthy on every signal. The issue does not claim it was stuck,
  and says it was converging on its own account.

- **Reported, not re-measured here: what a refresh bought, twice.** Two items
  finished by a fresh session on the old session's branch after the original
  went quiet at the finish:

  | item | old session | fresh session |
  | --- | --- | --- |
  | first | $46.08, 712k tokens | merged in about 5 min, $0.88 |
  | second | $18.96, 496k tokens | merged in about 6 min, $1.89 |

  Both fresh sessions did only the last mile — merge the base branch, run the
  checks, merge. The state was in the branch and the workstream file, which is
  what the handover protocol exists to make true.

- **The counter-case is in the same run and bounds the fix.** Reported: a
  refresh of the 48-USD manager mid-diagnostic would have ended its container
  and killed an in-flight test run; only the pushed branch survives. Read from
  source at `cb0028e` and narrowing it: the KILL path does NOT start with an
  archive — step 1 is `interrupt_session`, *"Its Stop guard fires; it may
  push. Wait one pass"*, and step 2 checks whether the handover landed before
  writing one. So a bounded ask-then-refresh already exists in the table's
  machinery. What it cannot do is COMPEL the push: `handover-guard.sh`'s own
  header says it is advisory and one-shot — *"A session that read the reminder
  and still means to stop … just stops again"* — which is why the step reads
  *"may push"*.

- **Reported, not re-measured here: the time floor the frozen-cost test
  needs.** The issue's item 3 is the measurement in #283's comment — a live
  manager read `IDLE` with a frozen cost across four windows of 19 to 31
  minutes while a background run finished. It is carried by
  `docs/research/push-age-is-not-death.md`, not restated here: it is a
  threshold on a liveness test, and this node is about a ceiling on spend.
  Also read from source, bearing on both: `git grep -n cost_usd -- .claude
  .agents` at `cb0028e` finds it **only** in `.agents/docs/orchestrated.md`,
  three times, each a spend total — never in the health table. So the test the
  issue's item 3 proposes a floor FOR is not written in the file a session
  reads.

## Consequence for the queue

No plan is blocked on this and none carries a `research:` edge to it.

Three things whoever takes it should carry in before costing the options:

- **Item 1 cannot be built in `dispatch` as phrased**, because a pull request
  is invisible there and the proxy for it is a known-bad reading. Either the
  detector reads the claim's AGE (available: the first commit past the merge
  base) and says only that, or the ceiling is the orchestrator's, which can
  read both cost and the pull request.
- **Item 2 is the whole risk.** A refresh keyed on hours fires on the
  mid-diagnostic case the issue names as the counter-example. The precondition
  has to be "at the finish", and what the orchestrator can read about that is
  the workstream file's `status:` and the retired-edge row — not elapsed time.
- **Item 4 is narrower than it reads** and partly exists: `interrupt_session`
  then a pass, then check whether the handover landed. What is missing is not a
  channel but a gate — nothing can compel the push, by the guard's own
  contract. A node answering this must not propose strengthening that guard
  without reading `docs/research/guard-fires-on-an-empty-branch.md`, which is
  about the same file from the opposite direction (it fires too often).

Note for a parallel wave: a research node has no `scope:`, so the overlap guard
cannot see that this node, `push-age-is-not-death` and `ledger-fields-with-no-rebuild`
would all land in `.claude/commands/orchestrate.md`'s health and ledger
sections. Taking two at once collides.

`.claude/commands/` is a protocol path (`./joharness.sh protocol-paths`), so the
branch that answers this is supervised.

## Verification

Second context: `.claude/agents/verifier.md` at opus.

- **No ceiling knob exists** — GROUNDED, zero hits re-counted.
- **The knob enumeration had no command behind it** — UNGROUNDED as written. The
  reader counted the real set; the list is now the output of a named command,
  with the one line that is not a knob called out. The claim it supports —
  nothing measures an item against time or money — survives the full 44.
- **The in-flight row carries no time or cost field, and its one age is the tip
  commit date** — GROUNDED.
- **A live, pushing manager is matched only by the LOOP row, which reads
  repetition** — GROUNDED. Found by this file's author against an earlier draft
  that claimed no such row existed, and confirmed by the second context from
  the table's own text.
- **The edge row is the shape a refresh wants** — GROUNDED.
- **The KILL path interrupts before archiving, and cannot compel a push** —
  GROUNDED, both quoted exactly.
- **The 48 USD item, the two refreshes, the counter-case** — WEAK.

Standing limit on every claim below that came from the issue rather than from
this tree: `.claude/agents/verifier.md` declares `tools: Read, Grep, Glob,
Bash` and has no control-plane call, so a reported fleet reading can be
re-read against the issue and never re-sampled. That is issue #267, planned as
`docs/plans/verifier-cannot-read-the-plane.md`. Every such claim is marked
WEAK for that reason and not because anything contradicted it; the second
context did confirm each number against the issue it came from, and found no
invented one anywhere in this batch.

## Graduates to

`.claude/commands/orchestrate.md` — the health table is where a refresh row
would live, beside the three readings it already makes (gone, silent,
looping). The knob's meaning and the cost that bought it belong under
`.agents/docs/orchestrated.md`'s knob table in the same graduation: a rule line
alone is what produced a table that measures whether work is happening and
never what it cost, and a rule line without the counter-case is how the
mid-diagnostic refresh gets written.
