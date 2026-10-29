# Feedback loops, and how to score one

What a feedback loop is here and how to tell a good one from a busy one.
Measure it: `./joharness.sh feedback`, counted from git at read time, nothing
stored.

## The four stages

A loop that improves anything clears four bars in order; each is a place it
dies quietly:

1. **Detect** — something notices the defect. (Review, CI, a gate.)
2. **Record** — the noticing survives the moment. (Findings in the workstream
   file's `## Review`.)
3. **Generalize** — one defect becomes a rule about a class of defects.
   (Graduation: `.agents/docs/handover.md`.)
4. **Prevent** — the rule reaches the next session before it repeats the
   defect, not after.

Only stage 4 changes an outcome. The finish ritual deletes the workstream
file, so a finding lives only in merge history; `feedback` puts it in front
of the next session touching the same file: `.agents/harness/pretool-feedback.sh`
before Edit, Write or NotebookEdit, once per file per session, at `review`,
and on demand (`./joharness.sh feedback <path>`).

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
the same file stops drawing the same class of finding.

Scored over the newest `JOHARNESS_RECURRENCE_WINDOW` recorded edges (default
8), both sides of the ratio: cumulative `1 - D/N` converges on 100% whatever
the loop does. A file fixed and then left alone leaves the window and stops
counting. Numbers from two windows never compare.

Volume is not a score: finding counts are no signal
(`.agents/docs/agent-selection.md`, Review churn). Output on a file nobody
touched inside the window does not score.

## Worked example: tree or diff

**The rule: a branch inherits every file its base branch carries, so presence
in the tree says nothing about the branch. Ownership is a DIFF against the
merge base.**

**A reader may claim no more refs than it read, and names them.** "Owns" is
three questions:

- `--diff-filter=ACMRT` — files the branch still HAS (`joharness.sh:cl_inflight`):
  plain `--name-only` lists deletions too.
- `--diff-filter=D` — files the branch DELETED. What recovers a retired
  workstream file (`.agents/docs/handover.md`, Survives PR).
- no filter — files the branch TOUCHED. Rarely the question being asked.

Trap: **`git diff base..tip` compares two STATES, not the history between
them.** A file added then retired on the branch (the ordinary workstream
file) is absent from `D` and `ACMRT` alike; `D` sees only files that existed
at the BASE (an inherited one, the plan file). "Deleted at any point" is a
history walk: `git log --diff-filter=D -- <path>`.

Recount: `./joharness.sh feedback joharness.sh`.

## Worked example: the hoist that did not hoist

**A fork inside a loop over history grows without bound. Hoist it — and check
the hoist ran: a global assigned inside `$( )` dies with the substitution.** A
number moving the right way is not evidence the stated mechanism moved it.

## When the consumer is the detector

A consumer splits the stages: **Detect** happens where the work is,
**Prevent** reaches it only after a sync. The direction rule
([`consumer-repos.md`](consumer-repos.md)) says where the fix goes; this
section says how it gets there.

### 1. Decide whether the harness is actually wrong

The signal is that you fought it: a gate argued with, a message worked
around, a ritual skipped. That is **not** evidence the harness is wrong. Ask:
**does the fact it states match what it measures?** A guard can be right about
the rule and wrong in one word of its message; then the feedback is the wording.

> **Never relax a guard that just caught you.** Fix what made you misread it.

### 2. Carry the measurement, because canonical cannot reproduce it

A report without its measurement is a preference.

### 3. Land it in canonical, never in the consumer

The direction rule: the next sync silently overwrites a local harness fix.

### 4. Inline or routed

The context rule keeps *sync* out of a session holding product work;
feedback is small and its evidence lives only in that session. So:

- **Capture always, immediately**: the workstream file's `## Review`, else the
  CANONICAL pull request body (the consumer's own carries no `## Review`, does
  not count), else an issue on the repo `CANONICAL_REPO` names
  (`.github/workflows/update.yml`).
- **Fix inline when small** — a message, a comment, a guard's scope.
- **Route it when not**, carrying the measurement.

The issue route is available, never an order: at most ONE per session, after
searching canonical's open issues; it carries the command and output.
Canonical out of GitHub scope? Hand the human the issue text, never drop it
silent. The clerk's UPSTREAM verdict (`.claude/commands/clerk.md`) is the twin
for an issue filed in a consumer: at most one issue per routed issue.

### 5. The manual report

For a merged edge: `./joharness.sh upstream [<edge>]` reports which findings
landed on a file canonical owns, which are unattributable, and the
`CANONICAL_REPO` they would go to; in canonical it says `CANONICAL` and stops.
It filters by path only: a fix commit carrying other findings flags its paths
as the commit's; a finding with no fix commit is placed by the paths its text
names. `/upstream-report <edge>` (`.claude/commands/upstream-report.md`), run
by hand, gates each finding on step 1's question and files at most one pull
request on the canonical: one research node, never a requirement or a plan.

A practice — a rule a consumer invented in its own files (`AGENTS.md` Part
2, `docs/`, `scripts/`) — never lands on a canonical-owned path, so
`upstream` never places it. It goes by hand: `/upstream-report practice
<path>[:<heading>]`, the same one research node. It qualifies when it is
generic (restated without the consumer's stack), measured (a command and
its output), and absent from canonical. § 8 governs a consumer's own
findings; a practice is not one.

### 6. A STUCK edge, not a merged one

`./joharness.sh analysis [<branch> [<claim>]]`, read by hand
(`.agents/docs/orchestrated.md`, `analysis` row). It says `MAY BE LIFTED`,
never `LIFTED`; `NO CONFIG MOVEMENT` is not "the cause is live".

### 7. Stage 4 is the sync, not the merge

A canonical fix prevents nothing in the consumer until the sync lands it.
Then check the thing that bit you is gone.

### 8. Where a consumer's OWN findings go

Nowhere new: one with a fix path is served by `feedback` on that path; one
without (`wontfix`, no-change) no path-keyed destination can reach. A defect
OUTSIDE the edge's change = a `defect:` issue on the consumer's repo
(`.claude/commands/manager.md`, "A DEFECT"), filed unlabelled so the clerk
plans it; a BLOCKING one opens `blocking: <branch>`, so the clerk plans it urgent.
`human-review` only when its fix needs a human's call (Loop, Decide alone).

## What this cannot see

- **Only the newest `JOHARNESS_FEEDBACK_EDGES` edges are read** (default 50,
  `joharness.sh:cmd_feedback`); the output names how many went unread.
- **Classes, not files.** Recurrence is measured on paths: same kind in two
  files reads unrelated; two unrelated findings in one file read as a repeat.
- **Commit-level attribution.** A commit carrying several findings attributes
  all of them to every file it touched.
- **Findings without the `r1:` id** count in volume but link to no file;
  `./joharness.sh ci`'s `== finding ids` stage names them on the branch's diff.
- **Disposition read from prose**: `(fixed)`, `wontfix`, "no change" match in
  the text, so "fixed; no change to the docs" reads as no-change.
- **Renames.** A pre-move path resolves by unique-suffix match, else stands.
- **A small window is noisy**: few edges, few pairs, one rediscovery moves it far.
- **Merged history only.** An open branch has recorded nothing yet.
