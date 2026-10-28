# Research queue

Open questions with the standing of a plan. One file per question, under
`docs/research/`, on `main`. `dispatch` lists them beside plans, same
ordering — oldest actionable first, urgent first if marked. A plan blocked on
an open question already drops out of the entrypoint; that is rank enough.

The node exists so a finding outlives the session that made it: a session that
researches, acts, and ends leaves nothing behind but a diff, and the next one
re-opens the same question. How to research is a session's business; that the
answer survives is the harness's. A **research file** is the node; **open
questions** is the queue hook's label for the same files.

## Shape

Copy [`TEMPLATE.md`](research/TEMPLATE.md). Nine sections, in order:

- **Question** — one sentence, answerable. No evidence could settle it = a
  topic, and a topic never closes.
- **Echo** — the question restated in the researcher's words before any method
  runs; the cheapest place to catch a misread.
- **Sweep** — `comprehensive` or `goal-directed`, named: what "complete"
  means. Unnamed, the question never closes.
- **What would settle it** — written BEFORE the method runs; written after, it
  describes what was found.
- **Method** — the commands, web queries quoted.
- **Findings** — each with the command or source that produced it.
- **Consequence for the queue** — which plan changes, how, or none.
- **Verification** — below.
- **Graduates to** — the file the answer lands in.

Frontmatter: `research` (the stem), `urgency` (`normal` | `urgent`), `agent`
(`haiku` | `sonnet` | `opus` | `fable`), `effort`, `graduates`.

## Which files are nodes

`docs/research/` may also hold plain reference documents; `docs/plans/` and
`docs/handover/` hold nothing but nodes. ROUTING decides: a file is a NODE
when either:

- it carries a `research:` key (self-names; a value naming a DIFFERENT file is
  a typo and red — a key that exists is intent);
- an open plan's `research:` edge names its stem. A node a plan waits on
  cannot leave the queue by dropping its frontmatter: its missing keys go red.

Neither = a DOCUMENT: lints green, never listed, never scheduled.
`joharness.sh:lint_graph` and `queue-context.sh` apply the identical test. A
file whose own history carried `research: <stem>` and whose tree no longer
does is DECAYED — red until the frontmatter is restored or the file deleted.
`./joharness.sh cleanup` counts documents and decayed nodes the base already
carries. Known limits: a rename that drops the frontmatter in the same change
defeats the history check, and a shallow checkout that finds no removal says
nothing (blind is not zero). The full-history run is the gate. In the
canonical repo a plain document here is warned: canonical keeps only nodes.

## Verification is not optional

A finding nobody checked from a second context is not settled.
[`../graph.md`](graph.md) Rules states the diamond rule; research is where
it bites hardest, since a model cannot reliably audit its own grounding. A
subagent is the cheap second context ([`../subagents.md`](subagents.md)).

An echoed search result, recorded as a second source, corroborates nothing.

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
([`../graph.md`](graph.md) Rules); a hand-written date is a second copy.
Mark each claim **GROUNDED**, **WEAK** or **UNGROUNDED**; a refuted claim
needs a word a grep finds.

## Edges

`research:` on a PLAN names an open question it waits on: blocked while
`docs/research/<question>.md` exists, free once deleted (file existence IS the
state, as `needs`). `graduates:` on a RESEARCH file names where the answer
goes, completed by the merge that deletes the file (the `graduated` edge,
[`../graph.md`](graph.md)). Both single-hop.

## Graduating

The pull request that closes a question deletes the research file and writes
the answer into the file `graduates:` named. Write the WHY-EXPLANATION, not
only the rule line: a rule in `AGENTS.md` is what the next session obeys; the
why under `.agents/docs/` stops the session after that re-opening a settled
question.

## What a research file is not

- **Not a plan.** It writes no code. A diff touching anything but the file and
  its graduation target is a plan with the wrong frontmatter.
- **Not a requirement.** Sessions file questions, never requirements
  ([`product.md`](product.md)); a scout proposes on
  GitHub issues and a human writes the requirement
  ([`../orchestrated.md`](orchestrated.md), Bounds).
- **Not an index.** There is no `./joharness.sh research` or dashboard; a
  second view is the stored-copy failure [`../graph.md`](graph.md) forbids.

A NEW research file with an unrecorded method failed: its findings may be
right, and nobody can tell.
