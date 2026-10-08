# Feedback loops, and how to score one

A harness rule that never gets better is a rule that was guessed once. This
document: what a feedback loop is here, how to tell a good one from a busy
one, and what this repo's own history says when you count it.

Measure it yourself: `./joharness.sh feedback`. Every number below is counted
from git at read time, nothing stored. Trust counted numbers, never written
numbers — including the ones on this page, which were true on 2026-08-24 and
are re-derivable in two seconds.

## The four stages

A loop that improves anything has to clear four bars in order. Each one is a
place a loop dies quietly:

1. **Detect** — something notices the defect. (Review, CI, a gate.)
2. **Record** — the noticing survives the moment. (Findings in the workstream
   file's `## Review`.)
3. **Generalize** — one defect becomes a rule about a class of defects.
   (Graduation: `.agents/docs/handover/README.md`.)
4. **Prevent** — the rule reaches the next session before it repeats the
   defect, not after.

Stages 1 and 2 are cheap and visible, which is why most loops stop there and
still feel like loops. Stage 4 is the only one that changes an outcome.

Stage 4 has machinery here, not just a rule: `.agents/harness/pretool-feedback.sh`
is a PreToolUse hook that serves a file's recorded findings before Edit, Write
or NotebookEdit touches it, once per file per session. `./joharness.sh feedback
<path>` is the same report on demand, and the hook is what stops stage 4 riding
on somebody remembering to type it.

## Scoring

Four yields, one outcome. The yields diagnose; only the outcome scores.

| Number | Question | Where it comes from |
| --- | --- | --- |
| Coverage | Does the loop run at all? | merged edges recording a review / edges carrying a workstream file |
| Retention | Does its output survive? | findings a later session can reach without archaeology |
| Generalization | Did a finding become a rule? | review-fix commits touching an `AGENTS.md` or `docs/` rule file |
| Cost | What did it take? | commits per finding, churn peak per branch |
| **Recurrence** | **Did the same thing come back?** | **file-level fixes landing where another edge IN THE SAME WINDOW already fixed a finding** |

**Recurrence is the score. Everything else explains it.** A loop is good if
the same file stops drawing the same class of finding, and for no other
reason.

### It is scored over a window, and that is the whole of why it works

Cumulative recurrence is `1 - D/N`: every fix adds to `N`, while `D` — the
distinct paths that ever drew a finding — saturates, because a repo is
finite and only a handful of files draw findings at all. So it converges on
100% however well the loop works. "Want this falling" then describes
something the arithmetic forbids, and worse, it fights the hot-spot list
printed directly beneath it: a session that reads what earlier edges found
and fixes that file properly increments the numerator for doing exactly what
the harness told it to.

So recurrence is scored over the newest `JOHARNESS_RECURRENCE_WINDOW`
recorded edges (default 8), both sides of the ratio. A file that is read,
fixed and then left alone leaves the window and stops counting; a file that
keeps drawing findings stays. Now the printed advice and the printed score
point the same way, and the number falls exactly when rediscovery stops.

Why 8: measured on this repo, 2026-08-27, over 26 fix-carrying edges and 93
repeat events. The gap between one fix on a path and the next is median 2,
and 86% of repeats fall within 8 edges. 8 to 12 is a plateau that adds no
repeats; past it sits a separate far tail at 17+, which is a file being
central rather than a rediscovery. Widen it freely — but a number from one
window never compares to a number from another, which is the mistake this
section exists to stop.

Counted under the definition that ships, 2026-08-27: **9/28 (32%)** at the
default window, against **64/113 (56%)** cumulative over the same history.
Those are two different questions, not a fall.

### Volume is not a score

Counting findings and calling more of them better is the trap. The review
churn rule (`.agents/docs/agent-selection.md`) already establishes it from
measurement: finding counts are no signal, false in both directions — five
findings can be one real defect found five ways, and zero can be a review
nobody ran. A loop scored on volume optimizes for volume; the models under
this harness are literal enough to deliver exactly that.

Recurrence has the opposite property. It cannot be gamed by producing more
output, because producing more output is not what makes it fall.

That defence was aimed at the wrong failure mode while the measure was
cumulative: producing more output *on the files the harness points you at*
was precisely what made it rise. The window is what makes the claim true —
output on a file nobody has touched inside the window does not score.

## Measured here (2026-08-24)

39 merged edges, 28 carrying a workstream file, 46 recorded findings.

- **Coverage: 9/9 since the ledger, 0/19 before it.** The review ledger
  landed in PR #31. Every merged edge after it recorded findings; not one
  before it did. A step change on the commit that added the mechanism —
  the strongest evidence in this repo that a recording mechanism, not
  exhortation, is what makes recording happen.
- **Volume: 46 findings — 33 fixed, 6 wontfix, 2 verified-no-change, 5
  unmarked.** 5.1 findings per reviewed edge. The 5 unmarked all arrived on
  one edge, written without the TEMPLATE's `r1:` id: counted, but unlinkable
  to any file. The measure says so rather than dropping them.
- **Cost: 0.8 commits per finding, mean churn peak 1.7** against a threshold
  of 5. Reviews here are not what drives rework.
- **Recurrence: 7 of 19 file-level fixes (36%)** landed on a file an earlier
  merged edge had already fixed a finding in.
- **Hot spots:** `.agents/harness/AGENTS.md` drew findings on 4 separate
  edges; `.agents/harness/selftest.sh` on 3. The harness's own rule file is
  the most defect-prone file in the repo by this measure.
- **Retention: zero.** The finish ritual deletes the workstream file, by
  design — a file left on `main` reads as current. So all 41 findings live
  in merge history and nowhere a session is told to look. Nothing in the
  harness read them until `feedback` did.

One exact repeat is visible in the record: PR #34's r1 and PR #35's r9 are
the same defect one edge apart, and the second finding says so in its own
text. The loop's stages 1 and 2 worked perfectly both times. Stages 3 and 4
did not exist.

## What the numbers picked

Retention zero and recurrence 36% pick the same intervention: carry findings
past the merge that deletes them, and put them in front of the next session
that touches the same file. That is what `feedback` does — the scorecard, and
`feedback <path>` for what a file has already cost. The review step prints the
pointer for the files in the branch's own diff, which is the moment it pays.

The alternatives were weighed against these numbers, not against taste:

- **Running the review instead of recording it** (spawn reviewers per lens):
  coverage is already 8/8. Buys nothing the numbers show missing.
- **Gate self-measurement** (do the thresholds earn their keep): worth doing,
  but churn's mean peak of 1.8 against a threshold of 5 says the gates are
  quiet, not miscalibrated. Later.
- **Feeding outcomes back into agent selection**: needs recurrence per tier,
  which needs more edges than 4 days of history holds. Blocked on data this
  measure now accumulates.

## Worked example: tree or diff

Recurrence names classes; this is the first one it named loudly enough to
graduate. Six merged edges, one question, and every fix local to the caller
that had it:

| Edge | Caller | What reading the tree cost |
| --- | --- | --- |
| PR54 r13 | `graph` | labelled a branch with work it merely inherited |
| PR58 r8 | `upgrade` | refused every sync branch cut from a base that had accreted a workstream file |
| PR60 | `cleanup`, `finish` | `--apply` DELETED an inherited live claim; `finish` returned green on a branch carrying one |
| PR69 r2 | `finish` | fired on the branch that built it — another session's inherited file put it at an edge it was not at |
| PR72 r1 | `finish` wiring | redded its own branch mid-build, naming its own live claim as the offence |
| PR77 r2 | `graph` | the same tree read PR54 had already named, fixed at last |
| PR290 r14, r15 | `janitor` | the rule GRADUATED and was broken anyway: two `cat-file` probes, then a sentence quantified over every branch — "on this branch only", "which no branch carries". Counted: one plan a claim named was on 20 origin refs and not on the base |

**The rule: a branch inherits every file its base branch carries, so presence
in the tree says nothing about the branch. Ownership is a DIFF against the
merge base.**

The last row is the one worth re-reading, because it came after the rule was
written and cites it. A reader can honour "ownership is a diff" and still lie,
by reading two refs and then writing a sentence about all of them. So the rule
generalises: **a reader may claim no more refs than it read, and the sentence
names them.** `janitor`'s cases say "<base>" and "this branch" in the output
for that reason — not for the operator's benefit alone, but because a sentence
bounded by its evidence cannot rot when a third branch appears.

Then pick the filter, because "owns" is three questions:

- `--diff-filter=ACMRT` — files the branch still HAS. `cleanup` needs this:
  plain `--name-only` lists deletions too, so a branch that ran the finishing
  ritual read as still carrying the file it had just deleted, and the file was
  protected from removal forever (`joharness.sh:cl_inflight`).
- `--diff-filter=D` — files the branch DELETED. What recovers a retired
  workstream file (`.agents/docs/handover/README.md`, Survives PR).
- no filter — files the branch TOUCHED. Rarely the question being asked.

One trap inside the right answer: **`git diff base..tip` compares two STATES,
not the history between them.** A file born on the branch and deleted on it —
added, then retired — nets to absent from `D` and from `ACMRT` alike, so
`--diff-filter=D` cannot see the ordinary workstream file, which is written
after the branch is cut. The deletion `D` does see is of a file that existed
at the BASE: an inherited one, or the plan file, which lives on the base
branch because it is the queue item. `dispatch`'s retired-edge scan was built
on the first reading and every one of its nine new cases went red at once
(PR on `orchestrator-inflight-count`). Asking "did this branch delete X" and
meaning "at any point" is a history walk — `git log --diff-filter=D -- <path>`
— and it is a different command.

The class was named in PR54 and still bit at PR69 and PR72, on the very gates
built to read ownership correctly. Stages 1 and 2 worked every time: each
session detected it and recorded it. Stage 3 never ran, so the seventh caller
would have paid again. That is this document's own thesis, tested on itself.

Recount rather than trust the table: `./joharness.sh feedback joharness.sh`
and `./joharness.sh feedback .agents/harness/selftest.sh` reach these
findings, which is where they live.

## Worked example: the hoist that did not hoist

Second class the recurrence named. A fork put inside a loop, four times, each
found by the perf budget rather than by a reader:

| Edge | Caller | The loop it was in |
| --- | --- | --- |
| PR128 `07424a0` | `review_prior` | an `awk` per file in the diff |
| PR132 `d3af200` | `fb_report_path` | once per reported path |
| PR149 | `fb_current_path` | `git ls-files` + `awk` + `grep -c`, once per recorded path that no longer exists — and one goes missing every time the finish ritual retires a file, so the count grows with the repo's own history |
| PR149 r5 | `fb_current_path` again | the hoist itself. The cache went into a global, and the hot caller was `$(fb_current_path ...)` — a SUBSHELL, so the global died before the next call and the fork came back once per miss |

**The rule: a fork inside a loop over history costs one per unit of history,
so it grows without bound. Hoist it — and then check the hoist ran, because a
global assigned inside `$( )` is discarded when the substitution ends.**

The fourth row is the one worth the table. The fix was correct, its comment
said "ONE `git ls-files` for the whole run", the budget went down, and it was
still forking 18 times. Everything agreed except the machine.

Two things follow, and both are about what a measure can see:

- **The budget counts binaries, not argv.** `perf_shims` logs `git`, so 18
  `git ls-files` and 1 are the same number to it. It caught the class and
  could not have caught the regression inside the fix. A case that shims
  `git` and counts `ls-files` can (`.agents/harness/selftest/feedback.sh`).
- **The count fell anyway**, because two of the three forks per miss really
  did go. A number moving the right way is not evidence the stated mechanism
  is the one that moved it — the same session had already published a wrong
  mechanism behind a right number (`joharness.sh`, the FB_LIMIT paragraph the
  perf block corrects in place).

Recount rather than trust the table: `./joharness.sh feedback joharness.sh`.

## When the consumer is the detector

The four stages assume one repo. A consumer running this harness splits them:
**Detect** happens where the work is, **Prevent** only reaches it after a sync.
That extra hop is where this loop dies, and the direction rule
([`consumer-repos.md`](consumer-repos.md)) says only where the fix goes, not how
you get it there.

Walked three times in one consumer session, 2026-08-25. What that cost:

### 1. Decide whether the harness is actually wrong

The signal is that you fought it: a gate you argued with, a message you worked
around, a ritual you skipped. That signal is **not** evidence the harness is
wrong, and this is the stage that goes wrong.

Ask one question: **does the fact it states match what it measures?**

That session's handover guard said *"branch changes code but has no workstream
file"* on a branch whose diff was two `.md` files. The session concluded the
guard had misfired, stopped through it twice, and told its user the harness was
at fault. The guard was right — the branch was changing the queue documents
with no claim, which is exactly its job. What was wrong was one word in the
message and a comment promising an exemption the filter never implemented.

So the feedback was real and it was **about the wording, not the rule**. Had
the session trusted its irritation, it would have relaxed a check that had just
caught it — which is the reverse of a feedback loop.

> **Never relax a guard that just caught you.** Fix what made you misread it.

### 2. Carry the measurement, because canonical cannot reproduce it

Canonical has no consumers to measure on. The number is the whole contribution:

| what canonical got | what it could not have found |
| --- | --- |
| `finish` gate | *three of eight pull requests merged carrying their workstream file, each turning `main` red within seconds; the two that did not were the two that retired first* |
| guard wording | *a session read "code", saw two `.md` files, and stopped through a claim it owed — twice* |
| `decide_ref` | *`cleanup --apply` deleted a live claim on a checkout with no base ref* |

A defect report without its measurement is a preference. With it, the ADR or
the comment writes itself, and the next reader gets the reason rather than the
rule.

### 3. Land it in canonical, never in the consumer

Not doctrine for its own sake. **The next sync overwrites every harness-owned
file in the consumer**, so a harness fix made locally is deleted by the
mechanism whose job is keeping it current — silently, and usually weeks later
when nobody connects the two.

### 4. Inline or routed

The context rule keeps *sync* out of a session holding product work because a
sync diff is thousands of lines. Feedback is the opposite shape: the diff is
small and specific, and the evidence is in that session's head and nowhere
else. So:

- **Capture always, immediately.** In the workstream file's `## Review` if the
  branch has one, in the canonical pull request body otherwise.
- **Fix inline when it is small** — a message, a comment, a guard's scope.
- **Route it when it is not**, and carry the measurement into whatever picks
  it up.

### The switch that mechanizes 1 to 4

Steps 1 to 4 are a session's judgement and a session's memory, and both end
when the session does. By the time a manager's pull request has merged its
findings are gone from every tree — the finish ritual deletes the workstream
file, which is the *Retention: zero* row above — and under orchestrated mode
nobody is left holding them: the manager exits at its merge and the
orchestrator writes one file and reads no plan.

`JOHARNESS_UPSTREAM_FEEDBACK` (`off` | `on`, **off by default**, declared in
`.agents/scripts/conf-keys.sh` so every sync names it to a consumer that has
no line for it):

| off | on |
| --- | --- |
| `./joharness.sh upstream [<edge>]` reports: which of that edge's findings landed on a file canonical owns, which are unattributable, and the `CANONICAL_REPO` they would go to. Nothing acts on it. | the same read, plus the orchestrator spawns ONE reporter per merged edge — `.claude/commands/upstream-report.md`, which walks steps 1 to 4 and files at most one pull request on the canonical. |

Off is the default for two reasons, and neither is caution for its own sake:
it opens pull requests in a repository the child does not own, and a reporter
is one session beyond `JOHARNESS_MAX_MANAGERS`, which is the human's money
(`.agents/harness/AGENTS.md`, Decide alone).

### The second switch: a STUCK edge, not a merged one

A merged edge carries a diff to attach a finding to. An edge that never
merges carries a condition and a clock, and the first switch cannot see it:
the manager has not merged, so the `done` row never fires, and the findings
that matter are not in its `## Review` — they are in why it stopped.

`JOHARNESS_IDLE_ANALYSIS` (`off` | `on`, **off by default**, declared in
`.agents/scripts/conf-keys.sh` beside the key above):

| off | on |
| --- | --- |
| `./joharness.sh analysis [<branch> [<claim>]]` reports: a claim's BLOCKED / STALL? / LOOP? mark, the base branch's current conf answers printed beside the cause the claim stated, and every key that differs or changed since. A sweep prints the rows carrying a condition and counts the rest. Nothing acts on it. | the same read, plus the orchestrator spawns ONE analyst per condition per item per run — `.claude/commands/analyst.md`, which gates what it finds and files at most one ISSUE on the canonical. |

An issue and not a research node, because the two carry different things. A
reporter carries a finding about a harness file it can name, which is a
question canonical's queue can hold. An analyst carries a fleet's behaviour
over a clock — what parked, for how long, what it held up — which is the
shape of the bug report a human files, and which issue #266 IS: a human wrote
that one by hand after the fleet could not.

The command says `MAY BE LIFTED`, never `LIFTED`. It knows a conf key moved;
it cannot know the key answers the prose the manager wrote. Asserting that
mapping would be #266's own defect inverted — a fact stated louder than what
it measures — so the command states what moved and the analyst reads both.

Its other verdict is `NO CONFIG MOVEMENT`, and it says in so many words that
this is not "the cause is live". #266 is that shape exactly: the key landed on
the base branch 8h47m BEFORE the session existed and the branch carried it, so
nothing differed and nothing moved. Which is why the repo's CURRENT answers
are printed for every row carrying a condition, movement or none — the gap was
never a diff, it was the conf and the prose never being read side by side.

What the mechanism does NOT do is decide. `upstream` filters by path and by
nothing else — a filter, not a verdict — because step 1 is the step that goes
wrong and it is not a filter a program can apply. The reporter gates each
finding against *does the fact it states match what it measures*, drops what
does not clear it, and says how many it dropped. A report that skipped that
step is a preference with a diff.

Two of its own limits are printed rather than papered over, both of them the
commit-level attribution named under *What this cannot see* above:

- **A finding whose fix commit carried other findings** is reported with its
  paths flagged as the commit's rather than the finding's. Inside one repo
  that ambiguity costs a hot-spot count; here it decides what leaves the
  repository, and one commit fixing a harness defect beside a repo-private one
  makes each look like both. Flagged, not dropped — a false negative loses the
  finding for good, a flagged false positive costs the reporter one read.
- **A finding with no fix commit at all** — the normal shape of a `wontfix` or
  a no-change verdict, recorded in a commit that touches only the workstream
  file — is placed by the paths its own TEXT names, marked as read from prose.
  One that names none is listed as unplaceable and never flips the verdict by
  itself: a report built on an unplaced finding is a consumer's own defect
  carried verbatim onto somebody else's queue.

A `wontfix` on a harness path is the strongest single signal the command has,
and it is the one that has no fix commit by construction. It reaches the
report through that second rule and through nothing else.

The report lands as **one research node** in canonical, never a requirement
and never a plan. A requirement is the human's goal to set and an unattended
branch that adds one is red (`joharness.sh:lint_requirement_writes`); a plan
asserts the fix, and a child asserting canonical's fix is the inversion step 1
forbids. A research node is a question canonical's own queue lists, a session
claims, and the merge that answers it deletes — so a consumer's finding enters
by rules already written, with no new node type and no new lint.

In canonical the command says `CANONICAL` and stops. A finding made here is
already in the repository that owns its fix; routing it would mean canonical
filing reports against itself, which is the same reason `upgrade` refuses to
run here.

### 5. Stage 4 is the sync, not the merge

A fix merged in canonical has not prevented anything in the consumer that
found it. It prevents on the sync that lands it, which is the one stage of the
loop nobody in either repo is watching — the consumer's session has moved on
and canonical never sees the consumer.

Close the loop by name: when the sync lands, check the thing that bit you is
gone. That session ran `./joharness.sh finish` on the very sync branch carrying
`finish`, which is the cheapest possible version of it.

### Where a consumer's OWN findings go

Issue #258's third direction asks for a destination for the findings `upstream`
calls unplaceable — the ones about the consumer's own product — and calls it
"the largest change and the one that fits the existing design best". Settled by
counting. **Do not build it**, and the reason is structural rather than a
headcount.

Canonical cannot run the code path that classifies: `cmd_upstream` returns early
on `JOHARNESS_CANONICAL=1`. So the sweep stripped that one line into a scratch
conf and read every merged edge through it (2026-10-08, this repo, 273 edges):

```bash
grep -v '^JOHARNESS_CANONICAL=1' joharness.conf > /tmp/consumer.conf
git log --first-parent --format='%H %P%x09%s' --merges origin/main |
  awk -F'\t' '{n = split($1, a, " "); if (n < 3) next; print a[1]}' |
  while read -r sha; do
    JOHARNESS_CONF=/tmp/consumer.conf ./joharness.sh upstream "$sha"
  done
```

2005 findings over 224 edges carrying a workstream file. Cross-check against the
other reader, and **the flag is not optional**:

```bash
JOHARNESS_FEEDBACK_EDGES=0 ./joharness.sh feedback   # 273 edges, 224 with a file, 2005 findings
```

Without `=0` that command reads only the newest `FB_LIMIT` edges (default 50)
and prints `530 findings` over `44 carrying a workstream file` — and 530 is the
same integer as the unplaceable row below, so the plain command reads as
confirming a row it never counted. Both totals also climb with every merge; this
page's header rule applies to them as to every other number here.

| bucket | findings | reader today |
| --- | --- | --- |
| kept — fix path canonical owns | 1356 | `upstream` → `/upstream-report` |
| this repo's own — fix path, none canonical's | 119 | `cmd_feedback`, path-keyed, served by the PreToolUse hook before the next edit |
| unplaceable | 530 | the question |

So the question is those 530. Split by whether the finding's own text carries a
path token at all, `upstream_text_paths` re-run on each bullet the sweep printed:

- **379 carry none.** Exactly the shape the second limit above predicts: a
  `wontfix` or a no-change verdict, recorded in a commit touching only the
  workstream file. It has no path BY CONSTRUCTION. A path-keyed place cannot
  hold it, so a destination for these is not a destination — it is a different
  key, and nobody has proposed one.
- **151 carry one**, under a heading that says they carry none.

Those 151 partition exactly, by the strongest resolution that succeeds against
`git ls-tree -r --name-only origin/main` plus the paths history ever added.
**The rule is stated because the numbers mean nothing without it** — an
unrecorded method is a failed file (`.agents/docs/research/README.md`):

| | resolution | findings |
| --- | --- | --- |
| A | the token IS a tree-or-history path, and canonical owns none of them | 8 |
| B | canonical-owned after stripping a leading `./`, or by a basename matching exactly one tree path | 44 |
| C | canonical-owned by a basename matching SEVERAL tree paths, every one of them canonical's | 13 |
| D | nothing resolves | 86 |

`8 + 44 + 13 + 86 = 151`. **B and C are the defect: 57 findings about
canonical's own files, printed to the operator as naming no path and never
entering a filed report.** A bare `README.md` is in neither — the root
`README.md` is not canonical-owned, so that basename is genuinely ambiguous and
belongs in D. That is the same trap as mistaking `docs/handover/README.md` for
`.agents/docs/handover/README.md` by suffix, which is how an earlier count of
this got 45 instead of 44.

Of A's 8, every one names a node that retires (`docs/plans/`, `docs/handover/`,
`docs/research/`, `docs/product/`), a queue-directory `README.md`, or a file in
another repository — one cites gastown's. **None names a durable
consumer-owned product file.**

**That zero is not the argument, and on this corpus it could not have been
anything else.** `upstream_harness_path` rejects 20 of this tree's 142 tracked
files; strip the retiring queue nodes and the durable remainder is six —
`.github/workflows/ci.yml`, `.github/workflows/update.yml`, `.gitignore`,
`LICENSE`, `README.md`, `joharness.conf`. Not one is product code, because
**canonical has no product code to find a finding in.** A real consumer's
`src/**` and `tests/**` are all durable and all rejected, so the measured zero
says nothing whatever about the population #258 is actually about. Quote it as
illustration or not at all.

What does carry the answer is a dichotomy the sweep only illustrates: **a
consumer's product finding either has a fix path or it does not.** With one, it
lands in row 2 and `cmd_feedback` already serves it, keyed on that path, through
a PreToolUse hook that fires before the next edit to the file — automatic
already, and the 119 in row 2 are that path exercised. Without one, it is a
`wontfix` or a no-change verdict with nothing to key on, and a path-keyed
destination cannot reach it however it is built. There is no third case, so
there is no gap for a new destination to fill. That is what kills #258's third
direction, and it would hold at any headcount.

**So the answer is neither a place nor a reader. It is placement**, and one
defect each in labelling and in ownership:

1. **The unplaceable heading is false about 151 of its 530 members.** The middle
   branch is `[ -n "$paths" ] && [ "$from_text" -eq 0 ]`, so a finding placed
   from its own TEXT cannot reach "this repo's own" and falls to the `else`,
   printing under *no fix path, and no path in the text*. The ROUTING there is
   deliberate and the code says so — "that is not a finding about this repo's
   own files, it is a finding nothing placed" — so the defect is the sentence,
   not the branch: it asserts of 151 findings something their own text refutes.
   `.claude/commands/upstream-report.md` repeats it ("listed with no path at
   all"), so the reporter reads it too. Instance: PR315's `r8`, printed as
   naming no path, whose text yields `precision/recall` — which places nothing,
   which is the point. The finding is not misrouted; the label is a lie.
2. **57 findings about canonical's own files never reach the report.**
   `upstream_harness_path` matches `joharness.sh` and not `./joharness.sh` —
   the form every instruction file in this repo writes the command in — which
   is 12 of the 44 by itself. The rest name a harness file by basename:
   `selftest.sh` → `.agents/harness/selftest.sh`, `janitor.md` →
   `.claude/commands/janitor.md`, `review.sh`, `drain.md`,
   `agent-selection.md`, `graph.md`, and C's `handover-context.sh`,
   `queue-context.sh`, `TEMPLATE.md`, each matching several paths that are all
   canonical's. The predicate's own comment says the doubtful cases are in
   because "a false negative loses the finding entirely". These 57 are that
   false negative, in the one direction that puts them out of canonical's
   hearing.

The trap for whoever fixes the second: **not** by narrowing
`upstream_text_paths`. D's 86 are the junk it would be aimed at — `origin/main`
20 times, a bare `/` 8, `precision/recall`, `before/after` — and no tokenizer
can tell those from `selftest.sh` or `TEMPLATE.md`, which are the same shape.
The predicate that decides OWNERSHIP is the wrong one, not the one that finds
tokens. And ownership is decidable where the path is not: several matches that
are ALL canonical's is not an ambiguous verdict, which is C's whole content.

Grading the claims, as `.agents/docs/research/README.md` requires of a closure:

- **GROUNDED** — every count above, re-derivable from the two commands quoted
  and the partition rule stated with the table. A second context re-counted
  273 / 224 / 2005, the three buckets, the 379 / 151 split, the 44 and the 12.
- **GROUNDED** — the dichotomy that carries the answer. It rests on
  `cmd_upstream`'s branch structure and `cmd_feedback`'s key, both read, not on
  any headcount.
- **GROUNDED** — defect 2 at 57, and defect 1 as a labelling defect.
- **UNGROUNDED, and it was load-bearing when first written** — "zero consumer
  product findings, so nothing is homeless". The zero reproduces and proves
  nothing: canonical owns no product code, so the corpus could not have held a
  counter-example. Found by the verifier pass, not by the session that counted
  it. The conclusion was re-derived from the dichotomy instead, which is why it
  still stands.
- **UNGROUNDED** — "142 of the 151 resolve to nothing real", as first written.
  It counted the 44 as unreal while the sentence after it depended on their
  being real, so it refuted itself; the figure is D, 86. Same pass.

The two defects are in `joharness.sh` and `.claude/commands/upstream-report.md`,
both named by `./joharness.sh protocol-paths`, so they are
`docs/plans/upstream-placement-defects.md` and SUPERVISED ONLY. Nothing is
blocked on them: the misplacement costs canonical 57 findings it has not been
hearing, and has never cost a consumer a reader it had.

## What this cannot see

Named because a measure that hides its blind spots is worse than no measure:

- **Only the newest 50 edges are read** (`JOHARNESS_FEEDBACK_EDGES`,
  default 50 — `joharness.sh:cmd_feedback`). Past that, findings fall out
  of every count above; the output names how many edges went unread.
- **Classes, not files.** Recurrence is measured on paths. Two findings of
  the same *kind* in different files read as unrelated; the same file drawing
  two unrelated findings reads as a repeat. Classifying prose needs judgment,
  and a field for sessions to fill in is a field that rots.
- **Commit-level attribution.** A finding is linked to its fix commit, so a
  commit carrying several findings attributes all of them to every file it
  touched.
- **Findings without the `r1:` id.** Attribution keys on the id the TEMPLATE
  prescribes. A bullet written without one still counts in volume — the
  handover hook counts it too — but nothing links it to a file. One of the
  nine reviewed edges here wrote all five of its findings that way, which is
  how the gap got noticed; the scorecard prints the count rather than
  quietly reading those edges as clean.
  This one is no longer only reported. `./joharness.sh ci` has a
  `== finding ids` stage that names the unkeyable bullets on the branch's own
  diff, by file and by their own text, while the branch can still fix the
  form (`joharness.sh:lint_finding_ids`). It warns and never reds: the count
  has no backtest behind it, and the plan that gates it comes after the number
  falls. It does not close the blind spot for findings already merged, and
  nothing rewrites those — a record edited to satisfy a later rule stops being
  a record.
- **Disposition read from prose.** `(fixed)`, `wontfix` and "no change" are
  matched in the finding's text, so a finding saying "fixed; no change to the
  docs" reads as no-change. The alternative is a structured field per
  finding, and a field a hurried session fills in wrong is the failure mode
  delete-on-merge exists to avoid.
- **Renames.** A path recorded before a move resolves by unique-suffix match
  and otherwise stands as recorded. This repo's own `.agents/` move split one
  hot spot into two cold ones until that was fixed.
- **The window is a choice, and a small one is noisy.** Recurrence scores
  only the newest `JOHARNESS_RECURRENCE_WINDOW` recorded edges, so a repo
  with few edges scores few pairs and one rediscovery moves it a long way.
  The window is named in the output for that reason; two windows never
  compare. This replaces the old "ask again at 30 edges" deferral, which the
  cumulative definition could never have answered — a sliding window answers
  it continuously instead, and there is nothing left to defer.
- **Merged history only.** An open branch has recorded nothing yet.
