---
research: where-a-red-base-reading-goes
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/consumer-repos.md
---

<!--
Issue #305. Reported from a consumer by the route
`.claude/commands/upstream-report.md` names; canonical decides. The counts
(how many managers re-ran a suite, how many failures each attributed) are the
consumer orchestrator's report of a run that cannot be read here and are
marked reported-not-re-measured, as the issue marks them. Everything about
what the harness stores and what its channels carry was read from this repo's
source at `cb0028e`.
-->

## Question

Where should the reading "these checks are red on the base branch, and not
because of my diff" live, given that this harness forbids inheriting an
infrastructure reading and forbids trusting a written number?

## Echo

Several managers working in parallel against one base branch each hit the same
pre-existing failures, and each has to establish that those failures are not
its own. That means building a baseline and re-running a suite — once per
manager, for the same answer.

The obvious remedy is a file on the base branch saying which checks are red.
Two rules this repo enforces elsewhere cut straight through it: an
infrastructure reading is re-derived at every check and never inherited, and a
counted number is trusted while a written number is not. So the question is not
"should we cache this". It is whether any record of a red base can exist here
without being the thing both rules name — and if not, whose problem this is.

The second half of the question is the one with a surprising answer in the
source: the one channel the harness gives one manager to tell another anything
is shaped so that this particular message cannot travel it. That is a design
decision, not an omission, which changes what a fix is allowed to propose.

## Sweep

`goal-directed` — enough to establish that no record exists, that no reader
for one exists, that the inter-manager channel refuses this message by
construction, and which of the three proposed homes survives the two rules.
Not a survey of CI caching, and not an attempt to size the waste: that needs
the consumer's repository.

## What would settle it

- **Whether a keyed record is an inherited reading or a measurement with its
  provenance attached.** This is the whole question and the two rules decide
  it. The issue's own proposal is a record keyed to the base commit — read by a
  manager whose merge base IS that commit, re-derived and rewritten by one
  whose base has moved. Settled by holding that shape against the rule's own
  words (*"true this hour, false the next"*) and saying whether keying answers
  it or evades it.
- **Whether the destination is the harness's or the consumer's.** The harness
  ships; a baseline record is about one repository's test suite. If the answer
  is "the consumer owns it", the harness owes exactly one sentence saying so —
  and that sentence is the fix. Settled by deciding which side of the ship
  boundary this falls on.
- **What it costs if the record is a file on the base branch.** Every merge may
  touch it, which makes it a registry: `shared:` in any plan that writes it,
  and one more reconcile per merge. Settled by counting that against one
  baseline run, which cannot be done here.

Written before the reads below: an answer that proposes a file of failing test
names on the base branch, without addressing the two rules by name, has not
answered this question — it has written the thing the rules forbid and left the
next reader to discover why.

## Method

Source reads at `cb0028e`, each re-run rather than taken from the issue:

    git grep -in "baseline" -- joharness.sh .agents .claude
    grep -cn "gh api\|gh pr\|api.github" joharness.sh
    sed -n '9248,9252p' joharness.sh          # mutate's green-baseline precondition
    grep -n "BASELINE IS NOT GREEN" joharness.sh
    sed -n '134,138p' .agents/harness/AGENTS.md          # the inheritance rule
    sed -n '5,11p'   .agents/docs/feedback.md            # the written-number rule
    sed -n '164,188p' .claude/commands/manage.md         # what a lead may be
    sed -n '584,592p' .claude/commands/orchestrate.md    # the stem is checked
    grep -n "never act on" .claude/commands/orchestrate.md

## Findings

- **There is no record of a red base, and no reader for one.** `cb0028e`:
  `git grep -in "baseline" -- joharness.sh .agents .claude` returns **14**
  hits. An earlier draft said they were "only" three categories; the
  independent reader counted them and four fall outside, so here is the whole
  set rather than a summary. `mutate`'s precondition that the baseline be GREEN
  and its refusal (`BASELINE IS NOT GREEN — nothing can be attributed to a
  mutation`); the curate clock's *repository baseline*, hours since the base
  branch's first commit; selftest assertions about those two; and four that are
  a different word altogether — `.agents/docs/product/README.md:191` and `:216`
  (a single-agent BASELINE in a cited benchmark), `joharness.sh:3347` (an
  unmarked-detector-baseline record), `.agents/harness/selftest/cleanup.sh:238`
  (a fixture's own starting point). The conclusion is unchanged and now rests
  on all 14: **not one of them records which checks are failing on the base
  branch.** And `grep -cn "gh api|gh pr|api.github" joharness.sh`
  returns **0**, so nothing in the scheduler reads a check run at all — step
  7's *"GitHub checks green on head"* is a condition on the session, not on the
  script.

- **The two rules the fix has to get past are both live text.** `cb0028e`,
  `.agents/harness/AGENTS.md`: *"Infrastructure reading (runner up, registry
  reachable, base green) re-derived at every check, never inherited — true this
  hour, false the next."* And `.agents/docs/feedback.md`: *"Every number below
  is counted from git at read time, nothing stored. Trust counted numbers,
  never written numbers — including the ones on this page."* A file of failing
  test names on the base branch is an instance of both. The issue states this
  against itself, which is the reason it is a question and not a plan.

- **The one inter-manager channel refuses this message by construction, in four
  separate ways.** `cb0028e`: a lead is *"one line … the text at most 40
  characters"*, its stem *"must be a QUEUE ITEM's name — a plan stem, spelled
  as the queue spells it"*, checked against the queue by the orchestrator and
  silently unmatched otherwise; the orchestrator *"relay[s] a lead. You never
  act on one"*; and `manage.md` sends a lead with no stem — *"an open issue, an
  item already merged, the harness itself"* — to the pull request body instead,
  *"which outlives you and which a human reads"*. A baseline reading has no
  queue stem, does not fit in 40 characters, and would end in a body no peer
  manager reads. So several managers re-deriving it is the designed outcome.
  The channel is a POINTER channel, deliberately — *"at 40 characters it is a
  POINTER, and whoever follows it has your merged branch to read"* — and a
  reading of which tests are red is a payload, not a pointer.

- **The one shape that is NOT forbidden is already specified in the rule the
  issue cites.** `cb0028e`, `.agents/harness/AGENTS.md`, step 5: *"Measured
  number carries what produced it, same sentence — the command, and when.
  Number nobody can re-count is a written number."* A record carrying the base
  commit, the command and the time is a measurement with its provenance
  attached; keyed to a commit, it also satisfies the inheritance rule as
  written, because nothing survives a base change. Whether that is an answer or
  a loophole is the first bullet of `## What would settle it` and is exactly
  what this node refuses to decide.

- **Reported, not re-measured here: the duplication.** With the base branch's
  CI red for hours on 2026-10-07, at least four managers each built a baseline
  worktree and re-ran the full web suite to attribute the same pre-existing
  failures — reported in their own words as *"7 unrelated failures"*, *"115
  baseline"*, *"red from pre-existing main defects"*. The issue says plainly
  that these are the orchestrator's report and that what one baseline run costs
  there is unmeasured, so the SIZE of the waste is reported and not known. That
  matters for option 3 below: a cost nobody has counted cannot justify a gate.

## Consequence for the queue

No plan is blocked on this and none carries a `research:` edge to it.

The issue's three options are not equally cheap and the cheapest is almost
free: say, in the file that tells a consumer what is theirs, that a red-base
reading is the consumer's to keep and the harness does not carry one. Right now
the harness says nothing either way, and silence is what produced four baseline
runs in a day — each manager correctly re-deriving an infrastructure reading
because that is what the rule tells it to do.

Two cautions for whoever takes it:

- **Option 3 is a gate over a written number**, which the second rule above
  refuses, and it would be the first GitHub read in the scheduler. The issue
  ranks it last and says *"possibly never"*; a node answering this should not
  quietly promote it because it is the most satisfying shape.
- **Do not reach for the lead channel.** Four independent properties of it say
  no, and widening any of them (the 40 characters, the stem check, the
  relay-never-act rule) touches the forgery reasoning those bounds exist for.

Note for a parallel wave: a research node has no `scope:`, so the overlap guard
cannot see whether two answers would collide. This one lands in
`.agents/docs/consumer-repos.md`, which nothing else in this batch touches —
unlike the nodes aimed at `.claude/commands/orchestrate.md`.

## Verification

Second context: `.claude/agents/verifier.md` at opus.

- **No record of a red base, and no reader for one** — GROUNDED, but the word
  "only" is UNGROUNDED: the grep returns 14 hits, four of them a different sense
  of the word. The enumeration is now the whole set and the conclusion rests on
  all 14.
- **Nothing in the scheduler reads a check run** — GROUNDED, `0` re-counted.
- **The two rules a fix must get past** — GROUNDED, both quoted exactly.
- **The lead channel refuses this message four ways** — GROUNDED. The reader
  verified all four properties and the POINTER sentence against source.
- **The one shape not forbidden is the provenance rule's own** — GROUNDED as a
  reading of that rule; whether it answers the question or evades it is what
  the node leaves open.
- **The duplication and its counts** — WEAK, and the issue says so itself.

Standing limit on every claim below that came from the issue rather than from
this tree: `.claude/agents/verifier.md` declares `tools: Read, Grep, Glob,
Bash` and has no control-plane call, so a reported fleet reading can be
re-read against the issue and never re-sampled. That is issue #267, planned as
`docs/plans/verifier-cannot-read-the-plane.md`. Every such claim is marked
WEAK for that reason and not because anything contradicted it; the second
context did confirm each number against the issue it came from, and found no
invented one anywhere in this batch.

## Graduates to

`.agents/docs/consumer-repos.md` — the file that already says which concerns
are a consumer's own and which the harness carries, and the only one of the
candidate homes that costs nothing when the answer is "not ours". If the answer
instead turns out to be a keyed record, the record's shape still belongs beside
the sentence saying whose it is, because the rule it has to survive
(`.agents/harness/AGENTS.md`, infrastructure readings) is read by every session
and would otherwise be contradicted by a file nobody can place.
