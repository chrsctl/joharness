---
workstream: an-injection-live-under-a-dispatched-reader
status: review
branch: claude/an-injection-live-under-a-dispatched-reader
pr: none
plan: an-injection-live-under-a-dispatched-reader
issue: none
session: https://claude.ai/code/session_013sNLp7abB3bjEtXFdikfuE
agent: opus
updated: 2026-10-10
next: Run ci + verify, retire handover, PR, merge
---

## Goal

Settle docs/research/an-injection-live-under-a-dispatched-reader.md: which
file carries the rule that a working-tree mutation and a dispatched read-only
reader are mutually exclusive. Graduate the answer, delete the node.

## Decisions

- Candidate A (subagents.md) holds the rule and the why; step 5 gets a
  one-clause pointer, the Loop pattern of rule-line plus docs-why, because
  step 5 is where the collision is ordered and every session meets it.
- Candidate E is gone: `mutate` was removed (a33db1d), so the node's
  findings 1-2 are stale; the collision survives as a hand-rolled revert
  ordered by step 5's "must FAIL without it".
- Diff touches AGENTS.md beyond the graduation target: research README
  says both "only itself and its target" and "rule line in AGENTS.md, why
  under docs"; took the second, as earlier graduations did.

## Rejected

- B (verifier brief) as the home: it can make a moved tree legible, not
  stop the spawner moving it; prevention is the spawner's, one home.
- `isolation: worktree` as the escape: subagents.md says it branches from
  the default branch, so it would not hold the diff under review. The
  manual `git worktree add --detach <sha>` does, so the rule offers it.
- D (feedback.md): page is about recorded findings, not dispatch.
- F (consumer only): step 5 orders the revert with no consumer script.

## Review

- r1: (verifier) subagents.md rule banned every edit while any subagent lives, contradicting manager workers on disjoint files (fixed: scoped to a reviewer that measures the work, workers named as covered by manage.md)
- r2: (verifier) step-5 clause said only "revert", narrower than the rule's revert/inject/edit (fixed: "Tree holds still while your verifier lives")
- r3: (verifier) incident cited without commit, and as "reverted" where the node says injection script (fixed: cites consumer commit 9c69b8e9 and the node's recovery command; wording matches node)
- r4: (verifier) rejection of the brief home argued against a git-status-snapshot strawman and dropped the node's pinning finding (fixed: rejection restated as legibility-not-prevention; detached worktree offered as the alternative)
- r5: (verifier) handover Where to look pointed at removed `mutate` (fixed: line dropped)
- r6: (verifier) "with no order between them" stale in the commit adding the order (fixed: past tense)
- r7: (verifier) AGENTS.md line at 83 columns (fixed: rewrapped)
- r8: (verifier) diff touches a file beyond the graduation target (no change: recorded under Decisions)

## Blockers

None.

## Where to look

- `.agents/docs/subagents.md` — declared graduation target.
- `.claude/agents/verifier.md` — reader-side candidate.
