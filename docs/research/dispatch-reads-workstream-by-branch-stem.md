---
research: dispatch-reads-workstream-by-branch-stem
urgency: normal
agent: sonnet
effort: medium
graduates: joharness.sh
---

## Question

Does `./joharness.sh dispatch` state a manager's status and recorded-finding count from a workstream file it fails to find when the branch name carries a suffix after the workstream stem, when `./joharness.sh review` reads the same file and counts in full?

## Echo

On a consumer, `dispatch` printed `0 finding(s) recorded` and status `?` for a branch whose workstream file holds 113 `## Review` findings and `status: in-progress`. `review`, on that same head, counted 113. If `dispatch` finds the file through the branch name rather than through the claim or the file's own `branch:` field, every session-suffixed branch (`claude/<stem>-<session id>`) reads as unknown with no findings. Its `CEILING?` warning also drops away. The orchestrator reads `dispatch` to judge liveness and cost, so this matters.

## Sweep

`goal-directed`: one branch, two branch names for the same head, one variable changed (the suffix). Not a survey of every consumer branch.

## What would settle it

The same branch head, with the same local refs and the same harness files, run under two remote branch names: `claude/agent-react-components-01J1YMK4` (as merged) and `claude/agent-react-components`. If `dispatch`'s status and finding count change with the name while `review`'s does not, the lookup is by branch stem. If they do not change, the cause is elsewhere.

## Method

All of this ran in a throwaway local clone of the consumer `chrsctl/gx`. Nothing was pushed. The harness files came from gx `origin/main` ed5c2482d, and `joharness.sh` there is byte-identical to canonical `main` 43b8bd22 (`diff -q` clean).

```
git clone -q --shared --no-checkout <gx> clone && cd clone
git update-ref refs/remotes/origin/main 6353b7ee8e58         # PR1215's merge base
git update-ref refs/remotes/origin/claude/agent-react-components-01J1YMK4 0da93c188   # its pre-retire head
# every other refs/remotes/origin/* deleted
git checkout -q -B claude/agent-react-components-01J1YMK4 0da93c188
git checkout -q ed5c2482d -- joharness.sh .agents/harness .agents/env   # current harness
./joharness.sh review   | grep "finding(s)"
./joharness.sh dispatch | grep -A1 "agent-react-components.md"
# then the same head under the stem alone:
git update-ref -d refs/remotes/origin/claude/agent-react-components-01J1YMK4
git update-ref refs/remotes/origin/claude/agent-react-components 0da93c188
./joharness.sh dispatch | grep -A1 "agent-react-components.md"
```

The workstream file at that head is `docs/handover/agent-react-components.md`. Its frontmatter carries `workstream: agent-react-components`, `status: in-progress`, `branch: claude/agent-react-components-01J1YMK4`.

## Findings

- **With the suffixed branch name, `dispatch` reads no workstream file: status `?`, `0 finding(s) recorded`, and no `CEILING?` line.** `review` on the same head counts 113.
  ```
  review:   113 finding(s) recorded
  dispatch: docs/product/agent-react-components.md  claude/agent-react-components-01J1YMK4  ?  pushed 108h  head 0da93c1881d6  base ok  STALL? no push for 108h (>= 45m): cross-check the control plane
            work: 15 commit(s) since main, 0 finding(s) recorded
  ```
- **The same head under the bare stem reads in full.** Status, findings and the ceiling check all return.
  ```
  dispatch: docs/product/agent-react-components.md  claude/agent-react-components  in-progress  pushed 108h  head 0da93c1881d6  base ok  STALL? no push for 108h (>= 45m): cross-check the control plane  CEILING? 111h since the claim, no pr: — REPORT it with the control plane's cost (.claude/commands/orchestrator.md)
            work: 15 commit(s) since main, 113 finding(s) recorded
  ```
- **A branch whose name equals its stem shows no disagreement.** `manager/reeve-ux-inbox-thread` on gx: `dispatch` 24, `review` 24.
- First seen by gx PR #1215's verifier (workstream r78), recorded there as "no change: a harness observation outside the item, PR body". It was never routed until this report.

## Consequence for the queue

`joharness.sh`'s `dispatch` should find a branch's workstream file the way `review` does: from the claim's stem, or from the file whose `branch:` field names the branch. It should not derive the filename from the branch name. Its selftest (`.agents/harness/selftest/dispatch.sh`) should gain a branch whose name carries a suffix. Canonical decides. This is a report from a consumer, not a fix.

## Verification

Not yet verified from an independent context. The findings above are the reporter's own measurements, each with its command. GROUNDED for the gx head and harness named in Method; whether canonical's other consumers name branches this way was not checked.

## Graduates to

`joharness.sh`, because the lookup lives in `dispatch`. The selftest that should hold the case is `.agents/harness/selftest/dispatch.sh`.
