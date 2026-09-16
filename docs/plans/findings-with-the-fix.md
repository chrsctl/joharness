---
plan: findings-with-the-fix
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

  Read each bullet's disposition marker too, with the parser
  `lint_finding_markers` already uses. A `(wontfix ...)` finding has no fix
  to share a commit with, so the check must exempt it — Acceptance requires
  that, and an algorithm that omits the marker read cannot deliver it.

- `.agents/harness/selftest/ci-finding-order.sh` — its topic file.
- `.agents/harness/selftest.sh` — register the topic.

## Out of scope

- The "before the fix" half. Unverifiable from git, per the Goal. A check
  that claims to enforce it would be a gate asserting something it cannot
  see, which is worse than no gate.
- The rest of issue #251. A sampling conduct reviewer is a session beyond
  the cap, which is the human's money, and the issue itself does not claim
  the cost is worth it. Three of its other four questions need a
  control-plane read or the diff. The fourth, peer divergence — managers
  applying one rule two ways — is closer to this one than a blanket
  grouping suggests: the workstream files it would compare are artifacts the
  session-start hook already reads, no session required. What separates it
  is judgement, not cost: deciding two branches faced the SAME rule means
  reading free text, and a check that guesses at sameness reports
  disagreements that are not. Filed as its own question rather than bundled,
  so whoever takes it starts from that distinction.
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
  finding whose commit touches only the workstream file; a finding recorded
  in the same commit as the FIRST PART of a fix that continues in a later
  commit, which is compliant because its own commit carries fix content; and
  a workstream file this branch only INHERITED. Note the second shape is not
  "alone" — a finding whose commit carries no fix content at all is the
  violation, whether or not a fix arrives later.
- Backtested before it is trusted, over the same window `feedback` walks —
  `JOHARNESS_FEEDBACK_EDGES`, whose default the code carries — so the window
  is a value the implementing session reads rather than a letter this plan
  left unbound. Report two numbers with the command and the date in the pull
  request body: findings examined, and findings the check would name. No
  pass threshold is set here, deliberately: the report-only strength means
  nothing reds on the number, and the number's job is to tell whoever reads
  it whether the rule is widely broken (so the check is right and the repo
  has a habit to fix) or the check is wrong. A ceiling comes later on that
  evidence, as `churn`'s did.

- SHIPS: this plan touches `joharness.sh`, so `ci`'s ship-scope stage flags
  it and `.agents/docs/plans/README.md` requires a consumer-side check. Name
  one: in a consumer, `./joharness.sh ci` on a branch carrying a workstream
  file with one finding committed alone prints the new stage and names that
  bullet. The topic file cannot cover this — the selftest tree is
  canonical-only and ships nowhere — so it is a check somebody runs there,
  stated here because the bar is met in the repo that was never the risk
  otherwise.


## Where to look

- `joharness.sh:fb_fix_map` — READ THIS FIRST. It already solves the hard
  half: it keys on the stable `r<N>` id across every commit in a range
  rather than on a bullet's current text, and its own comment carries the
  reason — a bullet as committed may predate its own disposition marker. The
  query in Scope was tested against exactly that case on this repo's history
  (a finding whose verdict was edited in a later, workstream-only commit) and
  lands on the adding commit, not the edit. Reuse the mechanism rather than
  rebuilding it.
- `joharness.sh:lint_finding_ids` — the bullet parser to reuse, and the
  report-only doctrine with its reasoning.
- `joharness.sh:lint_finding_markers` — the same parse, the other strength,
  and why that one reds.
- `.agents/docs/handover/README.md`, Reviewing — the rule being checked, and
  the measurement behind it.

## Traps

- A finding sharing a commit with ANY part of its fix is compliant; a
  finding whose commit carries no fix content is the violation. "Alone"
  means no fix content in that commit, never "the fix is not finished" —
  reading it the second way reports every branch that fixes across two
  commits.
- Escalate to opus if the false-positive shapes turn out not to be
  separable from the violation by commit membership alone — that is a
  wrong-but-plausible gate, which is the opus condition.
