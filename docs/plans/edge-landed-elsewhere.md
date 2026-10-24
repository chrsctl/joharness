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

- `.agents/harness/handover-context.sh` — `lead_why` (the text `dispatch` prints after `FINISH BEFORE STARTING:`) and the `EDGE:` lines, for every edge rank (0, 1, 2):
  - `pr_num` reads a `pr:` URL as its trailing number as well as `#N`. When `origin/<base>` carries a first-parent `Merge pull request #<pr> from` commit and `git rev-list --count origin/<base>..<branch>` is N > 0, `lead_why` and the `EDGE:` text say `N commit(s) after merged PR #<pr>`. N = 0 changes nothing.
  - For `status: done` whose `plan:` file `origin/<base>` lacks, add `plan gone from <base>: landed elsewhere? confirm in merged history, then release` to `lead_why` and `EDGE:` ONLY when `git log origin/<base> --diff-filter=D -- docs/plans/<plan>.md` shows base once carried and deleted it. A plan never on base (same-session plan) prints nothing new.
  - Reword the rank-2 line "closed, open and merged-elsewhere are the same bytes here" so it stays true.
- `.agents/harness/selftest/handover-context-rank.sh` — one case per new text, each failing without the change, including a `pr:` URL fixture and a same-session-plan fixture that prints nothing new.
- `.agents/docs/handover/README.md` — status table: one line saying the listing proves only these two facts and never closes a claim.

## Assumptions

- A1: the edge text "status done and unmerged" is built in `handover-context.sh` — evidence: `grep -n "done and unmerged" .agents/harness/handover-context.sh` — confidence: high
- A2: git alone reads the merge commit; no GitHub call — evidence: issue #594, `git log --first-parent --grep` — confidence: high
- A3: `dispatch` prints only `lead_why` from the hook, so the Goal needs `lead_why` changed — evidence: `joharness.sh:cmd_dispatch` sed on `hout`, `handover-context.sh:lead_why` — confidence: high

## Out of scope

- `janitor --apply` releasing the case, or a new status word: handover protocol text, a human's call; the issue calls them proposals.
- `.claude/commands/orchestrate.md` naming who takes stale edge work.
- `pr:` values other than a number, `#N` or a URL ending in a number.
- Any GitHub API call: harness commands never make one.

## Acceptance

- `./joharness.sh ci` — pass.
- `./joharness.sh verify` — 0 failed.
- `./joharness.sh dispatch` on a fixture with the issue's case 1 and case 2 prints the new `lead_why` text.
- New selftest fails with the `handover-context.sh` change reverted.

## Where to look

- `.agents/harness/handover-context.sh:rank` — EDGE and lead_why lines.
- `joharness.sh:cmd_janitor` — "holds: ... frees nothing" wording to match.
- `.agents/harness/selftest/handover-context-rank.sh` — fixture style.

## Traps

- No non-`*.md` edit under `.agents/harness/` outside a session holding this plan.
- The listing states facts git proves; it never writes `abandoned`.
- Test for a fix must FAIL without it.
