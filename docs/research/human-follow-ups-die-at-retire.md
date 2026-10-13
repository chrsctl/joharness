---
research: human-follow-ups-die-at-retire
urgency: normal
agent: fable
effort: high
graduates: .claude/commands/manage.md
---

## Question

Does the harness give a manager any durable place to leave work that only a
human can do (a core-path edit), or does that work survive only in a merged
pull request's body, where nothing reads it again?

## Echo

A manager that finishes everything but a core-path edit (`.github`,
`joharness.conf`, `.claude/settings.json`) has to hand that remainder to a
human. `manage.md` says "Follow-up work that must outlive this session = a
plan file in your pull request." But a plan whose `scope:` is core paths
ONLY is red in `ci` (`.agents/docs/plans/README.md`, the CORE ONLY
paragraph), so that route is closed for exactly this kind of follow-up. The
workstream file, where a session would write it, is deleted at retire
(Loop step 7). What rests on the answer: whether human-only remainders are
silently dropped whenever the human does not happen to read the right PR.

## Sweep

`goal-directed`: the two live instances in consumer `chrsctl/gx` and the
harness text that routes follow-ups; not every consumer.

## What would settle it

YES if (a) a merged edge left a human-only remainder, (b) the only record of
it on `main` or in the queue is a PR body or a deleted file, and (c) no
command a human or the orchestrator runs (dispatch, the orchestrator report,
`upstream`) lists it. NO if any harness output lists open human remainders.

## Method

In `chrsctl/gx`, 2026-10-13:

```
git log --oneline -6 origin/main
git show 88c820fd --stat
git show origin/main:docs/plans/crm-write-document-prints-a-pdf.md   # before its retire
JOHARNESS_PENDING_SPAWNS=0 ./joharness.sh dispatch
```

## Findings

- **Both gx plans were split so a manager could build them, leaving the CI
  edit to a human.** gx #651 (merged 2026-10-13 ~01:35Z) took
  `.github/workflows/ci.yml` out of the scope of
  `repo-scripts-are-shellchecked` and `crm-write-document-prints-a-pdf`, and
  put the edit in a "Human follow-up" section. Each plan's acceptance
  requires the manager's PR body to quote the edit verbatim. That was the
  only home available: a core-only plan is red in `ci`. (Background:
  chrsctl/joharness#457.)
- **Instance 1 was caught only because the human noticed.** The shellcheck
  manager merged gx #654 (retire commit 27c622aa deletes the plan and the
  workstream file, so the follow-up text is gone from `main`). The human
  then noticed the CI step was missing and asked the manager to add it. The
  manager committed `.github/workflows/ci.yml` (88c820fd, +4 lines) as gx
  #655, and the human merged it. Nothing in dispatch, the orchestrator's pass
  report or `upstream` had listed the remainder. The human, asked afterwards:
  "we need to collect work if forgot".
- **Instance 2 is open right now and listed nowhere.** The PDF plan's CI edit
  (move the renderer step ahead of `platform/tests/workflows.py`) will
  survive its retire only in that plan's PR body. Dispatch at
  2026-10-13T02:06Z prints no line for it.
- **The one follow-up route the harness names cannot hold this.** "Follow-up
  work that must outlive this session = a plan file in your pull request"
  (`.claude/commands/manage.md`, after "Commit per sub-task") collides with
  "A plan whose `scope:` is core paths ONLY is red in `ci`"
  (`.agents/docs/plans/README.md`). The two rules together leave a human-only
  remainder with no legal file.
- **Side finding: the core-path boundary was crossed on the human's word.**
  88c820fd is an agent-authored commit under `.github`. The human asked for
  it and merged it, so nothing went wrong here. But it shows that the
  documented route ("a human changes them, by hand") gives way under a
  forgotten follow-up. Canonical may want to say whether a session may
  author a core-path diff a human merges. (`.agents/docs/orchestrated.md`,
  Bounds, implies the guarantee is CODEOWNERS review, not authorship.)

Cost here: one CI step missing from `main` between #654 and #655, caught
only because the human noticed. One more remainder is pending with the same
exposure.

## Consequence for the queue

Canonical decides. Candidate changes:

1. **A legal home for a human remainder.** For example, a `human:` line in
   the plan or PR frontmatter, or a one-line ledger file on `main`
   (`docs/human-followups.md`, a row appended at retire and removed by the
   human's merge). Dispatch reads it and prints `waiting on a human: <n>
   follow-ups, oldest <age>`, the same way #457 asks for CORE ONLY plans.
2. **`manage.md` names that home**, beside "a plan file in your pull
   request", for work no plan may hold.
3. **The orchestrator's report carries the dispatch line**, and pushes a
   notification once per new remainder, as it does for a `blocked` row.
4. **Optional: decide the side finding.** Either an agent-authored core diff
   with a human merge is allowed (and the Bounds text says so), or it is not
   (and the Stop guard should name that case).

## Verification

UNVERIFIED by a second context. Commit ids and dispatch output are from one
orchestrator session in `chrsctl/gx`; canonical re-reads them before acting.

## Graduates to

`.claude/commands/manage.md`, the follow-up sentence that today names only a
plan file. The dispatch and orchestrator changes follow from where that
sentence sends the remainder.
