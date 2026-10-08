---
research: an-injection-live-under-a-dispatched-reader
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/subagents.md
---

## Question

Which file must carry the rule that a working-tree mutation and a dispatched
read-only reader are mutually exclusive, given that Loop step 5 orders both
and the harness layer carries no discipline about either?

## Echo

A consumer (`chrsctl/gx`) dispatched `.claude/agents/verifier.md` and, while
it was live, ran a defect-injection script over a file the verifier was
reading. The verifier ran the suite, saw it red, and reported the injected
defect as a defect in the diff. Nothing was committed wrong: that consumer's
own rules already forbid an injection live across a commit, and they held.

What I am being asked is not whether the reader was wrong — it read the tree
it was given, correctly. It is where the rule that prevents it BELONGS, and
that is a real question rather than a drafting detail, because the shape has
two ends and they are owned by different files. The spawning session can be
told not to move the tree while a reader it dispatched is alive. The reader
can be told to state, or to pin, the tree it measured. Those are different
rules with different failure modes, they live in different files, and one of
them may be enough.

What rests on it: every review this harness performs goes through a subagent
sharing the parent's container and the parent's checkout, and step 5 also
orders the parent to revert its own fix and put it back. The collision is not
a consumer's local habit. It is in the harness's own instructions.

## Sweep

`goal-directed`. Enough to decide which file owns the rule and whether the
harness already says it somewhere. NOT a survey of defect-injection practice,
and NOT the consumer's own injection rules, which are that consumer's and
already written.

## What would settle it

Set before any grep ran:

1. **Does the harness already say it?** Any rule, in any harness-owned file,
   about the state of the tree a dispatched reader reads. One hit and this
   question is a pointer, not a node.
2. **Does the harness ORDER the collision, or merely permit it?** If step 5
   orders a tree mutation and a dispatched reader with no ordering between
   them, the rule is harness-owned. If injection is only ever a consumer's
   practice, the rule may belong in the consumer and this node closes as
   `none`.
3. **Which existing rule is nearest, and what exactly does it not cover?** A
   rule one clause away gets the clause. A rule in a different file about a
   different actor needs a home of its own.
4. **What does the reader-side version cost the reader?** A verifier told to
   pin a sha cannot re-run claims about the working tree it was spawned to
   review, which is its whole job. If the reader-side rule disarms the
   reader, the dispatch-side rule is the answer by elimination.

Each is decidable by reading harness-owned text, so the answer does not
depend on anyone's judgement about how likely the collision is.

## Method

```bash
grep -rn -i 'inject' .agents/harness/ .claude/ .agents/docs/
grep -n -i 'working tree|tree state|inject|committed sha|uncommitted' \
  .agents/docs/feedback.md .agents/docs/subagents.md \
  .agents/docs/agent-selection.md .agents/harness/AGENTS.md AGENTS.md
grep -n 'revert the fix' .agents/harness/AGENTS.md
grep -n -i 'disjoint|tree|read-only|verifier' .claude/commands/manage.md
cat .claude/agents/verifier.md .agents/docs/subagents.md
```

All at `a907ef6b`. The consumer's record, read rather than summarized:

```bash
git show 9c69b8e9:docs/handover/crm-c4-registry-agreement-after-512.md
sed -n '1085,1175p' AGENTS.md      # in chrsctl/gx, read-only clone
```

This session also ran the candidate under test: the verifier for this branch
was spawned with no edit of mine in flight, and nothing in the tree moved
until it was dead rather than reported. Recorded as a cost in the findings,
not as a measurement of the rule's value.

## Findings

- **The harness layer carries no injection discipline at all.** `grep -rn -i
  'inject' .agents/harness/ .claude/ .agents/docs/` returns the session-start
  context injection, `hook-injected state` in `agent-selection.md:174`, and
  selftest fixtures using `INJECTED` as a string. Nothing about injecting a
  defect, and so nothing an added clause could sit beside. This is the fact
  that makes the consumer's own candidate — a graduation to
  `.agents/docs/feedback.md` — land in a file with no neighbouring rule to
  extend.
- **Step 5 orders both halves of the collision, in one step, with no order
  between them.** `.agents/harness/AGENTS.md:123`: *"Test written for a fix
  must FAIL without it: revert the fix, run the test, put it back."* And
  `:92`-`:93`: *"Every depth also spawns `.claude/agents/verifier.md`"*. A
  session obeying both literally reverts its fix in the shared checkout while
  the reader it is required to spawn is reading that checkout. The consumer
  reached this through its own injection script; the harness reaches it
  through its own prescribed revert, which every session that writes a test
  for a fix performs.
- **The nearest harness rule is about workers, not about the manager's own
  hands.** `.claude/commands/manage.md:66`: the files a worker may touch are
  *"disjoint from every other worker running at the same time; a shared file
  = sequential, one worker after another"*. Worker against worker. The
  verifier is spawned eleven paragraphs later (`:152`) and is not in that
  set — it touches no files — and the manager's own edits are not in it
  either. So the harness has a concurrency rule for the one pair where both
  parties write, and none for the pair where one writes and one measures.
- **The verifier's brief points it at the live checkout and never says the
  checkout can move.** `.claude/agents/verifier.md` tells it to *"Re-run
  claims about the repository's own state, with commands YOU compose against
  the checkout"*, and acknowledges the shared container in the one place it
  matters for execution safety: *"You share a container with the session that
  spawned you."* Both sentences are correct and neither carries a tree. The
  reader is told to measure, told what not to run, and told nothing about
  WHEN what it measures is the diff.
- **`subagents.md` already owns the premise and stops one sentence short.**
  It states *"All of them share the parent's container"*, lists **Review**
  as the first thing to use a subagent for, and says a subagent gets no hook
  state so *"the spawn prompt is the only channel"*. One shared mutable tree,
  one reader that cannot be told anything after it starts. The conclusion is
  absent.
- **The consumer's four escalations are all commit-side, and the fourth names
  the direction this one comes from.** In `chrsctl/gx`'s `AGENTS.md`: *"Never
  stage while a job that edits the tree is running"* (ADR 0131 r18); *"do not
  commit a file while any job that edits it is alive, and check that it is
  dead rather than that it has reported"* (ADR 0145 r13); *"an injection is
  never live across a commit"*, so *"Commit BEFORE injecting"* (ADR 0173 r9);
  and a manager's rule to diff every worker-touched path against `HEAD` and
  read a DELETED line as the alarm. Every one protects a COMMIT from a job
  that EDITS. The last closes with *"And `do not commit` in a worker prompt
  has not said `do not inject in the background`"* — the same class of
  omission, one actor over. A reader that writes nothing cannot be reached by
  any of the four, because nothing it does is a commit and nothing it touches
  is a file it edits.
- **The reader-side rule cannot be "measure a committed sha" without
  disarming the reader.** The verifier exists to review an uncommitted diff
  at step 5, before the edge; `git worktree add --detach` at a sha gives it a
  tree that does not contain the work under review. A reader-side rule can
  therefore only be *state the tree you measured* — which turns a wrong
  attribution into a traceable one and does not prevent it — or *re-measure
  before reporting*, which is a second run, not a rule. The preventive
  version has to bind the party that moves the tree.
- **Obeying the dispatch-side candidate cost this session one idle wait and
  no work.** This branch's verifier was spawned with nothing of mine in
  flight and the tree held still until it was dead. The cost of the rule, for
  a session whose edits are not themselves the measurement, is serialization
  of work it was not doing in parallel anyway. Not evidence that the rule is
  right; evidence that its price is small for the common case, and no
  evidence at all about a session mid-injection, which is the case that
  earns the rule.

## Consequence for the queue

No plan changes, and no plan is blocked. Nothing in `docs/plans/` names the
verifier's dispatch or a tree-state rule.

What the answer changes is which file a one-line rule lands in, and the
candidates differ in who they bind:

- **A. Dispatch-side, in `.agents/docs/subagents.md`.** An injection or a
  revert and a dispatched reader are mutually exclusive: mutate before you
  spawn, or after it is DEAD rather than reported. Binds the only party that
  can prevent the wrong attribution, inherits ADR 0145 r13's dead-not-
  reported distinction, and lands in the file that already states the shared
  container and the review use. Cost: a rule in a page that is a reference
  table, not a Loop step, so a session that never opens it never meets it.
- **B. Reader-side, in `.claude/agents/verifier.md`.** State the tree you
  measured; a red you did not produce from the diff is a finding about the
  tree, not about the diff. Reaches the reader through the one channel it
  has, and makes the failure legible instead of absent. Measured above not to
  prevent it, and a verifier that measures a committed sha cannot review the
  diff it was spawned for.
- **C. The Loop, at step 5.** One clause beside *"revert the fix, run the
  test, put it back"*, which is the sentence that orders the mutation. Every
  session meets it. Cost: `AGENTS.md` is the caveman file, and this is the
  step that already carries the most.
- **D. `.agents/docs/feedback.md`**, the consumer's own candidate and a
  graduation it names. Measured to have no neighbouring rule — nothing in
  that file is about tree state or about injection — so the clause would
  arrive as a new topic in a page about what a recorded finding is for.
- **E. Nowhere: the consumer's own AGENTS.md.** The collision was reached by
  an injection script, which is that consumer's practice and not the
  harness's. Refuted as stated by finding 2 — step 5's revert reaches it with
  no script at all — but it survives in a weaker form: the harness rule could
  be A alone, leaving injection practice to the consumers that do it.

A and C are the same rule in two homes, and the pair A+B is not redundant:
one prevents, the other makes a prevention failure legible. D and E are
answerable from the findings above; A-versus-C is a placement decision, and
whoever takes this closes it rather than writing both.

## Verification

Checked by a verifier subagent at this branch's tier, from a context that did
not run the greps, given the harness files and the consumer's record and
asked to re-run every citation. Findings tagged `(verifier)` in the workstream
file's `## Review`, recoverable per the pull request body.

- "The harness layer carries no injection discipline": **GROUNDED**, one grep
  over three directories, every hit enumerated above rather than counted.
- Every quotation with a file and line (`AGENTS.md:123`, `:92`-`:93`,
  `manage.md:66`, `:152`, `agent-selection.md:174`): **GROUNDED**, each read
  in place.
- The consumer's own record and its four escalations: **GROUNDED** in
  `chrsctl/gx` at `9c69b8e9` and `AGENTS.md:1085`-`1175`, read in a read-only
  clone. The ADR numbers are as that file cites them; the ADRs themselves
  were not opened, so "ADR 0145 r13 says X" is **WEAK** beyond what the
  AGENTS.md paragraph quotes.
- "The verifier cannot be told to measure a committed sha": **GROUNDED** in
  what step 5 spawns it for — an uncommitted diff — and in its own brief.
- Whether A alone would have prevented the consumer's incident: **WEAK**. The
  consumer says it ran the script *knowing the verifier was live*, so A
  states a rule it would have broken knowingly; nothing here measures whether
  a stated rule changes that.
- The price of A, from this session: **GROUNDED** for one run of one reader
  with no injection in flight, and **UNGROUNDED** as a general cost.

## Graduates to

`.agents/docs/subagents.md` — declared as the dispatch-side home, because it
is the page that already carries the two facts the rule rests on (one shared
container, one spawn prompt as the only channel) and the use that collides
with them (review). If the answer is B or C, the graduating pull request moves
the target; the declaration is not the finding. The why-explanation goes with
it either way: a rule line saying "do not mutate while a reader is live" with
no record of the wrong attribution it prevents is a rule the next session
reads as caution and routes around.
