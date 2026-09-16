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

Issue #251's one conduct question that costs nothing to ask: were a branch's
review findings recorded BEFORE their fix and in the SAME commit, as Loop
step 5 requires? Nothing checks it. The rule's whole value is that a finding
written after its fix describes the fix rather than the problem, and the
reviewer conversation it was meant to preserve is gone by then.

Live counter-example from this week: the branch that merged as `#253`
recorded two findings after their fixes and left them uncommitted through a
review round. A verifier caught it; no gate did.

## Scope

- `joharness.sh` — a third finding lint beside `lint_finding_ids` and
  `lint_finding_markers`, reading the same `## Review` bullets. For each
  `- r<N>:` line on this branch, find the commit that ADDED it and ask
  whether that same commit touches anything besides the workstream file.
- `.agents/harness/selftest/ci-finding-order.sh` — its topic file.
- `.agents/harness/selftest.sh` — register the topic.

## Out of scope

- The rest of issue #251. A sampling conduct reviewer is a session beyond
  the cap, which is the human's money, and the issue itself does not claim
  the cost is worth it. Four of its five questions need control-plane reads,
  peer comparison or a sampling rate nobody has calibrated. They stay filed.
- Any change to what `review` prints or to `JOHARNESS_REVIEW`.
- Reading the diff. This check reads commit membership, never content: that
  is what keeps it cheap and what distinguishes it from the verifier.

## Acceptance

- `./joharness.sh ci` — `ci: pass` on a branch whose findings are recorded
  correctly, and the new stage names the offending bullet on one whose
  findings are not. Both states asserted in the topic file, because a lint
  asserted in one direction passes when it is deleted.
- REPORT-ONLY at first, never `rc=1`. `lint_finding_ids` is the precedent
  and the reason is in its own comment: a gate that fires on an honest
  branch is one sessions route around. It earns a ceiling later on a
  backtest, the way `churn` did.
- The three false-positive shapes are each asserted as NOT reported: a
  `(wontfix ...)` finding whose commit touches only the workstream file, a
  finding whose fix legitimately lands across two commits with the finding
  in the first, and a workstream file this branch only INHERITED.
- Backtested before it is trusted: run it over the last N merged branches
  and report how many findings it would name. A number, with the command,
  in the pull request body. If it names most of them the rule is wrong or
  the check is, and either way it does not ship as written.

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
