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

First context, in `chrsctl/gx`, 2026-10-13 (an orchestrator session):

```
git log --oneline -6 origin/main
git show 88c820fd --stat
git show origin/main:docs/plans/crm-write-document-prints-a-pdf.md   # before its retire
JOHARNESS_PENDING_SPAWNS=0 ./joharness.sh dispatch
```

Second context, the manager that closed this file, 2026-10-14, in a fresh
read-only clone of `chrsctl/gx` (`git clone --depth 1`, then
`git fetch --depth=400 origin main`) and in this checkout:

```
git -C /home/user/gx show 88c820fd --stat
git -C /home/user/gx show 27c622aa --stat
git -C /home/user/gx show 27c622aa^:docs/plans/repo-scripts-are-shellchecked.md
git -C /home/user/gx log --oneline -5 origin/main -- docs/plans/crm-write-document-prints-a-pdf.md
git -C /home/user/gx show ab1dc009^:docs/plans/crm-write-document-prints-a-pdf.md
git -C /home/user/gx log --format='%h %ad %s' --date=iso -5 origin/main -- .github/workflows/ci.yml
git -C /home/user/gx show 600064e4 --format='%an%n%ad%n%B' --stat
git -C /home/user/gx log --oneline --merges --ancestry-path 600064e4..origin/main | tail -1
pull_request_read get: chrsctl/gx 654, 655, 657 (GitHub MCP)
issue_read get: chrsctl/joharness 457 (GitHub MCP)
grep -n 'CORE ONLY\|human-review\|follow-up' joharness.sh .claude/commands/*.md .agents/docs/*.md
sed -n 6575,6692p joharness.sh      # dispatch: what an in-flight row is read from
sed -n 2126,2175p joharness.sh      # cmd_upstream: what it reads
JOHARNESS_PENDING_SPAWNS=0 ./joharness.sh dispatch
```

## Findings

- **Both gx plans were split so a manager could build them, leaving the CI
  edit to a human.** GROUNDED. gx #651 (`7f1e0814`, "Split the core CI edit
  out of two CORE ONLY plans, on the human's order", `ee335fd0`) gave
  `repo-scripts-are-shellchecked` and `crm-write-document-prints-a-pdf` each
  a `## Human follow-up (core path, not this plan's)` section and an
  acceptance line requiring the pull request body to quote the edit
  verbatim. Read at `27c622aa^` and `ab1dc009^`. Background: joharness pull
  request #457 (a consumer report; it carries no plan).
- **Instance 1 was caught only because the human noticed.** GROUNDED for
  the commits, WEAK for the "noticed". gx #654 merged 2026-10-13T02:12:36Z;
  its retire commit `27c622aa` deletes the plan (99 lines) and the workstream
  file (24 lines), so the follow-up text is gone from `main`. The body of
  #654 carries the step under "A human applies this (core path `.github`)".
  gx #655 (`88c820fd`, `.github/workflows/ci.yml` +4, "Touches `.github`, a
  core path, at the user's explicit request — needs a human merge") was
  opened 02:16:55Z and merged by the human 02:17:42Z. That the human, not a
  harness read, saw the gap is the first context's session reading; no
  command re-takes it, and the second context found nothing contradicting
  it.
- **Instance 2 did NOT survive only in a pull request body — but for the
  same reason as instance 1, not because of the harness.** GROUNDED;
  corrects the first draft, which read it as open. gx #656 (`600064e4`,
  02:25:24Z, "Authored on the human's order; a human merges") put the
  renderer address into `ci.yml` BEFORE the plan's own pull request gx #657
  opened (02:37:11Z); #657's body records the edit as already applied. The
  catch was again the human ordering an agent, between the two merges.
- **Nothing the harness prints lists a human remainder.** GROUNDED by code
  reading in this checkout. `dispatch` builds an in-flight row from the
  workstream file at `origin/<branch>` (`gr_fields status session next pr`)
  and the plan queue; `CORE ONLY` rows come from plans still in
  `docs/plans/`; neither reads a pull request body or a deleted file.
  `cmd_upstream` reads a retired workstream file for `## Review` findings,
  and in canonical stops at once. The orchestrator's report is `dispatch`
  plus control-plane state. The first context's "dispatch at
  2026-10-13T02:06Z prints no line for it" is a session reading, WEAK: no
  command here re-takes it, and it is consistent with the code.
- **The one follow-up route the harness names cannot hold this.** GROUNDED.
  "Follow-up work that must outlive this session = a plan file in your pull
  request" (`.claude/commands/manage.md` §2) against "A plan whose `scope:`
  is core paths ONLY is red in `ci`" (`.agents/docs/plans/README.md`). The
  clerk has the same wall from the other side: a core-only ask gets verdict
  HUMAN and the label `human-review`, never a plan (`clerk.md` §3).
- **Side finding: both core diffs were agent-authored on the human's order
  and human-merged.** GROUNDED. `600064e4`'s message says so; for
  `88c820fd` it is the body of gx #655 ("at the user's explicit request —
  needs a human merge"), not the commit message. Both pull requests were
  merged by `chrsctl`.
  `.agents/docs/orchestrated.md` Bounds already puts the guarantee on
  code-owner review, not authorship.

Cost: one CI step missing from gx `main` for five minutes (02:12:36Z to
02:17:42Z), caught by the human. The second remainder cost nothing only
because the same human acted first.

## Consequence for the queue

Settled YES. The answer graduates as text, no plan:

1. The home for a human remainder is ONE GitHub issue labelled
   `human-review`, filed by the manager before its retire commit
   (`.claude/commands/manage.md` §2). The clerk already lists such an issue
   as `held: human-review` every pass and never plans it; the human's merge
   closes it.
2. Why, and what was rejected (a ledger on `main`, a core-only plan):
   `.agents/docs/plans/README.md`, "A human remainder".
3. Bounds names the second use of the label
   (`.agents/docs/orchestrated.md`).
4. `dispatch` keeps reading git only; whether it should also count open
   `human-review` issues is left open, named in the README section. The
   sibling research `partly-core-plans-strand-their-slots` owns what
   `dispatch` says about `CORE ONLY` plans.
5. The side finding needs no rule change: Bounds already says the guarantee
   is code-owner review.

## Verification

Second context: this file's closing manager, in a fresh clone of
`chrsctl/gx` and this checkout, commands under Method. Every commit id,
timestamp, line count and pull request body re-read. One finding corrected
(instance 2 was closed before its plan merged, not open). The verifier at
fable re-took the pull request bodies and timestamps through the GitHub REST
API and found one source misattributed (fixed). Two readings stay WEAK
because no command re-takes a session record: that the human
"noticed" rather than being told, and the 02:06Z dispatch output. Neither
changes the answer, which rests on the code reading of `dispatch` and
`cmd_upstream` in this checkout.

## Graduates to

`.claude/commands/manage.md`, the follow-up sentence that today names only a
plan file; the why under `.agents/docs/plans/README.md`, "A human
remainder"; one clause in `.agents/docs/orchestrated.md`, Bounds.
