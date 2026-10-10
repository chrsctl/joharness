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
recorded edges (default 8; 86% of repeats fall within 8 edges), both sides of
the ratio. A file fixed and then left alone leaves the window and stops
counting. Numbers from two windows never compare.

### Volume is not a score

Counting findings and calling more of them better is the trap. The review
churn rule (`.agents/docs/agent-selection.md`) already establishes it from
measurement: finding counts are no signal, false in both directions — five
findings can be one real defect found five ways, and zero can be a review
nobody ran. A loop scored on volume optimizes for volume; the models under
this harness are literal enough to deliver exactly that.

Recurrence cannot be gamed by producing more output: output on a file
nobody touched inside the window does not score.

## Why `feedback` exists

Retention was zero: the finish ritual deletes the workstream file, so every
recorded finding lived only in merge history, and the same defects came back
one edge apart. `feedback` carries findings past the merge and puts them in
front of the next session touching the same file — on demand, at `review`,
and before every edit through the PreToolUse hook.

## Worked example: tree or diff

The first class recurrence named loudly enough to graduate: seven edges, one
question, every fix local to the caller that had it (`cleanup --apply`
deleted an inherited live claim; `finish` redded its own branch over an
inherited file; a sentence about "every branch" written after reading two).

**The rule: a branch inherits every file its base branch carries, so presence
in the tree says nothing about the branch. Ownership is a DIFF against the
merge base.**

**A reader may claim no more refs than it read, and the sentence names
them.**

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
branch because it is the queue item. Asking "did this branch delete X" and
meaning "at any point" is a history walk — `git log --diff-filter=D -- <path>`
— and it is a different command.

Recount: `./joharness.sh feedback joharness.sh`.

## Worked example: the hoist that did not hoist

**A fork inside a loop over history costs one per unit of history, so it
grows without bound. Hoist it — and check the hoist ran: a global assigned
inside `$( )` is discarded when the substitution ends.** A number moving the
right way is not evidence the stated mechanism moved it.

## When the consumer is the detector

The four stages assume one repo. A consumer running this harness splits them:
**Detect** happens where the work is, **Prevent** only reaches it after a sync.
That extra hop is where this loop dies, and the direction rule
([`consumer-repos.md`](consumer-repos.md)) says only where the fix goes, not how
you get it there.

### 1. Decide whether the harness is actually wrong

The signal is that you fought it: a gate you argued with, a message you worked
around, a ritual you skipped. That signal is **not** evidence the harness is
wrong, and this is the stage that goes wrong.

Ask one question: **does the fact it states match what it measures?**

A guard that fired on a two-`.md` branch was right about the rule and wrong
in one word of its message: the feedback was about the wording, not the rule.

> **Never relax a guard that just caught you.** Fix what made you misread it.

### 2. Carry the measurement, because canonical cannot reproduce it

Canonical has no consumers to measure on; the number is the whole
contribution. A defect report without its measurement is a preference.

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
  branch has one, in the canonical pull request body otherwise. Neither
  exists (the finding surfaced after the retire commit, and no open
  CANONICAL pull request — the consumer's own carries no `## Review` and does
  not count)? An issue on the repo `CANONICAL_REPO` names
  (`.github/workflows/update.yml`).
- **Fix inline when it is small** — a message, a comment, a guard's scope.
- **Route it when it is not**, and carry the measurement into whatever picks
  it up.

The issue route is available, never an order. At most ONE such issue per
session; search canonical's open issues for the same finding first. It
carries the command and output that produced it. Canonical out of the
session's GitHub scope? Hand the human the issue text — never drop it silent.

The clerk's UPSTREAM verdict (`.claude/commands/clerk.md`) is the issue-shaped
twin of this route, for an issue filed in a consumer. The cap above binds
findings; a clerk files at most one issue per routed issue (its batch already
caps the pass).

### The manual report

Steps 1 to 4 end with the session, and a merged manager's findings are gone
from every tree. `./joharness.sh upstream [<edge>]` reports which of an
edge's findings landed on a file canonical owns, which are unattributable,
and the `CANONICAL_REPO` they would go to. `/upstream-report <edge>`
(`.claude/commands/upstream-report.md`) walks steps 1 to 4 on that read and
files at most one pull request on the canonical. Run by hand; nothing spawns
it.

### A STUCK edge, not a merged one

An edge that never merges carries a condition and a clock instead of a
diff. `./joharness.sh analysis [<branch> [<claim>]]` reports a claim's
BLOCKED / STALL? / LOOP? mark beside the base branch's current conf answers
and every key that changed since; read by hand, nothing acts on it. It says
`MAY BE LIFTED`, never `LIFTED`, and `NO CONFIG MOVEMENT` is not "the cause
is live": it knows a conf key moved, not that the key answers the prose the
manager wrote.

`upstream` filters by path and nothing else; the reporter gates each finding
against *does the fact it states match what it measures*. A finding whose fix
commit carried other findings is reported with its paths flagged as the
commit's; one with no fix commit (a `wontfix` or no-change) is placed by the
paths its own text names. The report lands as one research node in
canonical — never a requirement or a plan. In canonical the command says
`CANONICAL` and stops.

### 5. Stage 4 is the sync, not the merge

A fix merged in canonical has not prevented anything in the consumer that
found it. It prevents on the sync that lands it, which is the one stage of the
loop nobody in either repo is watching — the consumer's session has moved on
and canonical never sees the consumer.

Close the loop by name: when the sync lands, check the thing that bit you is
gone. That session ran `./joharness.sh finish` on the very sync branch carrying
`finish`, which is the cheapest possible version of it.

### Where a consumer's OWN findings go

Nowhere new — decided by counting (2026-10-08, 273 edges). A consumer's
product finding either has a fix path, and `feedback` already serves it keyed
on that path, or it has none (a `wontfix` or no-change), and no path-keyed
destination can reach it. No third case, so no destination to build.

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
  how the gap got noticed. `./joharness.sh ci`'s `== finding ids` stage names
  unkeyable bullets on the branch's own diff while it can still fix the form.
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
  The window is named in the output; two windows never compare.
- **Merged history only.** An open branch has recorded nothing yet.
