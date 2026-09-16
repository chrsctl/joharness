---
plan: findings-before-the-fix
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: joharness.sh, .agents/harness/selftest.sh, .agents/harness/selftest/ci-finding-order.sh
---

## Goal

Issue #251's one conduct question that costs nothing to ask. Loop step 5
requires a review finding to be recorded BEFORE its fix and in the SAME
commit. Nothing checks either half.

**Only the second half is checkable, and the first is not checkable at all.**
Git records what landed in a commit, never the order the author typed it, so
"before the fix" leaves no trace. Tested on this repo before this plan was
written: the finding that motivated the question, `r16` on the branch that
merged as `#253`, was written after its fix and committed WITH it, and passes
the same-commit test. Say this out loud in the lint's own comment, or the next
reader spends a session trying to recover authoring order from git.

What survives is worth having anyway. A finding line added in a commit that
touches nothing but the workstream file means the findings were written up as
a separate documentation pass, which is the shape the rule exists to stop.

## Scope

- `joharness.sh` — a third finding lint beside `lint_finding_ids` and
  `lint_finding_markers`, reading the same `## Review` bullets. For each
  `- r<N>:` line on this branch, find the commit that ADDED it and ask
  whether that commit touches anything besides the workstream file.

  The query is not obvious and the obvious one is wrong. Verified on this
  repo, 2026-09-16:

  ```bash
  git log --all --format=%H -G'^- r18:' --full-history --reverse -- <ws> | head -1
  git show --name-only --format='' <that commit>
  ```

  `--reverse | head -1` is load-bearing. Without it the newest match comes
  first, and for a retired workstream file that is the RETIRE commit, which
  deletes every finding line at once and touches the plan file beside it —
  so the naive query reports the wrong commit and then passes it.

- `.agents/harness/selftest/ci-finding-order.sh` — its topic file.
- `.agents/harness/selftest.sh` — register the topic.

## Out of scope

- The "before the fix" half. Unverifiable from git, per the Goal. A check
  that claims to enforce it would be a gate asserting something it cannot
  see, which is worse than no gate.
- The rest of issue #251. A sampling conduct reviewer is a session beyond
  the cap, which is the human's money, and the issue itself does not claim
  the cost is worth it. Its other four questions need control-plane reads,
  peer comparison or a sampling rate nobody has calibrated.
- Any change to what `review` prints or to `JOHARNESS_REVIEW`.
- Reading the diff. This check reads commit membership, never content: that
  is what keeps it cheap and what distinguishes it from the verifier.

## Acceptance

- `./joharness.sh ci` — `ci: pass` on a branch whose findings share a commit
  with their fix, and the new stage names the offending bullet on one whose
  findings landed alone. Both states asserted in the topic file: a lint
  asserted in one direction passes when it is deleted.
- The retire-commit trap is asserted: a fixture whose workstream file is
  retired, where the naive query would report the retire commit. The case
  fails with `--reverse` removed and passes with it.
- REPORT-ONLY, never `rc=1`. `lint_finding_ids` is the precedent and its own
  comment carries the reason: a gate that fires on an honest branch is one
  sessions route around. It earns a ceiling later on a backtest, as `churn`
  did.
- Three false-positive shapes asserted as NOT reported: a `(wontfix ...)`
  finding whose commit touches only the workstream file, a finding whose fix
  lands across two commits with the finding in the first, and a workstream
  file this branch only INHERITED.
- Backtested before it is trusted: run it over the merged branches the
  `feedback` window already walks, and put the count of findings it would
  name, with the command and the date, in the pull request body. No
  threshold is set here on purpose — the number is the evidence for whether
  the rule or the check is wrong, and whoever runs it reports it rather than
  passing a bar somebody guessed.


## Where to look

- `joharness.sh:lint_finding_ids` — the bullet parser to reuse, and the
  report-only doctrine with its reasoning.
- `joharness.sh:lint_finding_markers` — the same parse, the other strength,
  and why that one reds.
- `.agents/docs/handover/README.md`, Reviewing — the rule being checked, and
  the measurement behind it.

## Traps

- A finding and its fix in one commit is the rule; a finding ALONE in a
  commit is the violation. Inverting that reds every honest branch.
- Escalate to opus if the false-positive shapes turn out not to be
  separable from the violation by commit membership alone — that is a
  wrong-but-plausible gate, which is the opus condition.
