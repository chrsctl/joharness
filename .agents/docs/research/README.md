# Research queue

Open questions with the standing of a plan. One file per question, under
`docs/research/`, on `main`. Loop step 2 lists them beside plans, same
ordering — oldest actionable first, urgent first if marked. No special rank:
a plan blocked on an open question already drops out of the entrypoint, and
that is rank enough.

The node exists so a finding outlives the session that made it. A session
that researches, acts, and ends leaves nothing behind but a diff; the next
session re-opens the same question and reaches its own answer, which may
differ. Everything here is machinery for that one problem — not a
methodology. How to research is a session's business; that the answer
survives is the harness's.

## Shape

Copy [`TEMPLATE.md`](TEMPLATE.md). Nine sections, in order — **all nine**
taken from the four files that landed before this definition did, agreeing
without being told to. This page adds no section; it says why three of them
are load-bearing, and one of the four gains the `## Method` heading the
other three already had. An earlier draft of this paragraph claimed six came
from practice and three from here. Counted: three instances carry all nine
headings, one carries eight.

Both names are in use and both stay. A **research file** is the node — what
the graph, the lint and this page call it. **Open questions** is the queue
hook's label for the same files, because that is what a session reading the
hook is being offered. No glossary row: the two are not rival spellings of
one term, and a substring ban on either would fire on prose that is correct.

### What makes a file a node

`docs/research/` may also hold plain reference documents — prose a session
wrote that is not a scheduled question. **A node opens with a `---`
frontmatter block; a document does not.** The lint
(`joharness.sh:lint_nodes`) and the queue hook
(`.agents/harness/queue-context.sh`) both draw the line there, so a document
is neither reded for missing a node's keys nor listed as an open question.
This is the one queue directory with that split: `docs/plans/` and
`docs/handover/` hold nothing but nodes, and a frontmatter-less file there
is malformed, not exempt.

Why by the block and not by a marker: a consumer synced before this protocol
existed carries research prose with no frontmatter at all, and a rule keyed
on the block leaves those files alone with no edit — where a required
opt-out marker would red every one until a human touched it
(`chrsctl/gx#226`: 13 documents, a green consumer turned red by the sync
alone). The block cannot be dropped by accident to dodge the queue and still
be a node: a node stripped of its `---` is a legibly-not-a-node document in
the directory, while a node that keeps the block and forgets one key is
still DEAD.

- **Question** — one sentence, answerable. A question with no evidence that
  could settle it is not a research question. It is a topic, and a topic
  never closes.
- **Echo** — the question restated in the researcher's own words before any
  method runs. A model that misreads its input and then reasons competently
  on the wrong input produces an answer correct in shape and wrong in
  substance; the echo is the cheapest place to catch that, because it costs
  one paragraph and happens before the work.
- **Sweep** — `comprehensive` or `goal-directed`, named explicitly. This is
  the choice that decides what "complete" means: everything there is, or
  everything needed for what. Unnamed, completeness is unfalsifiable and the
  question never closes.
- **What would settle it** — written BEFORE the method runs. Written after,
  it is a description of what was found, and every finding settles the
  question by construction.
- **Method** — the commands. Web queries are commands; quote them.
- **Findings** — each with the command or source that produced it.
- **Consequence for the queue** — which plan changes, in what way, or none.
  Not in this shape's first draft: all four instances grew it unprompted,
  and it is the hop a plan reader acts on.
- **Verification** — see below.
- **Graduates to** — the file the answer lands in.

Frontmatter: `research` (the stem), `urgency` (`normal` | `urgent`), `agent`
(`haiku` | `sonnet` | `opus`), `effort`, `graduates` (the file the answer
lands in). The tier the queue prints comes from `agent`, same as a plan's.

## Verification is not optional

A finding nobody checked from a second context is not settled, and this file
says that as a rule rather than a preference.

[`../graph.md`](../graph.md) Rules already states the diamond rule for code:
verify outside the context that wrote it, because self-grade alone misses
own mistakes. Research is where it bites hardest — a model cannot reliably
audit its own grounding, so the pass that checks whether a citation says
what the finding claims has to run somewhere the finding was not made. A
subagent is the cheap way to get that second context
([`../subagents.md`](../subagents.md)).

One instance shows the failure the section exists to catch: a search result
that echoed the researcher's own phrasing back was recorded as a second
source. It corroborated nothing. The verification pass found it.

**Who checked, and from where. Never when.** Provenance is commits
([`../graph.md`](../graph.md) Rules, "never hand-write time into a file"),
and a hand-written date is a second copy of what `git log` already knows —
wrong the first time somebody edits the file without touching the date. The
four instances that predate this rule each carried one, and the commit that
added this paragraph removed all four. That commit also added a `## Method`
section to `glossary-enforcement` — the shape migration below, not a change
to any finding, and named here because "removed the dates and nothing else"
was written first and was false.

Mark each claim **GROUNDED**, **WEAK** or **UNGROUNDED**. Three words, not
two: the instances use all three, and the failure this section exists to
catch is a claim that turned out refuted — a vocabulary with no word for it
would push that into prose nobody greps.

## Edges

`research:` on a PLAN names an open question that plan is waiting on. The
plan is blocked while `docs/research/<question>.md` exists, and free the
moment it is deleted — the same machinery `needs` uses, for the same reason:
file existence IS the state, so there is no status field to go stale.

`graduates:` on a RESEARCH file names where the answer goes. Declared here,
completed by the merge that deletes the file — the `graduated` edge the
graph already defines for workstreams.

Both are single-hop. A session asks "what is open, what is blocked on it"
and reads the answer out of hook output without traversing anything.

## Graduating

The pull request that closes a question deletes the research file and writes
the answer into the file `graduates:` named. Same lifecycle as a plan: done
means deleted, and history keeps the record.

Write the WHY-EXPLANATION, not only the rule line. A rule in `AGENTS.md` is
what the next session obeys; the why-explanation under `.agents/docs/` is
what stops the session after that from re-opening a settled question. This
harness deletes the node instead of keeping a superseded record, which works
only if the graduation actually carries the reasoning across. A rule line
alone loses it, and then the question comes back.

## What a research file is not

- **Not a plan.** It writes no code. A research file whose diff touches
  anything but itself and its graduation target is a plan with the wrong
  frontmatter, and the review should say so.
- **Not a requirement.** Sessions file questions, never requirements
  ([`../product/README.md`](../product/README.md)).
- **Not an index.** There is no `./joharness.sh research`, no dashboard, no
  status field. The queue hook already lists these nodes; a second view is
  the stored-copy failure [`../graph.md`](../graph.md) forbids.

## An unrecorded method is a failed file

One instance carried `## Method: Not recorded` — two web-search passes whose
queries were not kept, so its findings could not be re-run as written. It
predated this rule, and the section naming it said so rather than
reconstructing plausible queries after the fact, which would read as a record
and be a guess.

It closed by re-running the sources with the queries kept, because a
graduation resting on unreproducible findings inherits that. The re-run also
caught what an unreproducible method hides: two of the file's own counts did
not reproduce, and one of them reproduces at no commit in this repo's
history. The findings were sound; the numbers beside them were not, and
nothing had ever re-run them.

So the rule, with the instance closed: a NEW research file with an unrecorded
method is a research file that failed. Its findings may still be right, and
nobody will ever be able to tell.
