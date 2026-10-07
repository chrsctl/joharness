---
workstream: janitor-reader-tells-the-truth
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: none
issue: 278
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: opus
updated: 2026-10-07
next: Read the mutation verdict for the base-branch clause, then commit the code with this file and open the pull request
---

## Goal

Requester, 2026-10-07: "Fix and continue." Four issues had been filed from
three janitor sweeps and a curate pass and none fixed, because each role
forbids touching code. This session is in none of those roles, the repo is
supervised, and the boundary that bars protocol text is the unattended one —
so the fixes are available here.

Taken: **#278 and #288**, which are one pattern in one function. `cmd_janitor`
printed two conclusions about state it never read.

- `holds: docs/plans/<x>.md, out of the queue while this claim stands`, from
  the claim's `plan:` field alone. False whenever the plan lives only on the
  claim's own branch, which is the normal shape — plan and claim are written
  together. Wrong on 5 of 5 candidates in the first sweep and on every
  plan-naming candidate for three sweeps.
- `pull request N — nearly done, not abandoned work`, from the field's
  presence alone. Said of a pull request closed without merging seven weeks
  earlier, three sweeps running, while `drain` said "state unverified" about
  the same field.

## Decisions

- **Step 3 was skipped and this file is late.** The build started without a
  claim. Recorded rather than quietly backdated: the Stop guard caught it,
  which is the guard working.
- **#278 and #288 together, #279 not.** The first two are one function and one
  pattern — a reader asserting state it never read — so one diff reviewed as
  one idea. #279 is a different family (a word that reached one reader and not
  others) and would make this diff two changes wearing one title.
- **`holds:` gains a third case, decided locally.** One `git cat-file -e`
  against `refs/remotes/origin/<base>`. The reader has no network and needs
  none: whether the base branch carries the file is a local question.
- **The `pr:` line keeps the exemption and drops the claim.** Naming a `pr:`
  is what makes the work Loop step 2's, whatever the state — so it says that,
  and says the state is unreadable here, which is what `drain` already says.

## Rejected

- **Making `janitor` read the pull request's state.** It would be the better
  sentence and it needs a token and a network call in a reader that
  deliberately has neither. The honest wording costs nothing.
- **Marking the third case a defect of the claim.** A plan on an unmerged
  branch is not a mistake by its author; it is how an unmerged branch works.
  The line now says what releasing buys, not that anybody erred.

## Review

- r1: (session) **the first fixture silently tested nothing.**
  `git checkout main` removes `docs/handover/` once it is empty there, so the
  new case's redirect failed and only its plan was committed — the branch was
  never a candidate, and three assertions failed for a reason that looked like
  the fix being wrong. The working `parked` fixture does `mkdir -p` first and
  I had dropped it. Found by probing the fixture's index at commit time
  (`status --porcelain` showed `?? docs/plans/ownplan.md` and `ls` showed the
  directory absent), after three cheaper probes that only narrowed it.
  (fixed — `mkdir -p` restored, with a comment saying why it is there, since
  the failure mode is a silent redirect rather than an error.)
- r2: (session) **the first mutation proved nothing and looked like proof.**
  `elif true; then` on a line that was a multi-line `elif git ... \`
  continuation orphaned the next line, broke the script, and redded **1010
  cases** off a green baseline. A mutation that reds a thousand cases says
  nothing about one clause. (fixed — the second mutation appends
  `|| true` to the condition's own line, keeping the syntax valid so only the
  cases that depend on the clause can red. Its verdict is what `next:` waits
  on.)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_janitor` — the candidate block, both printed lines.
- `.agents/harness/selftest/janitor.sh` — the `parked` fixture is the case
  where the old `holds:` line was TRUE, which is why nothing caught it.
