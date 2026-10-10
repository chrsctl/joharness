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
and the harness's own mutation tool is disciplined only about the tree it
leaves behind?

## Echo

A consumer dispatched `.claude/agents/verifier.md` and, while it was live,
ran a defect-injection script over a file the verifier was reading. The
verifier ran the suite, saw it red, and reported the injected defect as a
defect in the diff. Nothing was committed wrong: that consumer's own rules
already forbid an injection live across a commit, and they held.

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
orders the parent to revert its own fix and put it back. So the collision is
not a consumer's local habit — it is in the harness's own instructions, and
the harness ships a command that performs exactly that revert.

## Sweep

`goal-directed`. Enough to decide which file owns the rule and whether the
harness already says it somewhere. NOT a survey of defect-injection practice,
and NOT the consumer's own injection rules, which are that consumer's and
already written.

## What would settle it

Set before any search ran:

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
4. **What does the reader-side version cost the reader?** If a verifier told
   to pin a tree cannot re-run claims about the work it was spawned to
   review, the reader-side rule disarms the reader and the dispatch-side rule
   is the answer by elimination. If it can be pinned, both ends are live and
   the question is a placement decision, not an elimination.

Each is decidable by reading harness-owned text, so the answer does not
depend on anyone's judgement about how likely the collision is.

## Method

```bash
grep -rn -i 'inject' .agents/harness/ .claude/ .agents/docs/
grep -rnEi 'mutat' .agents/harness/ .claude/ .agents/docs/ joharness.sh AGENTS.md
grep -rn 'mutate' .agents/harness/AGENTS.md AGENTS.md .claude/commands/*.md \
  .claude/agents/*.md .agents/docs/*.md
grep -n -i 'working tree\|tree state\|inject\|committed sha\|uncommitted' \
  .agents/docs/feedback.md .agents/docs/subagents.md \
  .agents/docs/agent-selection.md .agents/harness/AGENTS.md AGENTS.md
grep -nEi 'tree|diff against|merge base' .agents/docs/feedback.md
grep -n 'revert the fix' .agents/harness/AGENTS.md
grep -n -i 'disjoint\|tree\|read-only\|verifier' .claude/commands/manage.md
sed -n '9333,9415p' joharness.sh
cat .claude/agents/verifier.md .agents/docs/subagents.md
```

The `-i 'a\|b'` spellings are BRE with escaped alternation, which is what ran.
An unescaped `'a|b'` without `-E` matches a literal pipe and returns nothing;
the verifier of this node ran the earlier draft's unescaped form verbatim and
got exit 1, which is how the corrected spellings got here.

The consumer's record, read rather than summarized, in a read-only clone:

```bash
git show 9c69b8e9:docs/handover/crm-c4-registry-agreement-after-512.md
sed -n '1085,1175p' AGENTS.md
```

This node ran its own candidate A: the verifier for this branch was spawned
with nothing of mine in flight, and nothing in the tree moved until it was
dead rather than reported.

## Findings

- **The harness ships defect injection as a command, and its whole discipline
  is about the tree it leaves behind, not about who else is reading.**
  `./joharness.sh mutate <file> <line> <text>` is Loop step 5's rule as a
  command — its header says so and quotes the AGENTS.md sentence verbatim
  (`joharness.sh:9333`-`:9336`). Its safety story is restoration:
  *"Restores the file whatever happens — a normal return, a failing suite, or
  ^C midway. A mutation left in the tree is worse than no tool: the next
  command reads a repo nobody edited on purpose"* (`:9354`-`:9356`), enforced
  by `trap mutate_restore EXIT INT TERM` (`:9409`). And it runs the suite
  twice with the defect live in the shared tree (`:9348`, `:9412`), which is
  precisely the window a dispatched reader misreads. The next command is the
  reader it protects; a concurrent one is not addressed. **This refutes the
  earlier draft of this finding**, which said the harness layer carries no
  injection discipline at all — it was graded GROUNDED on a search over
  `.agents/harness/`, `.claude/` and `.agents/docs/` that matched `inject`
  and never `mutate`, and never read `joharness.sh`.
- **No instruction file names `mutate`.** `grep -rn 'mutate'` over
  `.agents/harness/AGENTS.md`, root `AGENTS.md`, `.claude/commands/*.md`,
  `.claude/agents/*.md` and `.agents/docs/*.md` returns nothing. So the
  command carrying the discipline is reachable only by reading
  `joharness.sh`, and the sentence that orders the mutation (`AGENTS.md:123`)
  does not point at it. Whatever clause answers this question, a session
  meets the order and not the tool.
- **Step 5 orders both halves of the collision, in one step, with no order
  between them.** `.agents/harness/AGENTS.md:123`: *"Test written for a fix
  must FAIL without it: revert the fix, run the test, put it back."* And
  `:92`-`:93`: *"Every depth also spawns `.claude/agents/verifier.md`"*. A
  session obeying both literally reverts its fix in the shared checkout while
  the reader it is required to spawn is reading that checkout.
- **The nearest harness rule about concurrency is worker-against-worker.**
  `.claude/commands/manage.md:66`-`:67`: the files a worker may touch are
  *"disjoint from every other worker running at the same time; a shared file
  = sequential, one worker after another"*, and `:75` again — *"parallel
  across disjoint file sets"*. Both quantify over workers. The verifier is
  spawned later in the same file (`:152`) as *"a subagent too"* — the same
  category — but it touches no files, so a disjoint-FILES rule cannot bind
  it, and the spawning session's own edits are in neither set. So the harness
  has a rule for the one pair where both parties write, and none for the pair
  where one writes and one measures. That parenthetical at `:152` is also
  the nearest place a clause could attach.
- **`feedback.md` already carries a graduated rule of this class, which makes
  it a stronger home than the earlier draft priced.** `.agents/docs/feedback.md:145`
  is the section *"## Worked example: tree or diff"*, whose table counts
  eight edges paid to one question and whose rule reads *"a branch inherits
  every file its base branch carries, so presence in the tree says nothing
  about the branch. Ownership is a DIFF against the merge base"*
  (`:162`-`:163`). Loop step 4 points at it by name
  (`.agents/harness/AGENTS.md:77`-`:80`, *"Code asking whether a branch owns
  a file: DIFF against merge base, never read the tree … Six merged edges
  paid for this one"*). Same class — a reading taken from the mutable tree where the diff
  was the question — differing in the reading taken and in who takes it. The
  earlier draft said nothing in that file is about tree state; its grep
  matched `working tree` and `tree state`, and the section says *"reading the
  tree"*.
- **The verifier's brief points it at the live checkout, names that checkout
  as the boundary of what it can trust, and never says the checkout can
  move.** `.claude/agents/verifier.md:99`-`:100` tells it to *"Re-run claims
  about the repository's own state, with commands YOU compose against the
  checkout"*, and `:105` acknowledges the shared container in the one place
  it matters for execution safety: *"You share a container with the session
  that spawned you."* Since PR #325 it also carries `## What you cannot see`
  (`:64`-`:80`), which draws the line at *"this checkout, and commands run in
  this container"*, gives the boundary as *"outside this checkout"* (`:71`),
  and prescribes *"Check that nothing in the repository contradicts it"*
  (`:76`) for anything beyond it. So the brief now states twice that the
  checkout is the reader's ground, and a mutable checkout is not on the list
  of things it cannot see. Every sentence is correct and none carries a tree:
  the reader is told to measure, told what not to run, told what is out of
  reach, and told nothing about WHEN what it measures is the diff.
- **`subagents.md` already owns the premise and stops one sentence short.**
  It states *"All of them share the parent's container"* (`:37`-`:38`), lists
  **Review** as the first thing to use a subagent for (`:45`), says a
  subagent gets no hook state so *"The spawn prompt is the only channel"*
  (`:26`), and records that the Agent tool offers `isolation: worktree`
  (`:31`). One shared mutable tree, one reader that cannot be told anything
  after it starts, and the mechanism that would isolate it. The conclusion is
  absent.
- **The reader CAN be pinned, so neither end is eliminated.** The earlier
  draft argued a dispatched reader cannot be told to measure a committed sha,
  because step 5's diff is uncommitted and a detached worktree would not
  contain the work under review. Measured on this branch: all three files
  were committed at the sha the verifier was given, `git status --porcelain`
  empty, and the spawn prompt handed it `git diff main...HEAD` — so
  `git worktree add --detach <head>` would have contained the entire diff,
  and `subagents.md:31` offers the isolation as a spawn option. The harness
  also commits findings with their fixes (step 5), so a step-5 diff is
  normally committed. The elimination argument is gone: this is a placement
  decision between two live ends, which is what the question now asks.
- **The consumer's four escalations are all commit-side, and the fourth names
  the direction this one comes from.** In that consumer's `AGENTS.md`:
  *"Never stage while a job that edits the tree is running"*; *"do not commit
  a file while any job that edits it is alive, and check that it is dead
  rather than that it has reported"*; *"an injection is never live across a
  commit"*, so *"Commit BEFORE injecting"*; and a manager's rule to diff
  every worker-touched path against `HEAD` and read a DELETED line as the
  alarm. Every one protects a COMMIT from a job that EDITS. The last closes
  with *"And `do not commit` in a worker prompt has not said `do not inject
  in the background`"* — the same class of omission, one actor over. A reader
  that writes nothing is reached by none of the four: nothing it does is a
  commit and nothing it touches is a file it edits.
- **Obeying candidate A cost this branch one serialized wait.** This branch's
  verifier was spawned with nothing in flight and the tree held still until
  it was dead; the cost was work not done in parallel that was not going to
  be done in parallel anyway. No evidence that the rule is right, and none
  about a session mid-injection, which is the case that earns it. The
  sentence this replaces was written BEFORE that run and reported it in the
  past tense, which is the defect recorded as r1 in the workstream file.

## Consequence for the queue

No plan changes, and no plan is blocked. Nothing in `docs/plans/` names the
verifier's dispatch, `mutate`, or a tree-state rule.

What the answer changes is which file a one-line rule lands in, and the
candidates differ in who they bind:

- **A. Dispatch-side, in `.agents/docs/subagents.md`.** A mutation and a
  dispatched reader are mutually exclusive: mutate before you spawn, or after
  it is DEAD rather than reported. Binds the only party that can prevent the
  wrong attribution, inherits the consumer's dead-not-reported distinction,
  and lands in the file that already states the shared container, the review
  use and the spawn prompt as the only channel. Cost: that page is a
  reference table, not a Loop step, so a session that never opens it never
  meets it.
- **B. Reader-side, in `.claude/agents/verifier.md`.** State the tree you
  measured; a red you did not produce from the diff is a finding about the
  tree, not about the diff. Reaches the reader through the one channel it
  has, and makes the failure legible instead of absent. Measured not to
  prevent it — and no longer measured to disarm the reader, since the work
  under review is normally committed and `isolation: worktree` exists. Since
  PR #325 the file also has the section such a clause belongs in,
  `## What you cannot see`, whose own instance (issue #267) is the same
  failure one subject over: a reader that stays silent about a reading it
  could not take turns a known limit into a hidden one.
- **C. The Loop, at step 5.** One clause beside *"revert the fix, run the
  test, put it back"*, the sentence that orders the mutation. Every session
  meets it. Cost: `AGENTS.md` is the caveman file, and step 5 already carries
  the most.
- **D. `.agents/docs/feedback.md`**, the consumer's own candidate. Stronger
  than the earlier draft priced: that file already holds the graduated
  *"tree or diff"* worked example, eight edges of the same class, and Loop
  step 4 points at it. Cost: that example is about ownership reads, so the
  clause arrives as a second reading-the-tree lesson in a page about what a
  recorded finding is for.
- **E. `mutate`'s own header, or the command itself.** The one place in the
  harness that already performs the mutation, already owns a restore
  discipline, and already runs two suites inside the window. A refusal while
  a subagent is live would be the only candidate that is enforced rather than
  obeyed. Cost: nothing routes a session to it (finding 2), so it binds only
  sessions that use the tool, and a hand-rolled revert is unaffected.
- **F. Nowhere: the consumer's own AGENTS.md.** The collision was reached by
  an injection script, which is that consumer's practice. Refuted as stated
  by findings 1 and 3 — step 5's revert and the harness's own `mutate` reach
  it with no consumer script at all — but it survives in a weaker form: the
  harness rule could be A alone, leaving script practice to the consumers
  that do it.

A and C are the same rule in two homes. A+B is not redundant: one prevents,
the other makes a prevention failure legible. E is the only enforced option
and the least reachable. F and the old pricing of D are answerable from the
findings above; A-versus-C-versus-E is the placement decision, and whoever
takes this closes it rather than writing all three.

## Verification

Checked by `.claude/agents/verifier.md` at `opus`, this branch's tier
(`./joharness.sh review`), from a context that did not run the searches,
given the harness files and the consumer's record and asked to re-run every
citation and compose its own searches for the negative claim. Seventeen
findings returned; the six bearing on this node are answered in the
workstream file's `## Review`, tagged `(verifier)`. Three changed this node
materially: finding 1 was refuted and rewritten, finding 5 reversed a
candidate's pricing, and finding 8 replaced an elimination argument with a
placement one.

- Every quotation with a file and line — `AGENTS.md:123`, `:92`-`:93`,
  `:77`-`:80`, `manage.md:66`-`:67`, `:75`, `:152`, `verifier.md:64`-`:80`,
  `:99`-`:100`, `:105`, `subagents.md:26`, `:31`, `:37`-`:38`, `:45`,
  `feedback.md:145`, `:162`-`:163`, `joharness.sh:9333`, `:9348`,
  `:9354`-`:9356`, `:9409`, `:9412`: **GROUNDED**, each opened in place,
  by the verifier and again here after it reported.
- "The harness layer carries no injection discipline at all": **refuted**,
  and the finding rewritten. The verifier's own search
  (`grep -rnEi 'mutat' … joharness.sh`) is what reached `mutate`; mine
  matched `inject` and excluded `joharness.sh`. The replacement claim — that
  `mutate`'s discipline is restoration and not exclusion — is **GROUNDED**
  in the quoted header and the `trap`.
- "No instruction file names `mutate`": **GROUNDED**, one grep over the five
  instruction paths, zero hits.
- The reader-cannot-be-pinned premise: **refuted**, measured on this branch's
  own spawn (committed head, empty `git status --porcelain`, the diff the
  spawn prompt named) and against `subagents.md:31`.
- `feedback.md` having no neighbouring rule: **refuted**, and the candidate
  re-priced upward.
- The consumer's record and its four escalations: **GROUNDED** in that repo
  at `9c69b8e9` and its `AGENTS.md:1085`-`:1175`, read in a read-only clone.
  The ADR numbers are as that file cites them; the ADRs themselves were not
  opened, so anything beyond what those paragraphs quote is **WEAK**. The
  verifier could not reach that commit from this checkout, so every
  consumer-side citation here is unverified by it.
- Whether A alone would have prevented the consumer's incident: **WEAK**. The
  consumer's record says it ran the script knowing the verifier was live, so
  A states a rule it would have broken knowingly, and nothing here measures
  whether a written rule changes that.
- The price of A: **GROUNDED** for one run of one reader with no mutation in
  flight, **UNGROUNDED** as a general cost.

## Graduates to

`.agents/docs/subagents.md` — the dispatch-side home, because it is the page
that already carries the facts the rule rests on (one shared container, one
spawn prompt as the only channel, `isolation: worktree` as the escape) and
the use that collides with them.

Two things about that declaration, both recorded rather than resolved,
because the field is read mechanically and cannot hold a question. **It
selects candidate A.** The queue, `lint_graph` and `./joharness.sh graph`
read `graduates:` as a value, so this node arrives on the queue with A's
home already named while `## Consequence` leaves the placement open; every
other value would select some other candidate just as hard, and the key is
required. Whoever closes this moves the target if the answer is B, C, D or
E. **And the graduation hits a rule this file does not.**
`.agents/docs/consumer-repos.md:193`-`:212` bars a repository name, and a
consumer's plan and item names, from every shipping path — `.agents/docs/`
among them — while this node names a consumer because `docs/` is outside that
scope. The crossing prose cites the measurement instead: the command, the
commit, the counts.

The why-explanation crosses either way. A rule line saying "do not mutate
while a reader is live", with no record of the wrong attribution it prevents,
is a rule the next session reads as caution and routes around.
