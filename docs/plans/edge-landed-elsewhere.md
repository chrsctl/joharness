---
plan: edge-landed-elsewhere
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: 594
scope: .agents/harness/handover-context.sh, .agents/harness/selftest/handover-context-rank.sh, .agents/docs/handover/README.md
---

## Goal

`dispatch` says "finish before starting" about a `status: done` branch whose
plan file `main` no longer carries, and says only "held" about a branch whose
`pr:` merge commit is on `main` while its tip is ahead. Both are facts git
already holds (issue #594, measured on a consumer). The edge listing must say
what git can prove: "N commits after a merged PR", and "plan gone from main:
landed elsewhere? confirm in merged history, then release".

## Scope

- `.agents/harness/handover-context.sh` — edge entry (rank 0..2): when the
  entry's `pr:` names a number and `origin/<base>` carries a first-parent
  `Merge pull request #<pr> from` commit, print `N commit(s) after merged PR
  #<pr>` (N = `git rev-list --count origin/<base>..<branch>`) in place of
  "CHECK IT IS OPEN"; N = 0 prints nothing new. When `plan:` names a file
  `origin/<base>` lacks, status `done`, print `plan gone from <base>: landed
  elsewhere? confirm in merged history, then release` after the EDGE line.
- `.agents/harness/selftest/handover-context-rank.sh` — one case per new line, each failing
  without the change.
- `.agents/docs/handover/README.md` — status table: one line saying the
  listing proves only these two facts and never closes a claim.

## Assumptions

- A1: the edge text "status done and unmerged" is built in `handover-context.sh` — evidence: `grep -n "done and unmerged" .agents/harness/handover-context.sh` — confidence: high
- A2: git alone reads the merge commit; no GitHub call — evidence: issue #594, `git log --first-parent --grep` — confidence: high
- A3: `FINISH BEFORE STARTING` is derived from the same lead entry — evidence: `joharness.sh:cmd_dispatch` sed on `hout` — confidence: medium

## Out of scope

- `janitor --apply` releasing the case, or a new status word: handover protocol text, a human's call; the issue calls them proposals.
- `.claude/commands/orchestrate.md` naming who takes stale edge work.
- Any GitHub API call: harness commands never make one.

## Acceptance

- `./joharness.sh ci` — pass.
- `./joharness.sh verify` — 0 failed.
- New selftest fails with the `handover-context.sh` change reverted.

## Where to look

- `.agents/harness/handover-context.sh:rank` — EDGE and lead_why lines.
- `joharness.sh:cmd_janitor` — "holds: ... frees nothing" wording to match.
- `.agents/harness/selftest/handover-context-rank.sh` — fixture style.

## Traps

- No non-`*.md` edit under `.agents/harness/` outside a session holding this plan.
- The listing states facts git proves; it never writes `abandoned`.
- Test for a fix must FAIL without it.
