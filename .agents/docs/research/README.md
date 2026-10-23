# Research queue

Open questions with the standing of a plan. One file per question, under
`docs/research/`, on `main`. `dispatch` lists them beside plans, same
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

Copy [`TEMPLATE.md`](TEMPLATE.md). Nine sections, in order.

Both names are in use and both stay. A **research file** is the node — what
the graph, the lint and this page call it. **Open questions** is the queue
hook's label for the same files, because that is what a session reading the
hook is being offered. No glossary row: the two are not rival spellings of
one term, and a substring ban on either would fire on prose that is correct.

### What makes a file a node

`docs/research/` may also hold plain reference documents — prose a session
wrote that is not a scheduled question. This is the one queue directory
with that split: `docs/plans/` and `docs/handover/` hold nothing but nodes,
and a frontmatter-less file there is malformed, not exempt.

Which side a file falls on is decided by ROUTING, spelled out under "Which
files are nodes" below. A consumer synced before this protocol carries
research prose with no frontmatter at all, and routing leaves those files
alone with no edit — where a required opt-out marker would red every one
until a human touched it.

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
  It is the hop a plan reader acts on.
- **Verification** — see below.
- **Graduates to** — the file the answer lands in.

Frontmatter: `research` (the stem), `urgency` (`normal` | `urgent`), `agent`
(`haiku` | `sonnet` | `opus` | `fable`), `effort`, `graduates` (the file the answer
lands in). The tier the queue prints comes from `agent`, same as a plan's.

## Which files are nodes

Routing decides. A file under `docs/research/` is a NODE when the graph
routes through it — either of:

- it carries a `research:` key (self-names; a value naming a DIFFERENT
  file is a typo and red, never a document — a key that exists is intent);
- an open plan's `research:` edge names its stem. A node a plan waits on
  cannot leave the queue by dropping its frontmatter: the reference alone
  keeps it a node, and its missing keys go red.

Neither = a DOCUMENT. Consumers keep their own domain documents under
`docs/research/` from before this protocol existed; those lint green, are
never listed as open questions, and never block or get scheduled.
`joharness.sh:lint_graph` and `queue-context.sh` apply the identical test —
one rule, two readers.

An unreferenced node cannot escape by omission either: a file whose own
history carried `research: <stem>` and whose tree no longer does was a
node — DECAYED, red until the frontmatter is restored or the file is
deleted. `./joharness.sh cleanup` counts documents and decayed nodes the
base branch already carries.

Known limits: a rename that drops the frontmatter in the same change defeats
the history check, and a shallow checkout that finds no removal says nothing
(blind is not zero). The full-history run is the gate.

In the canonical repo a plain document here is warned: consumers keep
documents in this directory legitimately, canonical keeps only nodes.

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

The failure the section exists to catch: a search result that echoed the
researcher's own phrasing back, recorded as a second source. It
corroborates nothing.

**A reading the reviewer cannot take.** The verifier
(`.claude/agents/verifier.md`) has `Read`, `Grep`, `Glob` and `Bash`: this
checkout and commands in this container, no control-plane call. A claim
resting on a reading outside this checkout that no command there re-takes —
a session record above all — is one it can only check for internal
consistency. It says so, and marks the claim UNVERIFIED; in the node that is
WEAK at best, never GROUNDED. So a node whose evidence is such a reading
names its second context UP FRONT, in `## Method`, not at verification time.
Two honest answers exist: the operator takes the reading, or a session
tooled for it does. "The verifier did it" is neither.

**Who checked, and from where. Never when.** Provenance is commits
([`../graph.md`](../graph.md) Rules, "never hand-write time into a file"),
and a hand-written date is a second copy of what `git log` already knows —
wrong the first time somebody edits the file without touching the date.

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

Write the WHY-EXPLANATION, not only the rule line: a rule in `AGENTS.md` is
what the next session obeys; the why under `.agents/docs/` stops the session
after that re-opening a settled question. A rule line alone loses it.

## What a research file is not

- **Not a plan.** It writes no code. A research file whose diff touches
  anything but itself and its graduation target is a plan with the wrong
  frontmatter, and the review should say so.
- **Not a requirement.** Sessions file questions, never requirements
  ([`../product/README.md`](../product/README.md)); a scout proposes on
  GitHub issues and a human writes the requirement
  ([`../orchestrated.md`](../orchestrated.md), Bounds).
- **Not an index.** There is no `./joharness.sh research`, no dashboard, no
  status field. The queue hook already lists these nodes; a second view is
  the stored-copy failure [`../graph.md`](../graph.md) forbids.

## An unrecorded method is a failed file

A NEW research file with an unrecorded method is a research file that
failed. Its findings may still be right, and nobody will ever be able to
tell.
