---
plan: orchestrator-edge-slot-leak
urgency: urgent
agent: opus
effort: xhigh
needs: none
requirement: orchestrated-mode
scope: joharness.sh, .claude/commands/orchestrate.md
---

## Goal

The fix for `orchestrator-inflight-count` counts every unmerged branch whose
workstream file was retired as a committed slot. In the consumer it landed in,
five such branches exist, aged 70h to 613h, and **none of them is a merge in
flight**: the repository has zero open pull requests and every item they name
has already merged by another route. Cap 4, five leftovers, so
`slots : 0 of 4 free` — permanently. Nothing can be spawned, and the verdict
can never read DRAINED.

The plan that asked for the count named this exact risk and it shipped anyway:

> The row must still be distinguishable from a genuinely abandoned branch, or
> this trades a duplicate-spawn defect for a slot that never frees.
> — `docs/plans/orchestrator-inflight-count.md`, Scope

That is the trade that was made. The duplicate-spawn defect is gone and the
fleet is stopped instead, which is the worse half: a duplicate costs one
manager, and this costs every manager the queue would ever have spawned.

## The measurement

Consumer `chrsctl/gx`, 2026-09-06 23:13Z, immediately after the sync PR #308
brought the fix in. `./joharness.sh dispatch`:

```
slots     : 0 of 4 free
```

The five rows, each `PR in flight, no claim file`, checked one at a time
against GitHub and against `origin/main`:

| branch | push age | item the row names | where that item actually merged |
| --- | --- | --- | --- |
| `claude/continue-bzq5sk` | 613h | `?` — none | — |
| `claude/eval-corpus-hardening-uxt0gy` | 226h | eval-corpus-hardening | #126, from the sibling branch `…-ydyilv` |
| `claude/permission-system-large-companies-0tke0t` | 70h | permission-system-at-ten-thousand-seats | #290, from the branch of that name |
| `claude/replay-age-impl-uxt0gy` | 241h | replay-age | #100, from the sibling `claude/replay-age-uxt0gy` |
| `claude/revisions-audit-trails-94qa1b` | 206h | crm-change-review (+ crm-revisions-ui) | #191 and #194, from that same branch |

`mcp__github__list_pull_requests(state: open)` on the repository returns `[]`.
There is no pull request behind any of these rows, so "PR in flight" is an
inference from git shape, and it is wrong five times out of five.

Following the row's own instruction would have made it worse. It says to look
the title up and, if the session is gone, *"respawn on the branch to FINISH
it, never to restart the item"*. There is nothing to finish: the items merged
weeks ago. A successor spawned onto `claude/replay-age-impl-uxt0gy` finds
merged work, no pull request, and a plan file absent from `main`.

## The discriminator, which IS in git

The code's comment says the difference cannot be found there:

```
# Distinguishable from a genuinely abandoned branch, which is the other
# thing this shape can be — and the difference is not in git. Push age is
# the one signal here, …
```

For a row that NAMES an item, it is in git, and it is one `git cat-file -e`:

**Is the item still present on `origin/main`?**

- **Present** → genuinely mid-merge. Step 7 retires the file on the *branch*;
  `main` keeps it until the merge lands. Hold the slot. This is the true
  positive the count was built for.
- **Absent** → the item was retired by a merge that already happened, by this
  branch or any other. The branch is a leftover. It holds nothing.

Checked against all five above: absent in all five, and absent is the correct
answer in all five. Checked against the shape it must not break — a manager at
step 7 with its pull request open — the file is still on `main`, so the slot is
still held. The check discriminates; push age does not, because a manager can
sit quiet past 45m with a real pull request open and a leftover can be minutes
old.

Push age stays useful for the row's prose. It is not the thing that decides
whether money is committed.

## Scope

- Read the item off the edge row and ask whether it exists on the base branch.
  Absent: do not count the branch in `n_inflight`, and print it as a leftover
  — a row that says the item already merged and that the branch is the
  human's to delete. Present: unchanged, count it.
- The `?` row (no item, so nothing to look up) cannot use this. It is already
  routed to the human and must stay so. But it must not hold a slot forever
  either: 613h with no item and no pull request is not a commitment, it is
  litter. Decide one rule and say it in the row — a leftover past some
  multiple of the stall window is reported and not counted, or it is counted
  and the verdict names it as the reason the fleet is stopped. Either is
  defensible; silence is not, because today the orchestrator reads
  `0 of 4 free` with no way to act.
- `.claude/commands/orchestrate.md`: the health table's last two rows tell the
  orchestrator to respawn to finish a merge. Say that a row whose item is gone
  from the base branch is NOT that case, and is never respawned.
- Say in the verdict when zero slots are free *because of leftovers rather
  than managers*. Those are opposite situations — one is a fleet at capacity,
  one is a fleet that has stopped — and today they print the same line.

## Out of scope

- Reverting the count. The undercount it fixed was measured 15 times in one
  run and is real; this is a missing discriminator, not a wrong idea.
- Deleting branches. A session never `git push --delete`
  (`.agents/docs/product/README.md`, Branch flow). The row tells the human.
- Anything about push age as a stall signal. That part is fine.

## Acceptance

- A fixture branch, unmerged and ahead of base, whose workstream file is
  retired and whose **item is absent from the base branch**, is NOT counted in
  `slots` and prints as a leftover naming the human as the one who clears it.
- The same fixture with the item **present** on the base branch IS counted and
  prints unchanged. Both, or the check pins nothing — this is one boolean and
  a fixture that only exercises one side proves only that the code runs.
- Injected-defect check: with the discriminator removed, the first fixture
  must be counted again. If it stays uncounted the fixture is on the wrong
  side of the boundary (`.agents/harness/AGENTS.md`, injected the defect and
  it stayed GREEN).
- The verdict distinguishes "0 slots, N managers working" from "0 slots, N
  leftovers". Asserted on `dispatch` output, not on a helper — the fix is in
  the reader, so drive the reader.
- **Consumer-side** (this plan SHIPS): `chrsctl/gx` at 2026-09-06 23:13Z is the
  reproduction, and it needs no setup — the five branches are on the remote.
  After the fix, `./joharness.sh dispatch` there must report the one live
  manager's slot and free the rest.

## Where to look

- `joharness.sh`, the `--- edges past the retire commit` block (around the
  `PR in flight, no claim file` row): `n_inflight` and `n_edge` are
  incremented before anything asks whether the branch is really committed.
  The comment beginning *"Distinguishable from a genuinely abandoned branch"*
  is the sentence this plan contradicts, and it should be rewritten rather
  than left standing next to the new check.
- `.claude/commands/orchestrate.md`, the two rows added for the edge case, and
  the paragraph beginning *"These rows carry no `session:` line"*.
- `docs/plans/orchestrator-inflight-count.md`, Scope — the risk, named before
  the fix was written.

## Traps

- Do not decide it from the presence of an open pull request. `dispatch` is
  git-only and offline by design; reaching for a forge API here makes the
  queue's core read depend on a network and on credentials the harness does
  not require.
- Do not use push age as the discriminator. A quiet manager with a real pull
  request open and a leftover pushed ten minutes ago are indistinguishable by
  age, and the first is the case that must keep its slot.
- The item's absence is evidence about the BASE branch at read time, so read
  the base the branch actually targets, not a hardcoded `main`.
