---
workstream: issue-claim-edge
status: review
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: issue-claim-edge
issue: 119
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Retire plan + workstream file, open the pull request, merge on green checks.
---

## Goal

Issue #119, which this session caused: two sessions solved #114 in parallel
because a claim on an issue cannot be represented. Give the issue the same
stable frontmatter edge a plan already has.

## Decisions

- This file carries `issue: 119` from its first commit — the field claiming
  the issue that asks for the field. If the implementation is right, the hook
  will print that claim on the next session start, which is the acceptance
  criterion running against itself.
- Field, not derived grep. Chosen by the requester 2026-08-29 after I argued
  the opposite in #119 on rot grounds. I was wrong: `status:` rots because
  its value changes over time; an issue number never does, and `plan:` is an
  accepted stable edge of exactly this shape. A derived grep fails toward
  "free", which is the direction that caused the duplicate.
- The hook stays offline. It reads git refs and nothing else, and it ships to
  every consumer; a hook needing a token to say what is claimed fails closed
  in the repos that most need it.

## Rejected

- Fixing the inherited-file case here. A branch that merely inherits a
  workstream file carrying `issue:` reads as claiming it, because the hook
  enumerates with `files_at` (`git ls-tree`) — the tree, not the diff. That
  is the rule `.agents/harness/AGENTS.md` step 4 states flatly and that six
  merged edges paid for, and it is `handover-inflight-diff`'s to fix: that
  queued plan changes `files_at` for every reader at once, and forking it
  here would leave two ownership tests. What this branch does instead is
  print the FILE beside each claim, so one inherited file reads as one claim
  rather than five branch names.
- Rejecting `99999999999999999999`. Nonsense as an issue number, accepted by
  both validators, and left that way: a ceiling would be arbitrary, and two
  validators agreeing on a silly value beats them disagreeing on a plausible
  one.

## Review

Round 1, `.claude/agents/verifier.md` at opus. Thirteen findings; five
severe, and every severe one was the same shape — a REAL claim rendered
invisible, never a fake one rendered visible. That is the failure the field
exists to prevent, reproduced five ways inside the fix for it.

- r1 (verifier): `MAX_ENTRIES` broke the ref loop before claims were banked.
  Measured on this repo: 12 entries printed against 46 branches carrying
  workstream files. Refs sort newest-first, so the OLDEST claim vanished
  first — the long-running one, the most likely to be duplicated. The cap
  now bounds the entry listing only. (fixed)
- r2 (verifier): `status: done` skipped the claim. That status is set before
  the merge, and step 7 leaves a merge the session cannot click on a human's
  clock; the issue is claimed and pushed throughout that window. Claim now
  banked before the skip. (fixed)
- r3 (verifier): the claim goes dark from PR-open to issue-close, because
  step 7 retires the file the claim lives in. Not fixable by the field, and
  claiming otherwise would be the false-confidence version of the bug. The
  protocol now names the seam and what covers the far side. (fixed as
  documentation, which is the honest fix)
- r4 (verifier): an inherited file fanned one claim across five branches.
  (mitigated — see Rejected; root cause is `handover-inflight-diff`'s)
- r5 (verifier): this branch's own claim never reached the consolidated
  block, so the hook printed "claims issue #119" and "none — no in-flight
  workstream file claims an issue" in one run, on the branch adding the
  field. The empty case was also the one branch without a hedge. (fixed)
- r6 (verifier): the plan's consumer-safety acceptance said output would be
  identical; it is three lines longer, deliberately, and nothing recorded
  the reversal. (fixed in the plan)
- r7 (verifier): the lint had zero tests — deleting its whole case block left
  the suite green. The evidence it worked was a scratch file committed and
  then deleted rather than promoted. Five fixtures now. (fixed)
- r8 (verifier): `0114` and `0` passed both validators. Padded renders
  perfectly and still gets duplicated, because a reader scanning for `#114`
  does not match `#0114` — the severe direction wearing the harmless one's
  face. (fixed; validators proven to agree across 25 values)
- r9 (verifier): the protocol said a bad claim is "never silent"; the hook is
  silent and a fixture pins that silence. The noise is `ci`'s, on the owning
  branch. Reworded to say which reader hears it. (fixed)
- r10 (verifier): the new selftest block was inserted mid-sentence in another
  step's comment banner. (fixed)
- r11 (verifier): fixture cleanup diverged from both neighbours and swallowed
  a delete failure they do not. (fixed)
- r12 (verifier): this file was stale against what shipped — `next:` false,
  `## Rejected` empty while the plan recorded two. (fixed, here)
- r13 (verifier): the #114 anecdote was written into five shipping places
  against state-each-fact-once. `TEMPLATE.md` is a pointer now. (fixed)

Round 2, mine, fixing round 1.

- r14: `claimed_issues` was initialised after the current-branch block that
  appends to it, so under `set -u` the entire handover section died — no
  workstream file, no in-flight work, no claims. A hook built to prevent a
  false "nobody is on this" failed by reporting nothing at all. (fixed)
- r15: the empty-case fixture pinned wording I then changed while adding the
  hedge, and failed — a token assertion doing its job. Added the assertion
  that should have been first: the empty case is hedged, not absolute.
  (fixed)

Process, recorded rather than hidden: I told the verifier the branch was
frozen at `e39b86b` and then pushed an anchor fix while it worked. It caught
that too. A freeze that moves is not a freeze.

## Review

Not yet run: no edge, no pull request open.

## Blockers

None.

## Where to look

- `.agents/harness/handover-context.sh` — the `fields` reader and the two
  print sites.
- `joharness.sh:lint_graph` — where the field gets validated.
