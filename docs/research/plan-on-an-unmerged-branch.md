---
research: plan-on-an-unmerged-branch
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/orchestrated.md
---

<!--
Issue #297, with its second instance in the issue's own comment. Reported
from a consumer by the route `.claude/commands/upstream-report.md` names;
canonical decides. The fleet measurements are about a live orchestrated run
and could not be taken here. The claims about what the queue reads were read
from this repo's source at `cb0028e`.
-->

## Question

How should the queue reach a plan file that exists only on an unmerged branch,
given that the one reader scheduling work reads the base branch and nothing
else?

## Echo

A manager that finds a second defect behind the one it fixed is told to file it
separately rather than widen its pull request. Filing means a plan file, and a
plan file arrives on a branch. Until that branch merges, the plan is in no tree
the queue reads — so the item exists, is written, is marked urgent, and is
invisible to the only role that could staff it.

What I am asking is narrower than "make dispatch read branches". There are
three distinct shapes behind the two reported instances, and they do not have
one fix: a plan-only pull request (merging it is cheap and releases the plan),
a plan riding a product pull request that cannot merge soon (merging it is not
available, so the plan is stuck behind a check it did not break), and a plan
whose author has already exited (nobody is left to merge anything). What rests
on the answer is whether the queue gains a reader, the filer gains a last step,
or the orchestrator gains a documented route — and only the first covers all
three.

## Sweep

`goal-directed` — enough to decide which of the three fix shapes covers which
instance, and what a reader of unmerged branches would cost in false rows. Not
a survey of queue sources, and not a proposal to move the queue off the base
branch.

## What would settle it

- **A count of the shapes, from real history rather than from the two
  instances.** How often does a plan file first appear on a branch whose own
  pull request is not a plan-only one? `git log --diff-filter=A` over
  `docs/plans/` across unmerged refs answers it, and the answer decides whether
  "the filer merges its own plan pull request" is a fix or a half-fix.
- **What a reader of unmerged branches costs in wrong rows.** The queue's
  existing readers of branch state (`dispatch_retired_edges`,
  `dispatch_rescope_branches`) both drop merged refs and read files AT the
  branch; a plan reader would share that walk. The risk is the opposite of the
  current defect: a plan listed from a branch that is abandoned, or listed
  twice while its author also holds it. Settled by saying which of the existing
  walks it joins and what it does with a plan whose branch is also its holder.
- **Whether the row may carry an instruction at all.** A plan not on the base
  branch is not claimable by a spawn — there is nothing for a manager to read
  until the branch is in hand. So the row is either informational (name the
  pull request, let the orchestrator report it) or it carries the
  `source_revision` route, which spawns a manager against someone else's
  branch. Those are different amounts of authority and the issue offers both.

Either answer closes this: a reader is specified with its row shape and what it
refuses to say, or the answer is that the base branch stays the only queue and
the filer's last step is to merge its own plan pull request — in which case the
plan-riding-a-product-PR shape is named as an accepted gap rather than left to
be rediscovered.

## Method

Source reads at `cb0028e`, each re-run rather than taken from the issue:

    grep -n "BASE_BRANCH\|origin/" .agents/harness/queue-context.sh | head -20
    sed -n '74,80p'  .agents/harness/queue-context.sh
    grep -cn "gh api\|gh pr\|api.github" joharness.sh
    sed -n '7937,7988p' joharness.sh          # dispatch_rescope_branches walk
    git grep -in "source_revision"       # zero AT cb0028e, not at this head
    sed -n '500,516p' .claude/commands/orchestrate.md   # the spawn's fields

Not yet run, and what would settle the first bullet above. Written in the
shape `joharness.sh:7951-7956` prescribes and NOT the pipe form — refs into a
variable first, every inner git reading `</dev/null` — because *"the pipe form
… lets the inner git inherit the pipe as stdin and consume ref lines — a race
that dropped or duplicated refs run to run"*. An earlier draft of this block
was the pipe form, which the independent reader caught as the exact trap a
finding below quotes:

    refs="$(git for-each-ref --format='%(refname)' refs/remotes/origin </dev/null)"
    while IFS= read -r r; do
      [ -n "$r" ] || continue
      git log --diff-filter=A --format="%H $r" "origin/main..$r" \
        -- docs/plans </dev/null
    done <<<"$refs"

## Findings

- **The queue's ITEMS are read from one ref, and the fallbacks are not other
  branches.** `cb0028e`, `.agents/harness/queue-context.sh:67` sets
  `BASE_BRANCH="${HANDOVER_BASE_BRANCH:-main}"`, and lines 73-76 pick the ref:

      # The queue lives on the base branch. Prefer the remote view (just fetched),
      # fall back to a local base branch, then to HEAD for a repo with no remote.
      ref=""
      for candidate in "origin/${BASE_BRANCH}" "${BASE_BRANCH}" HEAD; do

  The comment says what the fallbacks are for, and it is not other branches. So
  a plan on an unmerged branch is outside the ITEM scan by construction, and the
  row the orchestrator needs cannot exist — the item is not free, not held, not
  in flight, because it is not there.

- **But the hook is NOT a single-ref reader, and the correction matters for
  where a fix goes.** An earlier draft of the finding above said the queue is
  read from `origin/<base>` *"and from nowhere else"*; the independent reader
  refuted it in the same file. `queue-context.sh:182-200` already walks every
  branch — `git for-each-ref … refs/remotes`, skipping `origin/HEAD` and the
  base branch, dropping merged refs via `ref_merged`, then reading each
  workstream file AT the branch with `git show "${short}:${wf}"`, and comparing
  the blob against the base's so an inherited file is not counted as this
  branch's claim. That is a third branch walk beside `dispatch`'s two, it is in
  the hook itself, and it is the most natural place for a plan-on-a-branch row
  to live: the machinery, the merged-ref skip and the inherited-file trap are
  all already there. What is single-ref is the ITEM scan, not the reader.

- **Nothing in the scheduler can see a pull request.** `grep -cn "gh api|gh
  pr|api.github" joharness.sh` returns **0** at `cb0028e`. So "list open pull
  requests whose diff is only under `docs/plans/`" — the issue's first option —
  cannot be implemented the way it is phrased. What IS available is the ref
  walk two of dispatch's own readers already run: unmerged `refs/remotes/origin/*`,
  files diffed against the merge base, read at the branch
  (`dispatch_rescope_branches`, `dispatch_retired_edges`). A plan reader would
  be a third consumer of that walk and would see plan files, not pull requests.
  This matters for the fix's shape: the row can say "a plan exists on branch X
  and not on the base branch", and cannot say whether a pull request is open
  for it.

- **The two existing walks already carry the pieces such a reader needs.**
  `cb0028e`, `dispatch_rescope_branches`: refs collected into a variable before
  the loop (the pipe form raced and dropped refs), merged refs dropped by
  `merge-base --is-ancestor`, no merge base = skip, files read with
  `git show "${r}:${wf}"` so a branch's own version is read rather than the
  base's, and every inner git reads `</dev/null`. Four traps already paid for.

- **Reported, not re-measured here: instance one, the plan-only pull
  request.** A plan opened as its own pull request on 2026-10-07T17:26:40Z,
  frontmatter `urgency: urgent, agent: sonnet, effort: low`, one file,
  `+142/-0`. The fix it described was three names in one test file; the base
  branch's check stayed red throughout. **6h09m** from the pull request opening
  to a manager existing for it, and it moved only when a human asked about the
  failed check. Nine other pull requests merged in that window. Every
  orchestrator pass in between carried the same line: *"merge PR … — human's"*,
  cut where it named that repository's own pull request number.

- **Reported, not re-measured here: instance two, and it widens the shape.**
  About an hour later in the same run (2026-10-08), the base branch's check
  failed at a new step. At 00:55Z the orchestrator, finding no plan for it,
  spawned a manager to read the failure and write the plan. At 00:58:33Z — three
  minutes later — a different manager commented that it had already found that
  failure and filed it as a plan, pushed on ITS branch. That branch's own pull
  request could not merge: its check failed on a base it did not break. So
  "merge the filer's pull request" would not have released this one, and the
  duplicate spawn was already paid for. The orchestrator reports it could not
  reach the second manager to ask: the messaging tool listed no row for cloud
  sessions, which is the degradation `orchestrate.md`'s optional-tools table
  already describes.

- **The route used by hand is named NOWHERE in the harness.**
  `git grep -in "source_revision"` **at `cb0028e`** returns **zero** hits in
  the whole tree — re-run against any tree carrying this node it returns this
  node's own lines and nothing else, which is why the commit is named; the spawn block enumerates its fields and carries `source_url`,
  `model`, `title` and `prompt` only, with `source_url` explained by the
  failure that bought it (*"attempt one spawned without it and both sessions
  asked for a clone"*). So the orchestrator that used `source_revision`
  reached past the block for a tool parameter the block does not list — which
  makes the issue's third option *"document the route used here"* its most
  literal reading, not its weakest. Reported, not re-measured: that is what
  the consumer's orchestrator did at 23:35Z, telling the manager to cut its
  own work branch so its pull request carries the plan to the base branch. The
  outcome of that route was not known when the issue was filed.

## Consequence for the queue

No plan is blocked on this and none carries a `research:` edge to it.

The answer changes what the orchestrator does with a report line it currently
cannot act on, so it lands beside the mode's other measured costs rather than
in a plan on its own. Three cautions for whoever takes it:

- **The first option as phrased is not buildable.** The scheduler makes no
  GitHub call and a pull request is not visible to it. Re-read it as "plan
  files present on unmerged branches and absent from the base branch" before
  costing it.
- **The second option does not cover instance two**, and instance two is the
  one that cost a duplicate manager. A fix that stops at "the filer merges its
  own plan pull request" should say so in the same breath.
- **The third option spawns a manager onto a branch somebody else owns.** That
  is more authority than any current row carries, and it is the one option that
  needs a bound written before it is offered — what happens when both the
  spawned manager and the branch's owner reach `finish`.

Note for a parallel wave: a research node has no `scope:`, so the overlap guard
cannot see that an answer here and an answer to `rescope-re-offered-after-merge`
would both land in `dispatch`'s branch walks. Taking both at once collides.

## Verification

Second context: `.claude/agents/verifier.md` at opus, which re-ran every
Method command against source rather than reading the quotations here.

- **The queue's ITEM scan reads one ref** — GROUNDED.
- **"and from nowhere else" was FALSE of the reader** — UNGROUNDED, by the second
  context, and the correction is now a finding of its own.
  `queue-context.sh:182-200` is a third branch walk, in the hook itself. The
  reader also caught that the quoted code block spliced line 67 onto 75-76 and
  dropped a two-line comment, against `.agents/docs/caveman.md`
  `## Never touch`; the block is now the real lines with the comment.
- **The scheduler makes no GitHub call** — GROUNDED, `0` re-counted.
- **`source_revision` is named nowhere at `cb0028e`** — GROUNDED, and now
  pinned to that commit: the command returns this node's own lines in any tree
  carrying it.
- **The two existing walks carry the pieces a reader needs** — GROUNDED, and
  the reader found this file's own proposed command written in the pipe form
  those walks exist to avoid. Rewritten in the prescribed shape.
- **Both reported instances, their times and counts** — WEAK.

Standing limit on every claim below that came from the issue rather than from
this tree: `.claude/agents/verifier.md` declares `tools: Read, Grep, Glob,
Bash` and has no control-plane call, so a reported fleet reading can be
re-read against the issue and never re-sampled. That is issue #267, planned as
`docs/plans/verifier-cannot-read-the-plane.md`. Every such claim is marked
WEAK for that reason and not because anything contradicted it; the second
context did confirm each number against the issue it came from, and found no
invented one anywhere in this batch.

## Graduates to

`.agents/docs/orchestrated.md` — the file that already carries what this mode
measured and what it cost, including the run where the fleet sat overlap-bound
with free slots. "The queue cannot see an item that exists" is the same kind of
fact about the same mode, and the rule it implies (a row in `dispatch`, a last
step in `manage.md`, or a bounded `source_revision` route in `orchestrate.md`)
is a one-line consequence of it. Writing the rule without the why is how the
option that does not cover instance two gets built twice.
