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

The health table is a liveness table. Every row that ends in a respawn requires
the session to be gone — crashed and confirmed, archived, or silent across two
passes — and a manager that commits, pushes and bills steadily satisfies none
of them. So a manager can be alive on every signal and still be the wrong place
for the next hour of the human's money, and nothing in the loop has a word for
that state.

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
  precondition.** Two refreshes in the reported run finished items in minutes
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
  cost equivalent return **zero** hits at `cb0028e`. The knobs that exist are
  `JOHARNESS_MAX_MANAGERS`, `JOHARNESS_STALL_MINUTES`,
  `JOHARNESS_HEALTH_MINUTES`, `JOHARNESS_RESPAWN_LIMIT`,
  `JOHARNESS_CHURN_LIMIT` and `JOHARNESS_CHURN_THRESHOLD` — a cap on
  concurrency, a silence threshold, a pass cadence, a respawn count, and two
  per-file rewrite bands. Nothing measures an item against time or money.

- **The in-flight row carries no elapsed-time and no cost field, and its one
  age is not what the row's own word says.** `cb0028e`: the work line is built
  from `rev-list --count` (commits since the base), `churn_top` (one file's
  rewrites) and the review-marks count. The age printed as `pushed <N>h` comes
  from `dispatch_age_min`, which reads `git log -1 --format=%ct` on the remote
  ref — the tip COMMIT date, not a push time, and in either case the age of the
  LAST write rather than the age of the claim. So the row says how recently the
  manager moved and never how long it has been moving.

- **Every respawn row in the health table requires the session to be GONE.**
  `cb0028e`, `.claude/commands/orchestrate.md`: confirmed dead
  (`archive_session`, THEN RESPAWN), archived or not found by title (RESPAWN,
  *"no nudge, there is nobody to ask"*), nudged and silent across two passes
  (*"NOW gone"*), stillborn (never ran a turn), and gone at the edge
  (*"RESPAWN on that branch to FINISH the merge, never to restart the plan"*).
  There is no row for a session that is alive, pushing and expensive. This is
  the gap, stated as the table's own shape rather than as an absence: the
  refresh the issue asks for would be the FIRST row that acts on a working
  manager, which is why its precondition is the whole design and not a detail.

- **The last row is the shape a refresh wants, and it is reachable only when
  the owner is gone.** *"gone at the edge … RESPAWN on that branch to FINISH
  the merge"* is exactly the two cheap successes the issue reports. So the fix
  is not a new mechanism; it is the same mechanism with its precondition
  widened from "gone" to "gone, or past a ceiling at the finish" — and that
  widening is where the live-session risk enters.

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

Pending: the independent read of this branch.

## Graduates to

`.claude/commands/orchestrate.md` — the health table is where a refresh row
would live, and it is the file whose every respawn precondition is "gone". The
knob's meaning and the cost that bought it belong under
`.agents/docs/orchestrated.md`'s knob table in the same graduation; the rule
alone is what produced a table where a working manager has no row, and a rule
line without the counter-case is how the mid-diagnostic refresh gets written.
