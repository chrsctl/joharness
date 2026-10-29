---
research: ceremony-commit-cost
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/handover.md
---

## Question

Which of the claim, handover-only and retire commits could ride on a
neighbouring commit, without losing claim-by-push, the same-commit
handover rule, or the retire-before-PR rule?

## Echo

In gx, about a quarter of all commits are bookkeeping, not product. If
some of them buy no guarantee, they cost every pull request a commit, a
push and a CI run for nothing. If each buys one, the answer is "keep,
because", recorded where the next person who asks will find it.

## Sweep

`goal-directed`: every commit kind the Loop asks for, the rule that asks
for it, and whether a neighbouring commit could carry it instead.

## What would settle it

For each kind, a yes or no, each with the rule that makes it a separate
commit or the reason none does:

- the claim push, needed before code exists;
- the handover-only commit;
- the retire commit, needed as the LAST commit before the PR.

Plus a count from gx history of how many commits each "yes" removes.
Either outcome settles the question.

## Method

Baseline count, all non-merge commits in gx since 2026-10-15, by first
word of the subject:

```bash
git -C <gx> log --since=2026-10-15 --no-merges --format=%s \
  | awk '{print tolower($1)}' | sed 's/:$//' | sort | uniq -c | sort -rn
```

A plan-checker run on 2026-10-29 gave 2144 commits, of which at least 554
open with handover, claim or retire (about 26%).

Rules: read `.agents/harness/AGENTS.md` Loop steps 3, 6 and 7,
`.agents/docs/handover.md`, `.agents/docs/plans.md` § Lifecycle, and the
claim reader in `.agents/harness/queue-context.sh`. For each kind, name
the reader that needs it as its own commit.

## Findings

None yet.

## Consequence for the queue

None yet. A "yes" becomes one plan editing the rule that allows the fold.

## Verification

Per `.agents/docs/research.md` § Verification.

## Graduates to

`.agents/docs/handover.md` — the answer, as a rule or a "keep, because".
